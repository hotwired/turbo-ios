import WebKit

protocol WebViewDelegate: class {
    func webView(_ webView: WebView, didProposeVisitToLocation location: URL, options: VisitOptions)
    func webViewDidInvalidatePage(_ webView: WebView)
    func webView(_ webView: WebView, didFailJavaScriptEvaluationWithError error: NSError)
}

protocol WebViewPageLoadDelegate: class {
    func webView(_ webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String)
}

protocol WebViewVisitDelegate: class {
    func webView(_ webView: WebView, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool)
    func webView(_ webView: WebView, didStartRequestForVisitWithIdentifier identifier: String, date: Date)
    func webView(_ webView: WebView, didCompleteRequestForVisitWithIdentifier identifier: String)
    func webView(_ webView: WebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int)
    func webView(_ webView: WebView, didFinishRequestForVisitWithIdentifier identifier: String, date: Date)
    func webView(_ webView: WebView, didRenderForVisitWithIdentifier identifier: String)
    func webView(_ webView: WebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String)
}

private let MessageHandlerName = "turbo"

class WebView: WKWebView {
    weak var delegate: WebViewDelegate?
    weak var pageLoadDelegate: WebViewPageLoadDelegate?
    weak var visitDelegate: WebViewVisitDelegate?
    
    deinit {
        configuration.userContentController.removeScriptMessageHandler(forName: MessageHandlerName)
    }

    init(configuration: WKWebViewConfiguration) {
        super.init(frame: CGRect.zero, configuration: configuration)

        let bundle = Bundle(for: type(of: self))
        let source = try! String(contentsOf: bundle.url(forResource: "WebView", withExtension: "js")!, encoding: .utf8)
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        configuration.userContentController.addUserScript(userScript)
        configuration.userContentController.add(ScriptMessageHandler(delegate: self), name: MessageHandlerName)

        translatesAutoresizingMaskIntoConstraints = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func visitLocation(_ location: URL, options: VisitOptions, restorationIdentifier: String?) {
        callJavaScript(function: "webView.visitLocationWithOptionsAndRestorationIdentifier", arguments: [location.absoluteString, options.toJSON(), restorationIdentifier])
    }

    func cancelVisit(withIdentifier identifier: String) {
        callJavaScript(function: "webView.cancelVisitWithIdentifier", arguments: [identifier])
    }

    // MARK: JavaScript Evaluation

    private func callJavaScript(function: String, arguments: [Any?] = []) {
        let expression = JavaScriptExpression(function: function, arguments: arguments)
        
        guard let script = expression.wrappedString else {
            NSLog("Error formatting JavaScript expression `%@'", function)
            return
        }
        
        if window == nil {
            debugLog("[WebView] *** calling \(function), but not in a window!")
        }
        
        debugLog("[Bridge] → \(function)")

        evaluateJavaScript(script) { result, error in
            debugLog("[Bridge] = \(function) evaluation complete")
            
            if let result = result as? [String: Any], let error = result["error"] as? String, let stack = result["stack"] as? String {
                NSLog("Error evaluating JavaScript function `%@': %@\n%@", function, error, stack)
            } else if let error = error {
                self.delegate?.webView(self, didFailJavaScriptEvaluationWithError: error as NSError)
            }
        }
    }
}

extension WebView: ScriptMessageHandlerDelegate {
    func scriptMessageHandlerDidReceiveMessage(_ scriptMessage: WKScriptMessage) {
        guard let message = ScriptMessage(message: scriptMessage) else { return }
        
        let timestamp = message.timestamp.truncatingRemainder(dividingBy: 10000)
        if message.name != .log {
            debugLog("[Bridge] ← \(message.name) (@ \(timestamp))")
        }
        
        switch message.name {
        case .pageLoaded:
            pageLoadDelegate?.webView(self, didLoadPageWithRestorationIdentifier: message.restorationIdentifier!)
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
            NSLog("JavaScript error: %@", error ?? "<unknown error>")
        case .log:
            guard let msg = message.data["message"] as? String else { return }
            debugLog("[Bridge] ← log: \(msg) (@ \(timestamp))")
        }
    }
}
