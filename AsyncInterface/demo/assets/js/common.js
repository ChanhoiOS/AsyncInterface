const back = () => {
    history.back();
}

const copyToClipboard = async (data) => {
    await navigator.clipboard.writeText(data)
}

const showToast = (msg) => {
    toastr.options = {
        closeButton: true,
        showMethod: 'slideDown',
        timeOut: 4000,
        positionClass: "toast-bottom-full-width"
    };
    toastr.success(msg, "Response");
}