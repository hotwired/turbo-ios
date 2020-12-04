import UIKit
@testable import Turbo

class TestVisitable: UIViewController, Visitable {
    // MARK: - Tests
    var visitableDidRenderCalled = false
    
    // MARK: - Visitable
    var visitableDelegate: VisitableDelegate?
    var visitableView: VisitableView!
    var visitableURL: URL!
    
    init(url: URL) {
        self.visitableURL = url
        self.visitableView = VisitableView(frame: .zero)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func visitableDidRender() {
        visitableDidRenderCalled = true
    }
}

class TestSessionDelegate: NSObject, SessionDelegate {
    var sessionDidLoadWebViewCalled = false
    var sessionDidStartRequestCalled = false
    var sessionDidFinishRequestCalled = false
    var failedRequestError: Error? = nil
    var sessionDidFailRequestCalled = false
    var sessionDidProposeVisitCalled = false
    
    func sessionDidLoadWebView(_ session: Session) {
        sessionDidLoadWebViewCalled = true
    }
    
    func sessionDidStartRequest(_ session: Session) {
        sessionDidStartRequestCalled = true
    }
    
    func sessionDidFinishRequest(_ session: Session) {
        sessionDidFinishRequestCalled = true
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        sessionDidFailRequestCalled = true
        failedRequestError = error
    }
    
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        sessionDidProposeVisitCalled = true
    }
}
