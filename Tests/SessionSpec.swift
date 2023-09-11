import WebKit
import XCTest
import Quick
import Nimble
import Swifter
@testable import Turbo

private let timeout = DispatchTimeInterval.seconds(35)

class SessionSpec: QuickSpec {
    let server = HttpServer()

    override func spec() {
        var session: Session!
        var sessionDelegate: TestSessionDelegate!

        beforeSuite {
            self.startServer()
        }

        beforeEach {
            sessionDelegate = TestSessionDelegate()

            let configuration = WKWebViewConfiguration()
            configuration.applicationNameForUserAgent = "Turbo iOS Test/1.0"
            session = Session(webViewConfiguration: configuration)
            session.delegate = sessionDelegate
        }

        afterEach {
            session.webView.configuration.userContentController.removeScriptMessageHandler(forName: "turbo")
        }

        describe("init") {
            it("initializes web view with configuration") {
                expect(session.webView.configuration.applicationNameForUserAgent) == "Turbo iOS Test/1.0"
            }
        }

        describe("cold boot visit") {
            it("makes the session the visitable delegate") {
                let visitable = TestVisitable(url: self.url("/"))
                expect(visitable.visitableDelegate).to(beNil())

                session.visit(visitable)
                expect(visitable.visitableDelegate) === session
            }

            it("calls start request") {
                let visitable = TestVisitable(url: self.url("/"))
                session.visit(visitable)

                expect(sessionDelegate.sessionDidStartRequestCalled).toEventually(beTrue(), timeout: timeout)
            }

            context("when visit succeeds") {
                beforeEach {
                    let visitable = TestVisitable(url: self.url("/"))
                    session.visit(visitable)
                }

                it("calls sessionDidLoadWebView delegate method") {
                    expect(sessionDelegate.sessionDidLoadWebViewCalled).toEventually(beTrue(), timeout: timeout)
                    expect(sessionDelegate.sessionDidFailRequestCalled) == false
                }

                it("calls sessionDidFinishRequest delegate method") {
                    expect(sessionDelegate.sessionDidFinishRequestCalled).toEventually(beTrue(), timeout: timeout)
                    expect(sessionDelegate.sessionDidFailRequestCalled) == false
                }

                it("configures JavaScript bridge") {
                    expect(sessionDelegate.sessionDidLoadWebViewCalled).toEventually(beTrue(), timeout: timeout)

                    waitUntil { done in
                        session.webView.evaluateJavaScript("Turbo.navigator.adapter == window.turboNative") { result, _ in
                            XCTAssertEqual(result as? Bool, true)
                            done()
                        }
                    }
                }
            }

            context("when visit fails from http error") {
                beforeEach {
                    let visitable = TestVisitable(url: self.url("/invalid"))
                    session.visit(visitable)
                }

                it("calls sessionDidFailRequest delegate method") {
                    expect(sessionDelegate.sessionDidFailRequestCalled).toEventually(beTrue(), timeout: timeout)
                }

                it("provides an error") {
                    expect(sessionDelegate.failedRequestError).toEventuallyNot(beNil(), timeout: timeout)
                    guard let error = sessionDelegate.failedRequestError else {
                        fail("Should have gotten an error")
                        return
                    }

                    expect(error).to(matchError(TurboError.http(statusCode: 404)))
                }

                it("calls sessionDidFinishRequest delegate method") {
                    expect(sessionDelegate.sessionDidFinishRequestCalled).toEventually(beTrue(), timeout: timeout)
                }
            }

            context("when visit fails from missing library") {
                beforeEach {
                    let visitable = TestVisitable(url: self.url("/missing-library"))
                    session.visit(visitable)
                }

                it("calls sessionDidFailRequest delegate method") {
                    expect(sessionDelegate.sessionDidFailRequestCalled).toEventually(beTrue(), timeout: timeout)
                }

                it("provides an page load error") {
                    expect(sessionDelegate.failedRequestError).toEventuallyNot(beNil(), timeout: timeout)
                    guard let error = sessionDelegate.failedRequestError else {
                        fail("Should have gotten an error")
                        return
                    }

                    expect(error).to(matchError(TurboError.pageLoadFailure))
                }

                it("calls sessionDidFinishRequest delegate method") {
                    expect(sessionDelegate.sessionDidFinishRequestCalled).toEventually(beTrue(), timeout: timeout)
                }
            }

            describe("Turbolinks 5 compatibility") {
                it("loads the page and sets the adapter") {
                    let visitable = TestVisitable(url: self.url("/turbolinks"))
                    session.visit(visitable)

                    expect(sessionDelegate.sessionDidLoadWebViewCalled).toEventually(beTrue(), timeout: timeout)

                    waitUntil { done in
                        session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative") { result, _ in
                            XCTAssertEqual(result as? Bool, true)
                            done()
                        }
                    }
                }
            }

            describe("Turbolinks 5.3 compatibility") {
                it("loads the page and sets the adapter") {
                    let visitable = TestVisitable(url: self.url("/turbolinks-5.3"))
                    session.visit(visitable)

                    expect(sessionDelegate.sessionDidLoadWebViewCalled).toEventually(beTrue(), timeout: timeout)

                    waitUntil { done in
                        session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative") { result, _ in
                            XCTAssertEqual(result as? Bool, true)
                            done()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Server

    private func url(_ path: String) -> URL {
        let baseURL = URL(string: "http://localhost:8080")!
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return baseURL.appendingPathComponent(relativePath)
    }

    private func startServer() {
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
