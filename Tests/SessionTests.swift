import Embassy
@testable import Turbo
import WebKit
import XCTest

private let defaultTimeout: TimeInterval = 10000
private let turboTimeout: TimeInterval = 30

class SessionTests: XCTestCase {
    private static var eventLoop: EventLoop!
    private static var server: HTTPServer!

    private let sessionDelegate = TestSessionDelegate()
    private var session: Session!

    override class func setUp() {
        super.setUp()
        startServer()
    }

    override class func tearDown() {
        super.tearDown()
        server.stopAndWait()
        eventLoop.stop()
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

    private static func startServer() {
        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        eventLoop = loop

        let server = DefaultHTTPServer(eventLoop: loop, port: 8080) { environ, startResponse, sendBody in
            let path = environ["PATH_INFO"] as! String

            func respondWithFile(resourceName: String, resourceType: String) {
                let fileURL = Bundle.module.url(forResource: resourceName, withExtension: resourceType, subdirectory: "Server")!
                let data = try! Data(contentsOf: fileURL)

                let contentType = (resourceType == "js") ? "application/javascript" : "text/html"
                startResponse("200 OK", [("Content-Type", contentType)])
                sendBody(data)
                sendBody(Data())
            }

            switch path {
            case "/turbo-7.0.0-beta.1.js":
                respondWithFile(resourceName: "turbo-7.0.0-beta.1", resourceType: "js")
            case "/turbolinks-5.2.0.js":
                respondWithFile(resourceName: "turbolinks-5.2.0", resourceType: "js")
            case "/turbolinks-5.3.0-dev.js":
                respondWithFile(resourceName: "turbolinks-5.3.0-dev", resourceType: "js")
            case "/":
                respondWithFile(resourceName: "turbo", resourceType: "html")
            case "/turbolinks":
                respondWithFile(resourceName: "turbolinks", resourceType: "html")
            case "/turbolinks-5.3":
                respondWithFile(resourceName: "turbolinks-5.3", resourceType: "html")
            case "/missing-library":
                startResponse("200 OK", [("Content-Type", "text/html")])
                sendBody("<html></html>".data(using: .utf8)!)
                sendBody(Data())
            default:
                startResponse("404 Not Found", [("Content-Type", "text/plain")])
                sendBody(Data())
            }
        }

        self.server = server
        try! server.start()

        DispatchQueue.global().async {
            loop.runForever()
        }
    }
}
