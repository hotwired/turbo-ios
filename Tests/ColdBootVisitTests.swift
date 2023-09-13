@testable import Turbo
import WebKit
import XCTest

class ColdBootVisitTests: XCTestCase {
    private let webView = WKWebView()
    private let visitDelegate = TestVisitDelegate()
    private var visit: ColdBootVisit!

    override func setUp() {
        let url = URL(string: "http://localhost/")!
        let bridge = WebViewBridge(webView: webView)

        visit = ColdBootVisit(visitable: TestVisitable(url: url), options: VisitOptions(), bridge: bridge)
        visit.delegate = visitDelegate
    }

    func test_start_transitionsToStartState() {
        XCTAssertEqual(visit.state, .initialized)
        visit.start()
        XCTAssertEqual(visit.state, .started)
    }

    func test_start_notifiesTheDelegateTheVisitWillStart() {
        visit.start()
        XCTAssertTrue(visitDelegate.didCall("visitWillStart(_:)"))
    }

    func test_start_kicksOffTheWebViewLoad() {
        visit.start()
        XCTAssertNotNil(visit.navigation)
    }

    func test_visit_becomesTheNavigationDelegate() {
        visit.start()
        XCTAssertIdentical(webView.navigationDelegate, visit)
    }

    func test_visit_notifiesTheDelegateTheVisitDidStart() {
        visit.start()
        XCTAssertTrue(visitDelegate.didCall("visitDidStart(_:)"))
    }

    func test_visit_ignoresTheCallIfAlreadyStarted() {
        visit.start()
        XCTAssertTrue(visitDelegate.methodsCalled.contains("visitDidStart(_:)"))

        visitDelegate.methodsCalled.remove("visitDidStart(_:)")
        visit.start()
        XCTAssertFalse(visitDelegate.didCall("visitDidStart(_:)"))
    }
}

private class TestVisitDelegate {
    var methodsCalled: Set<String> = []

    func didCall(_ method: String) -> Bool {
        methodsCalled.contains(method)
    }

    private func record(_ string: String = #function) {
        methodsCalled.insert(string)
    }
}

extension TestVisitDelegate: VisitDelegate {
    func visitDidInitializeWebView(_ visit: Visit) {
        record()
    }

    func visitWillStart(_ visit: Visit) {
        record()
    }

    func visitDidStart(_ visit: Visit) {
        record()
    }

    func visitDidComplete(_ visit: Visit) {
        record()
    }

    func visitDidFail(_ visit: Visit) {
        record()
    }

    func visitDidFinish(_ visit: Visit) {
        record()
    }

    func visitWillLoadResponse(_ visit: Visit) {
        record()
    }

    func visitDidRender(_ visit: Visit) {
        record()
    }

    func visitRequestDidStart(_ visit: Visit) {
        record()
    }

    func visit(_ visit: Visit, requestDidFailWithError error: Error) {
        record()
    }

    func visitRequestDidFinish(_ visit: Visit) {
        record()
    }

    func visit(_ visit: Visit, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        record()
    }
}
