import WebKit
import XCTest
import Quick
import Nimble
import GCDWebServers
@testable import Turbo

private let timeout = DispatchTimeInterval.seconds(5)

class SessionSpec: QuickSpec {
    let server = GCDWebServer()

    override func spec() {
        var session: Session!
        var sessionDelegate: TestSessionDelegate!
        
        beforeSuite {
            self.startServer()
        }
        
        afterSuite {
            self.stopServer()
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
                        session.webView.evaluateJavaScript("Turbo.navigator.adapter == window.turboNative") { result, error in
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
                        session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative") { result, error in
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
                        session.webView.evaluateJavaScript("Turbolinks.controller.adapter === window.turboNative") { result, error in
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
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return server.serverURL!.appendingPathComponent(relativePath)
    }
    
    private func startServer() {
        let bundle = Bundle(for: SessionSpec.self)
        let resources = bundle.resourcePath!
        
        server.addGETHandler(forBasePath: "/", directoryPath: resources, indexFilename: "turbo.html", cacheAge: 0, allowRangeRequests: true)

        server.addHandler(forMethod: "GET", path: "/turbolinks", request: GCDWebServerRequest.self) { _ in
            GCDWebServerDataResponse(data: try! Data(contentsOf: bundle.url(forResource: "turbolinks", withExtension: "html")!), contentType: "text/html")
        }
        
        server.addHandler(forMethod: "GET", path: "/turbolinks-5.3", request: GCDWebServerRequest.self) { _ in
            GCDWebServerDataResponse(data: try! Data(contentsOf: bundle.url(forResource: "turbolinks-5.3", withExtension: "html")!), contentType: "text/html")
        }
        
        server.addHandler(forMethod: "GET", path: "/missing-library", request: GCDWebServerRequest.self) { _ in
            GCDWebServerDataResponse(html: "<html></html>")
        }
        
        server.addHandler(forMethod: "GET", path: "/invalid", request: GCDWebServerRequest.self) { _ in
            GCDWebServerResponse(statusCode: 404)
        }
        
        server.start(withPort: 8080, bonjourName: nil)
    }
    
    private func stopServer() {
        server.stop()
    }
}
