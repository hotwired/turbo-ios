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
    let options: VisitOptions
    let bridge: WebViewBridge
    var webView: WKWebView { bridge.webView }
    let location: URL
    
    var hasCachedSnapshot: Bool = false
    var isPageRefresh: Bool = false
    private(set) var state: VisitState
    
    init(visitable: Visitable, options: VisitOptions, bridge: WebViewBridge) {
        self.visitable = visitable
        self.location = visitable.visitableURL!
        self.options = options
        self.bridge = bridge
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

    func complete() {
        guard state == .started else { return }
        
        if !requestFinished {
            finishRequest()
        }
        
        state = .completed
        
        completeVisit()
        delegate?.visitDidComplete(self)
        delegate?.visitDidFinish(self)
    }

    func fail(with error: Error, forURL url: URL) {
        guard state == .started else { return }

        state = .failed
        if delegate?.visitShouldFail(url) ?? true {
            delegate?.visit(self, requestDidFailWithError: error)
        }
        failVisit()
        delegate?.visitDidFail(self)
        delegate?.visitDidFinish(self)
    }

    func cacheSnapshot() {
        bridge.cacheSnapshot()
    }

    func startVisit() {}
    func cancelVisit() {}
    func completeVisit() {}
    func failVisit() {}

    // MARK: Request state

    private var requestStarted = false
    private var requestFinished = false

    func startRequest() {
        guard !requestStarted else { return }
        
        requestStarted = true
        delegate?.visitRequestDidStart(self)
    }

    func finishRequest() {
        guard requestStarted, !requestFinished else { return }
        
        requestFinished = true
        delegate?.visitRequestDidFinish(self)
    }
}

// CustomDebugStringConvertible
extension Visit {
    override var debugDescription: String {
        "<\(type(of: self)) state: \(state), location: \(location)>"
    }
}
