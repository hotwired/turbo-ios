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
            // Ensure no messages come through later
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
            }
            
            context("when visit fails") {
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
        }
    }
    
    // MARK: - Server
    
    private func url(_ path: String) -> URL {
        let relativePath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return server.serverURL!.appendingPathComponent(relativePath)
    }
    
    private func startServer() {
        server.addGETHandler(forBasePath: "/", directoryPath: Bundle(for: SessionSpec.self).resourcePath!, indexFilename: "index.html", cacheAge: 0, allowRangeRequests: true)
        
        server.addHandler(forMethod: "GET", path: "/invalid", request: GCDWebServerRequest.self) { request in
            return GCDWebServerResponse(statusCode: 404)
        }
        
        server.start(withPort: 8080, bonjourName: nil)
    }
    
    private func stopServer() {
        server.stop()
    }
}
