import WebKit

protocol ScriptMessageHandlerDelegate: class {
    func scriptMessageHandlerDidReceiveMessage(_ scriptMessage: WKScriptMessage)
}

// This class prevents retain cycle caused by WKUserContentController
class ScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: ScriptMessageHandlerDelegate?
    
    init(delegate: ScriptMessageHandlerDelegate?) {
        self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive scriptMessage: WKScriptMessage) {
        delegate?.scriptMessageHandlerDidReceiveMessage(scriptMessage)
    }
}
