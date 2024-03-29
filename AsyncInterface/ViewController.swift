//
//  ViewController.swift
//  AsyncInterface
//
//  Created by 이찬호 on 3/5/24.
//

import UIKit
import WebKit
import Then
import SnapKit
import SwiftPromises

class ViewController: UIViewController {
    
    var webView: WKWebView!
    let webConfiguration = WKWebViewConfiguration()
    
    private var taskHandlers = [String: TaskHandler]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setContentController()
        setFunction()
        setWebView()
    }
    
    func setContentController() {
        let contentController = WKUserContentController()
        webConfiguration.userContentController = contentController
    }
    
    func setFunction() {
        taskHandlers["outLink"] = { param in
            var result = [String: Any]()
            
            if let url = param["url"] as? String, self.urlInvalid(url) {
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: url)!, options: [:])
                }
                
                result["result"] = true
                return result
            } else {
                do {
                    throw TaskError(message: "Unvalid Url Error!!")
                } catch {
                    result["result"] = false
                    return result
                }
            }
        }
    }

    func setWebView() {
        webView = WKWebView(frame: self.view.frame, configuration: webConfiguration)
        
        taskHandlers.keys.forEach {
            webView.configuration.userContentController.add(self, name: $0) // 작업 이름을 추가합니다
        }
        
        webView.navigationDelegate = self
        webView.uiDelegate = self
        self.view.addSubview(webView)
        
        self.setupWebViewConstraints()
        
        var reqUrl: URL?

        guard let path = Bundle.main.path(forResource: "demo/index", ofType: "html") else { return }
        reqUrl = URL(fileURLWithPath: path)
        
        if #available(iOS 16.4, *) { webView.isInspectable = true }
        
        webView.load(URLRequest(url: reqUrl!))
    }
    
    private func setupWebViewConstraints() {
        let safeArea = self.view.safeAreaLayoutGuide
        self.webView.do {
            $0.snp.makeConstraints { make in
                make.leading.equalTo(safeArea.snp.leading)
                make.top.equalTo(safeArea.snp.top)
                make.trailing.equalTo(safeArea.snp.trailing)
                make.bottom.equalTo(self.view.snp.bottom)
            }
        }
    }
}

extension ViewController {
    private func onCallback(_ returnKey: String, _ result: [String : Any]) -> Void {
        onComplete(returnKey, result)
    }
    
    private func onComplete(_ returnKey: String, _ result: [String : Any]) -> Void {
        var script = ""
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: result),
            let jsonString = String(data: jsonData, encoding: .utf8) {
            //script = "\(returnKey)('\(jsonString)');"
            script = "\(returnKey)(\(jsonString));"
        }
     
        webView?.evaluateJavaScript(script) { (_, error) in
            if let error = error {
                print("evaluateJavaScript error: ", error)
            } else {
                print("evaluateJavaScript script: ", script)
            }
        }
    }
    
    /*
     script = "result({\"success\":true})" Dict
     script = "result('success')" String
    */
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
              let name = body["action"] as? String,
              let returnKey = body["returnKey"] as? String else { return }
        print("name: ", name)
        print("body: ", body)
        print("returnKey: ", returnKey)
        
        guard let taskHandler = taskHandlers[name] else {
            let result: [String: Any] = ["result": false]
            onCallback(returnKey, result)
            return
        }

        Task {
            var result = try await taskHandler(body)
            onCallback(returnKey, result)
        }
    }
}


extension ViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Swift.Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert);
            
        let cancelAction = UIAlertAction(title: "확인", style: .cancel) {
            _ in completionHandler()
        }
            
        alertController.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension ViewController {
    func urlInvalid(_ url: String) -> Bool {
        if url.hasPrefix("https") || url.hasPrefix("http") || url.hasPrefix("www") {
            return true
        } else {
            return false
        }
    }
}


