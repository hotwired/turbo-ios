import WebKit

enum VisitState {
    case initialized
    case started
    case canceled
    case failed
    case completed
}

class Visit: NSObject {
    weak var delegate: VisitDelegate?
    let visitable: Visitable
    var restorationIdentifier: String?
    
    fileprivate let options: VisitOptions
    fileprivate let webView: WebView
    fileprivate let location: URL
    fileprivate(set) var hasCachedSnapshot: Bool = false

    private(set) var state: VisitState
    
    override var description: String {
        "<\(type(of: self)): state=\(state) location=\(location)>"
    }

    init(visitable: Visitable, options: VisitOptions, webView: WebView) {
        self.visitable = visitable
        self.location = visitable.visitableURL!
        self.options = options
        self.webView = webView
        self.state = .initialized
    }

    func start() {
        guard state == .initialized else { return }

        delegate?.visitWillStart(self)
        state = .started
        startVisit()
    }

    func cancel() {
        guard state == .started else { return }
        
        state = .canceled
        cancelVisit()
    }

    fileprivate func complete() {
        guard state == .started else { return }
        
        if !requestFinished {
            finishRequest(at: Date())
        }
        
        state = .completed
        
        completeVisit()
        delegate?.visitDidComplete(self)
        delegate?.visitDidFinish(self)
    }

    fileprivate func fail(with error: NSError) {
        guard state == .started else { return }

        state = .failed
        delegate?.visit(self, requestDidFailWithError: error)
        failVisit()
        delegate?.visitDidFail(self)
        delegate?.visitDidFinish(self)
    }

    fileprivate func startVisit() {}
    fileprivate func cancelVisit() {}
    fileprivate func completeVisit() {}
    fileprivate func failVisit() {}

    // MARK: Request state

    private var requestStarted = false
    private var requestFinished = false

    fileprivate func startRequest(at date: Date) {
        guard !requestStarted else { return }
        
        requestStarted = true
        delegate?.visitRequestDidStart(self)
    }

    fileprivate func finishRequest(at date: Date) {
        guard requestStarted, !requestFinished else { return }
        
        requestFinished = true
        delegate?.visitRequestDidFinish(self)
    }
}

class ColdBootVisit: Visit, WKNavigationDelegate, WebViewPageLoadDelegate {
    private var navigation: WKNavigation?

    override fileprivate func startVisit() {
        debugLog(self)

        webView.navigationDelegate = self
        webView.pageLoadDelegate = self

        if let response = options.response, response.isSuccessful, let body = response.responseHTML {
            navigation = webView.loadHTMLString(body, baseURL: location)
        } else {
            navigation = webView.load(URLRequest(url: location))
        }

        delegate?.visitDidStart(self)
        startRequest(at: Date())
    }

    override fileprivate func cancelVisit() {
        removeNavigationDelegate()
        webView.stopLoading()
        finishRequest(at: Date())
    }

    override fileprivate func completeVisit() {
        removeNavigationDelegate()
        delegate?.visitDidInitializeWebView(self)
    }

    override fileprivate func failVisit() {
        removeNavigationDelegate()
        finishRequest(at: Date())
    }

    private func removeNavigationDelegate() {
        guard webView.navigationDelegate === self else { return }
        webView.navigationDelegate = nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard navigation == self.navigation else { return }
        finishRequest(at: Date())
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Ignore any clicked links before the cold boot finishes navigation
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                fail(with: NSError(code: .httpFailure, statusCode: httpResponse.statusCode))
            }
        } else {
            decisionHandler(.cancel)
            fail(with: NSError(code: .networkFailure, localizedDescription: "An unknown error occurred"))
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard navigation == self.navigation else { return }

        fail(with: NSError(code: .networkFailure, error: error as NSError))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard navigation == self.navigation else { return }

        fail(with: NSError(code: .networkFailure, error: error as NSError))
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.visit(self, didReceiveAuthenticationChallenge: challenge, completionHandler: completionHandler)
    }

    // MARK: - WebViewPageLoadDelegate

    func webView(_ webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String) {
        self.restorationIdentifier = restorationIdentifier
        delegate?.visitDidRender(self)
        complete()
    }
}

class JavaScriptVisit: Visit {
    private var identifier = "(pending)"
    
    init(visitable: Visitable, options: VisitOptions, webView: WebView, restorationIdentifier: String?) {
        super.init(visitable: visitable, options: options, webView: webView)
        self.restorationIdentifier = restorationIdentifier
    }

    override var description: String {
        return "<\(type(of: self)) \(identifier): state=\(state) location=\(location)>"
    }

    override fileprivate func startVisit() {
        debugLog(self)
        webView.visitDelegate = self
        webView.visitLocation(location, options: options, restorationIdentifier: restorationIdentifier)
    }

    override fileprivate func cancelVisit() {
        debugLog(self)
        webView.cancelVisit(withIdentifier: identifier)
        finishRequest(at: Date())
    }

    override fileprivate func failVisit() {
        debugLog(self)
        finishRequest(at: Date())
    }
}

extension JavaScriptVisit: WebViewVisitDelegate {
    func webView(_ webView: WebView, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool) {
        debugLog(self)
        self.identifier = identifier
        self.hasCachedSnapshot = hasCachedSnapshot
        
        delegate?.visitDidStart(self)
    }
    
    func webView(_ webView: WebView, didStartRequestForVisitWithIdentifier identifier: String, date: Date) {
        guard identifier == self.identifier else { return }
        debugLog(self)
        startRequest(at: date)
    }
    
    func webView(_ webView: WebView, didCompleteRequestForVisitWithIdentifier identifier: String) {
        guard identifier == self.identifier else { return }
        debugLog(self)
        
        if hasCachedSnapshot {
            delegate?.visitWillLoadResponse(self)
        }
    }
    
    func webView(_ webView: WebView, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int) {
        guard identifier == self.identifier else { return }
        
        fail(with: NSError(httpStatusCode: statusCode))
    }
    
    func webView(_ webView: WebView, didFinishRequestForVisitWithIdentifier identifier: String, date: Date) {
        guard identifier == self.identifier else { return }
        
        debugLog(self)
        finishRequest(at: date)
    }
    
    func webView(_ webView: WebView, didRenderForVisitWithIdentifier identifier: String) {
        guard identifier == self.identifier else { return }
        
        debugLog(self)
        delegate?.visitDidRender(self)
    }
    
    func webView(_ webView: WebView, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String) {
        guard identifier == self.identifier else { return }
        
        debugLog(self)
        self.restorationIdentifier = restorationIdentifier
        complete()
    }
}
