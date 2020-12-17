import WebKit

protocol WebViewDelegate: AnyObject {
    func webView(_ webView: WebViewBridge, didProposeVisitToLocation location: URL, options: VisitOptions)
    func webViewDidInvalidatePage(_ webView: WebViewBridge)
    func webView(_ webView: WebViewBridge, didFailInitialPageLoadWithError: Error)
    func webView(_ webView: WebViewBridge, didFailJavaScriptEvaluationWithError error: Error)
}

protocol WebViewPageLoadDelegate: AnyObject {
    func webView(_ webView: WebViewBridge, didLoadPageWithRestorationIdentifier restorationIdentifier: String)
}

protocol WebViewVisitDelegate: AnyObject {
    func webView(_ webView: WebViewBridge, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool)
    func webView(_ webView: WebViewBridge, didStartRequestForVisitWithIdentifier identifier: String, date: Date)
    func webView(_ webView: WebViewBridge, didCompleteRequestForVisitWithIdentifier identifier: String)
    func webView(_ webView: WebViewBridge, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int)
    func webView(_ webView: WebViewBridge, didFinishRequestForVisitWithIdentifier identifier: String, date: Date)
    func webView(_ webView: WebViewBridge, didRenderForVisitWithIdentifier identifier: String)
    func webView(_ webView: WebViewBridge, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String)
}

/// The WebViewBridge is an internal class used for bi-directional communication
/// with the web view/JavaScript
final class WebViewBridge {
    private let messageHandlerName = "turbo"

    weak var delegate: WebViewDelegate?
    weak var pageLoadDelegate: WebViewPageLoadDelegate?
    weak var visitDelegate: WebViewVisitDelegate?
    
    let webView: WKWebView
    
    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: messageHandlerName)
    }

    init(webView: WKWebView) {
        self.webView = webView
        setup()
    }
    
    private func setup() {
        webView.configuration.userContentController.addUserScript(userScript)
        webView.configuration.userContentController.add(ScriptMessageHandler(delegate: self), name: messageHandlerName)
    }
    
    private var userScript: WKUserScript {
        let url = Self.bundle.url(forResource: "turbo", withExtension: "js")!
        let source = try! String(contentsOf: url, encoding: .utf8)
        return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }
    
    private static var bundle: Bundle {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        return Bundle(for: WebViewBridge.self)
        #endif
    }
    
    // MARK: - JS
    
    func visitLocation(_ location: URL, options: VisitOptions, restorationIdentifier: String?) {
        callJavaScript(function: "window.turboNative.visitLocationWithOptionsAndRestorationIdentifier", arguments: [
            location.absoluteString,
            options.toJSON(),
            restorationIdentifier
        ])
    }

    func cancelVisit(withIdentifier identifier: String) {
        callJavaScript(function: "window.turboNative.cancelVisitWithIdentifier", arguments: [identifier])
    }

    // MARK: JavaScript Evaluation

    private func callJavaScript(function: String, arguments: [Any?] = []) {
        let expression = JavaScriptExpression(function: function, arguments: arguments)
        
        guard let script = expression.wrappedString else {
            NSLog("Error formatting JavaScript expression `%@'", function)
            return
        }
        
        debugLog("[Bridge] → \(function)")

        webView.evaluateJavaScript(script) { result, error in
            debugLog("[Bridge] = \(function) evaluation complete")
            
            if let result = result as? [String: Any], let error = result["error"] as? String, let stack = result["stack"] as? String {
                NSLog("Error evaluating JavaScript function `%@': %@\n%@", function, error, stack)
            } else if let error = error {
                self.delegate?.webView(self, didFailJavaScriptEvaluationWithError: error)
            }
        }
    }
}

extension WebViewBridge: ScriptMessageHandlerDelegate {
    func scriptMessageHandlerDidReceiveMessage(_ scriptMessage: WKScriptMessage) {
        guard let message = ScriptMessage(message: scriptMessage) else { return }
        
        if message.name != .log {
            debugLog("[Bridge] ← \(message.name)")
        }
        
        switch message.name {
        case .pageLoaded:
            pageLoadDelegate?.webView(self, didLoadPageWithRestorationIdentifier: message.restorationIdentifier!)
        case .pageLoadFailed:
            delegate?.webView(self, didFailInitialPageLoadWithError: TurboError.pageLoadFailure)
        case .pageInvalidated:
            delegate?.webViewDidInvalidatePage(self)
        case .visitProposed:
            delegate?.webView(self, didProposeVisitToLocation: message.location!, options: message.options!)
        case .visitStarted:
            visitDelegate?.webView(self, didStartVisitWithIdentifier: message.identifier!, hasCachedSnapshot: message.data["hasCachedSnapshot"] as! Bool)
        case .visitRequestStarted:
            visitDelegate?.webView(self, didStartRequestForVisitWithIdentifier: message.identifier!, date: message.date)
        case .visitRequestCompleted:
            visitDelegate?.webView(self, didCompleteRequestForVisitWithIdentifier: message.identifier!)
        case .visitRequestFailed:
            visitDelegate?.webView(self, didFailRequestForVisitWithIdentifier: message.identifier!, statusCode: message.data["statusCode"] as! Int)
        case .visitRequestFinished:
            visitDelegate?.webView(self, didFinishRequestForVisitWithIdentifier: message.identifier!, date: message.date)
        case .visitRendered:
            visitDelegate?.webView(self, didRenderForVisitWithIdentifier: message.identifier!)
        case .visitCompleted:
            visitDelegate?.webView(self, didCompleteVisitWithIdentifier: message.identifier!, restorationIdentifier: message.restorationIdentifier!)
        case .errorRaised:
            let error = message.data["error"] as? String
            debugLog("JavaScript error: \(String(describing: error))")
        case .log:
            guard let msg = message.data["message"] as? String else { return }
            debugLog("[Bridge] ← log: \(msg)")
        }
    }
}
