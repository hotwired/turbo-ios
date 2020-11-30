import Foundation

final class JavaScriptVisit: Visit {
    private var identifier = "(pending)"
    
    init(visitable: Visitable, options: VisitOptions, webView: WebView, restorationIdentifier: String?) {
        super.init(visitable: visitable, options: options, webView: webView)
        self.restorationIdentifier = restorationIdentifier
    }

    override var description: String {
        return "<\(type(of: self)) \(identifier): state=\(state) location=\(location)>"
    }

    override func startVisit() {
        debugLog(self)
        webView.visitDelegate = self
        webView.visitLocation(location, options: options, restorationIdentifier: restorationIdentifier)
    }

    override func cancelVisit() {
        debugLog(self)
        webView.cancelVisit(withIdentifier: identifier)
        finishRequest(at: Date())
    }

    override func failVisit() {
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
        
        fail(with: TurboError.http(statusCode: statusCode))
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
