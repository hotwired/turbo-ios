import Swifter
@testable import Turbo
import WebKit
import XCTest

class SessionTests: XCTestCase {
    private static let server = HttpServer()

    private let sessionDelegate = TestSessionDelegate()
    private var session: Session!

    override class func setUp() {
        startServer()
    }

    override class func tearDown() {
        server.stop()
    }

    override func setUp() {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Turbo iOS Test/1.0"

        session = Session(webViewConfiguration: configuration)
        session.delegate = sessionDelegate
    }

    override func tearDown() {
        session.webView.configuration.userContentController.removeScriptMessageHandler(forName: "turbo")
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
        XCTAssertTrue(result as! Bool)
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
        // 5 seconds more than Turbo.js timeout.
        await visit("/missing-library", timeout: 35)

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
        XCTAssertTrue(result as! Bool)
    }

    func test_coldBootVisit_Turbolinks5_3Compatibility_loadsThePageAndSetsTheAdapter() async throws {
        await visit("/turbolinks-5.3")

        XCTAssertTrue(sessionDelegate.sessionDidLoadWebViewCalled)

        let result = try await session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative")
        XCTAssertTrue(result as! Bool)
    }

    // MARK: - Server

    @MainActor
    private func visit(_ path: String, timeout: TimeInterval = 5) async {
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

    private static func startServer() {
        server["/turbo-7.0.0-beta.1.js"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbo-7.0.0-beta.1", withExtension: "js", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/turbolinks-5.2.0.js"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbolinks-5.2.0", withExtension: "js", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/turbolinks-5.3.0-dev.js"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbolinks-5.3.0-dev", withExtension: "js", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbo", withExtension: "html", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/turbolinks"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbolinks", withExtension: "html", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/turbolinks-5.3"] = { _ in
            let fileURL = Bundle.module.url(forResource: "turbolinks-5.3", withExtension: "html", subdirectory: "Server")!
            let data = try! Data(contentsOf: fileURL)
            return .ok(.data(data))
        }

        server["/missing-library"] = { _ in
            .ok(.html("<html></html>"))
        }

        server["/invalid"] = { _ in
            .notFound
        }

        try! server.start()
    }
}
