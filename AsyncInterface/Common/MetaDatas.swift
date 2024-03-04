//
//  MetaDatas.swift
//  CommonFunction
//
//  Created by 이찬호 on 2/28/24.
//

import Foundation
import SwiftPromises

struct Metadata {
    let sequence: Int
}

struct TaskError: Error {
    let message: String
}

typealias TaskHandler = (_ param: [String: Any]) async throws -> [String: Any]
