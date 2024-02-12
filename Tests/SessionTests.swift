import Embassy
@testable import Turbo
import WebKit
import XCTest

private let defaultTimeout: TimeInterval = 10000
private let turboTimeout: TimeInterval = 30

class SessionTests: XCTestCase {
    private let sessionDelegate = TestSessionDelegate()
    private var session: Session!
    private var eventLoop: SelectorEventLoop!
    private var server: DefaultHTTPServer!

    @MainActor
    override func setUp() async throws {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Turbo iOS Test/1.0"

        session = Session(webViewConfiguration: configuration)
        session.delegate = sessionDelegate

        eventLoop = try SelectorEventLoop(selector: KqueueSelector())
        server = DefaultHTTPServer.turboServer(eventLoop: eventLoop)
        try server.start()
        DispatchQueue.global().async { self.eventLoop.runForever() }
    }

    override func tearDown() {
        session.webView.configuration.userContentController.removeScriptMessageHandler(forName: "turbo")

        server.stopAndWait()
        eventLoop.stop()
    }

    func test_init_initializesWebViewWithConfiguration() {
        XCTAssertEqual(session.webView.configuration.applicationNameForUserAgent, "Turbo iOS Test/1.0")
    }

    func test_coldBootVisit_makesTheSessionTheVisitableDelegate() {
        let visitable = TestVisitable(url: url("/"))
        XCTAssertNil(visitable.visitableDelegate)

        session.visit(visitable)
        XCTAssertIdentical(visitable.visitableDelegate, session)
    }

    func test_coldBootVisit_callsStartRequest() {
        let visitable = TestVisitable(url: url("/"))
        session.visit(visitable)

        XCTAssertTrue(sessionDelegate.sessionDidStartRequestCalled)
    }

    func test_coldBootVisit_whenVisitSucceeds_callsSessionDidLoadWebViewDelegateMethod() async {
        await visit("/")

        XCTAssertTrue(sessionDelegate.sessionDidLoadWebViewCalled)
        XCTAssertFalse(sessionDelegate.sessionDidFailRequestCalled)
    }

    func test_coldBootVisit_whenVisitSucceeds_callsSessionDidFinishRequestDelegateMethod() async {
        await visit("/")

        XCTAssertTrue(sessionDelegate.sessionDidFinishRequestCalled)
        XCTAssertFalse(sessionDelegate.sessionDidFailRequestCalled)
    }

    func test_coldBootVisit_whenVisitSucceeds_configuresJavaScriptBridge() async throws {
        await visit("/")

        XCTAssertTrue(sessionDelegate.sessionDidLoadWebViewCalled)
        let result = try await session.webView.evaluateJavaScript("Turbo.navigator.adapter == window.turboNative")
        XCTAssertTrue(try XCTUnwrap(result as? Bool))
    }

    func test_coldBootVisit_whenVisitFailsFromHTTPError_callsSessionDidFailRequestDelegateMethod() async {
        await visit("/invalid")

        XCTAssertTrue(sessionDelegate.sessionDidFailRequestCalled)
    }

    func test_coldBootVisit_whenVisitFailsFromHTTPError_providesAnError() async throws {
        await visit("/invalid")

        XCTAssertNotNil(sessionDelegate.failedRequestError)
        let error = try XCTUnwrap(sessionDelegate.failedRequestError)
        XCTAssertEqual(error as? TurboError, TurboError.http(statusCode: 404))
    }

    func test_coldBootVisit_whenVisitFailsFromHTTPError_callsSessionDidFinishRequestDelegateMethod() async {
        await visit("/invalid")

        XCTAssertTrue(sessionDelegate.sessionDidFinishRequestCalled)
    }

    @MainActor
    func test_coldBootVisit_whenVisitFailsFromMissingLibrary_providesAnPageLoadError() async throws {
        await visit("/missing-library", timeout: turboTimeout + defaultTimeout)

        XCTAssertTrue(sessionDelegate.sessionDidFailRequestCalled)
        XCTAssertTrue(sessionDelegate.sessionDidFinishRequestCalled)

        XCTAssertNotNil(sessionDelegate.failedRequestError)
        let error = try XCTUnwrap(sessionDelegate.failedRequestError)
        XCTAssertEqual(error as? TurboError, TurboError.pageLoadFailure)
    }

    func test_coldBootVisit_Turbolinks5Compatibility_loadsThePageAndSetsTheAdapter() async throws {
        await visit("/turbolinks")

        XCTAssertTrue(sessionDelegate.sessionDidLoadWebViewCalled)

        let result = try await session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative")
        XCTAssertTrue(try XCTUnwrap(result as? Bool))
    }

    func test_coldBootVisit_Turbolinks5_3Compatibility_loadsThePageAndSetsTheAdapter() async throws {
        await visit("/turbolinks-5.3")

        XCTAssertTrue(sessionDelegate.sessionDidLoadWebViewCalled)

        let result = try await session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative")
        XCTAssertTrue(try XCTUnwrap(result as? Bool))
    }

    // MARK: - Server

    @MainActor
    private func visit(_ path: String, timeout: TimeInterval = defaultTimeout) async {
        let expectation = self.expectation(description: "Wait for request to load.")
        sessionDelegate.didChange = { expectation.fulfill() }

        let visitable = TestVisitable(url: url(path))
        session.visit(visitable)
        await fulfillment(of: [expectation], timeout: timeout)
    }

    private func url(_ path: String) -> URL {
        let baseURL = URL(string: "http://localhost:8080")!
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(relativePath)
    }
}
