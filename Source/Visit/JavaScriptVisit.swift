import Foundation

/// A JavaScript managed visit through the Turbo library
/// All visits are JavaScriptVisits except the initial ColdBootVisit
/// or if a reload() is issued
final class JavaScriptVisit: Visit {
    private var identifier = "(pending)"
    
    init(visitable: Visitable, options: VisitOptions, bridge: WebViewBridge, restorationIdentifier: String?) {
        super.init(visitable: visitable, options: options, bridge: bridge)
        self.restorationIdentifier = restorationIdentifier
    }

    override var debugDescription: String {
        "<JavaScriptVisit identifier: \(identifier), state: \(state), location: \(location)>"
    }

    override func startVisit() {
        log("startVisit")
        bridge.visitDelegate = self
        bridge.visitLocation(location, options: options, restorationIdentifier: restorationIdentifier)
    }

    override func cancelVisit() {
        log("cancelVisit")
        bridge.cancelVisit(withIdentifier: identifier)
        finishRequest()
    }

    override func failVisit() {
        log("failVisit")
        finishRequest()
    }
}

extension JavaScriptVisit: WebViewVisitDelegate {
    func webView(_ webView: WebViewBridge, didStartVisitWithIdentifier identifier: String, hasCachedSnapshot: Bool) {
        log("didStartVisitWithIdentifier", ["identifier": identifier, "hasCachedSnapshot": hasCachedSnapshot])
        self.identifier = identifier
        self.hasCachedSnapshot = hasCachedSnapshot
        
        delegate?.visitDidStart(self)
    }
    
    func webView(_ webView: WebViewBridge, didStartRequestForVisitWithIdentifier identifier: String, date: Date) {
        guard identifier == self.identifier else { return }
        log("didFinishRequestForVisitWithIdentifier", ["identifier": identifier, "date": date])
        startRequest()
    }
    
    func webView(_ webView: WebViewBridge, didCompleteRequestForVisitWithIdentifier identifier: String) {
        guard identifier == self.identifier else { return }
        log("didCompleteRequestForVisitWithIdentifier", ["identifier": identifier])
        
        if hasCachedSnapshot {
            delegate?.visitWillLoadResponse(self)
        }
    }
    
    func webView(_ webView: WebViewBridge, didFailRequestForVisitWithIdentifier identifier: String, statusCode: Int) {
        guard identifier == self.identifier else { return }
        
        log("didFailRequestForVisitWithIdentifier", ["identifier": identifier, "statusCode": statusCode])
        fail(with: TurboError(statusCode: statusCode))
    }
    
    func webView(_ webView: WebViewBridge, didFinishRequestForVisitWithIdentifier identifier: String, date: Date) {
        guard identifier == self.identifier else { return }
        
        log("didFinishRequestForVisitWithIdentifier", ["identifier": identifier, "date": date])
        finishRequest()
    }
    
    func webView(_ webView: WebViewBridge, didRenderForVisitWithIdentifier identifier: String) {
        guard identifier == self.identifier else { return }
        
        log("didRenderForVisitWithIdentifier", ["identifier": identifier])
        delegate?.visitDidRender(self)
    }
    
    func webView(_ webView: WebViewBridge, didCompleteVisitWithIdentifier identifier: String, restorationIdentifier: String) {
        guard identifier == self.identifier else { return }
        
        log("didCompleteVisitWithIdentifier", ["identifier": identifier, "restorationIdentifier": restorationIdentifier])
        self.restorationIdentifier = restorationIdentifier
        complete()
    }
    
    private func log(_ name: String, _ arguments: [String: Any] = [:]) {
        debugLog("[JavascriptVisit] \(name) \(location.absoluteString)", arguments)
    }
}
