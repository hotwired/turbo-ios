import UIKit
import WebKit

open class Session: NSObject {
    open weak var delegate: SessionDelegate?

    public var pathConfiguration: PathConfiguration?
    
    public var webView: WKWebView {
        return _webView
    }

    private let _webView: WebView
    private var initialized = false
    private var refreshing = false

    public init(webViewConfiguration: WKWebViewConfiguration? = nil) {
        _webView = WebView(configuration: webViewConfiguration ?? WKWebViewConfiguration())
        super.init()
        _webView.delegate = self
    }

    // MARK: Visiting

    private var currentVisit: Visit?
    private var topmostVisit: Visit?

    /// The topmost visitable is the visitable that has most recently completed a visit
    open var topmostVisitable: Visitable? {
        return topmostVisit?.visitable
    }
    
    /// The active visitable is the visitable that currently owns the web view
    public var activeVisitable: Visitable? {
        return activatedVisitable
    }

    open func visit(_ visitable: Visitable, action: Action) {
        visit(visitable, options: VisitOptions(action: action, response: nil))
    }
    
    open func visit(_ visitable: Visitable, options: VisitOptions = .defaultOptions, reload: Bool = false) {
        debugLog(self)
        guard visitable.visitableURL != nil else { return }

        visitable.visitableDelegate = self

        if reload {
            initialized = false
        }
        
        let visit = makeVisit(for: visitable, options: options)
        currentVisit?.cancel()
        currentVisit = visit

        visit.delegate = self
        visit.start()
    }
    
    private func makeVisit(for visitable: Visitable, options: VisitOptions) -> Visit {
        if initialized {
            return JavaScriptVisit(visitable: visitable, options: options, webView: _webView, restorationIdentifier: restorationIdentifier(for: visitable))
        } else {
            return ColdBootVisit(visitable: visitable, options: options, webView: _webView)
        }
    }

    open func reload() {
        guard let visitable = topmostVisitable else { return }

        initialized = false
        visit(visitable)
        topmostVisit = currentVisit
    }

    // MARK: Visitable activation

    private var activatedVisitable: Visitable?

    private func activateVisitable(_ visitable: Visitable) {
        guard !isActivatedVisitable(visitable) else { return }
        
        deactivateActivatedVisitable()
        visitable.activateVisitableWebView(webView)
        activatedVisitable = visitable
    }
    
    private func deactivateActivatedVisitable() {
        guard let visitable = activatedVisitable else { return }
        deactivateVisitable(visitable, showScreenshot: true)
    }

    private func deactivateVisitable(_ visitable: Visitable, showScreenshot: Bool = false) {
        guard isActivatedVisitable(visitable) else { return }

        if showScreenshot {
            visitable.updateVisitableScreenshot()
            visitable.showVisitableScreenshot()
        }

        visitable.deactivateVisitableWebView()
        activatedVisitable = nil
    }
    
    private func isActivatedVisitable(_ visitable: Visitable) -> Bool {
        return visitable === activatedVisitable
    }

    // MARK: Restoration Identifiers

    private var visitableRestorationIdentifiers = NSMapTable<UIViewController, NSString>(keyOptions: NSPointerFunctions.Options.weakMemory, valueOptions: [])

    private func restorationIdentifier(for visitable: Visitable) -> String? {
        return visitableRestorationIdentifiers.object(forKey: visitable.visitableViewController) as String?
    }

    private func storeRestorationIdentifier(_ restorationIdentifier: String, forVisitable visitable: Visitable) {
        visitableRestorationIdentifiers.setObject(restorationIdentifier as NSString, forKey: visitable.visitableViewController)
    }
    
    // MARK: - Navigation

    private func completeNavigationForCurrentVisit() {
        guard let visit = currentVisit else { return }
        
        topmostVisit = visit
    }
}

extension Session: VisitDelegate {
    func visitRequestDidStart(_ visit: Visit) {
        delegate?.sessionDidStartRequest(self)
    }

    func visitRequestDidFinish(_ visit: Visit) {
        delegate?.sessionDidFinishRequest(self)
    }

    func visit(_ visit: Visit, requestDidFailWithError error: NSError) {
        delegate?.session(self, didFailRequestForVisitable: visit.visitable, withError: error)
    }

    func visitDidInitializeWebView(_ visit: Visit) {
        initialized = true
        delegate?.sessionDidLoadWebView(self)
    }

    func visitWillStart(_ visit: Visit) {
        visit.visitable.showVisitableScreenshot()
        activateVisitable(visit.visitable)
    }

    func visitDidStart(_ visit: Visit) {
        guard !visit.hasCachedSnapshot else { return }
        visit.visitable.showVisitableActivityIndicator()
    }

    func visitWillLoadResponse(_ visit: Visit) {
        visit.visitable.updateVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidRender(_ visit: Visit) {
        visit.visitable.hideVisitableScreenshot()
        visit.visitable.hideVisitableActivityIndicator()
        visit.visitable.visitableDidRender()
    }

    func visitDidComplete(_ visit: Visit) {
        guard let restorationIdentifier = visit.restorationIdentifier else { return }
        storeRestorationIdentifier(restorationIdentifier, forVisitable: visit.visitable)
    }

    func visitDidFail(_ visit: Visit) {
        visit.visitable.clearVisitableScreenshot()
        visit.visitable.showVisitableScreenshot()
    }

    func visitDidFinish(_ visit: Visit) {
        guard refreshing else { return }

        refreshing = false
        visit.visitable.visitableDidRefresh()
    }
    
    func visit(_ visit: Visit, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.session(self, didReceiveAuthenticationChallenge: challenge, completionHandler: completionHandler)
    }
}

extension Session: VisitableDelegate {
    public func visitableViewWillAppear(_ visitable: Visitable) {
        guard let topmostVisit = self.topmostVisit, let currentVisit = self.currentVisit else { return }

        if visitable === topmostVisit.visitable && visitable.visitableViewController.isMovingToParent {
            // Back swipe gesture canceled
            if topmostVisit.state == .completed {
                currentVisit.cancel()
            } else {
                visit(visitable, action: .advance)
            }
        } else if visitable === currentVisit.visitable && currentVisit.state == .started {
            // Navigating forward - complete navigation early
            completeNavigationForCurrentVisit()
        } else if visitable !== topmostVisit.visitable {
            // Navigating backward
            visit(visitable, action: .restore)
        }
    }

    public func visitableViewDidAppear(_ visitable: Visitable) {
        if let currentVisit = self.currentVisit, visitable === currentVisit.visitable {
            // Appearing after successful navigation
            completeNavigationForCurrentVisit()
            if currentVisit.state != .failed {
                activateVisitable(visitable)
            }
        } else if let topmostVisit = self.topmostVisit, visitable === topmostVisit.visitable && topmostVisit.state == .completed {
            // Reappearing after canceled navigation
            visit(visitable, action: .restore)
        }
    }

    public func visitableDidRequestReload(_ visitable: Visitable) {
        guard visitable === topmostVisitable else { return }
        reload()
    }

    public func visitableDidRequestRefresh(_ visitable: Visitable) {
        guard visitable === topmostVisitable else { return }

        refreshing = true
        visitable.visitableWillRefresh()
        reload()
    }
}

extension Session: WebViewDelegate {
    func webView(_ webView: WebView, didProposeVisitToLocation location: URL, options: VisitOptions) {
        let properties = pathConfiguration?[location.path] ?? [:]
        delegate?.session(self, didProposeVisitToURL: location, options: options, properties: properties)
    }

    func webViewDidInvalidatePage(_ webView: WebView) {
        guard let visitable = topmostVisitable else { return }

        visitable.updateVisitableScreenshot()
        visitable.showVisitableScreenshot()
        visitable.showVisitableActivityIndicator()
        reload()
    }

    func webView(_ webView: WebView, didFailJavaScriptEvaluationWithError error: NSError) {
        guard let currentVisit = self.currentVisit, initialized else { return }
        
        initialized = false
        currentVisit.cancel()
        visit(currentVisit.visitable)
    }
}

extension Session: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> ()) {
        let navigationDecision = NavigationDecision(navigationAction: navigationAction)
        decisionHandler(navigationDecision.policy)

        if let url = navigationDecision.externallyOpenableURL {
            openExternalURL(url)
        } else if navigationDecision.shouldReloadPage {
            reload()
        }
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        debugLog("[Session] webViewWebContentProcessDidTerminate")
    }
    
    private func openExternalURL(_ url: URL) {
        delegate?.session(self, openExternalURL: url)
    }

    private struct NavigationDecision {
        let navigationAction: WKNavigationAction

        var policy: WKNavigationActionPolicy {
            return navigationAction.navigationType == .linkActivated || isMainFrameNavigation ? .cancel : .allow
        }

        var externallyOpenableURL: URL? {
            if let url = navigationAction.request.url, shouldOpenURLExternally {
                return url
            } else {
                return nil
            }
        }

        var shouldOpenURLExternally: Bool {
            let type = navigationAction.navigationType
            return type == .linkActivated || (isMainFrameNavigation && type == .other)
        }

        var shouldReloadPage: Bool {
            let type = navigationAction.navigationType
            return isMainFrameNavigation && type == .reload
        }

        var isMainFrameNavigation: Bool {
            return navigationAction.targetFrame?.isMainFrame ?? false
        }
    }
}
