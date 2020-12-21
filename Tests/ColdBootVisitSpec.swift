import Quick
import Nimble
import WebKit
@testable import Turbo

class ColdBootVisitSpec: QuickSpec {
    override func spec() {
        var webView: WKWebView!
        var bridge: WebViewBridge!
        var visit: ColdBootVisit!
        var visitDelegate: TestVisitDelegate!
        let url = URL(string: "http://localhost/")!
        
        beforeEach {
            webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
            bridge = WebViewBridge(webView: webView)
            visitDelegate = TestVisitDelegate()
            visit = ColdBootVisit(visitable: TestVisitable(url: url), options: VisitOptions(), bridge: bridge)
            visit.delegate = visitDelegate
        }
        
        describe(".start()") {
            beforeEach {
                expect(visit.state) == .initialized
                visit.start()
            }
            
            it("transitions to a started state") {
                expect(visit.state) == .started
            }
            
            it("notifies the delegate the visit will start") {
                expect(visitDelegate.didCall("visitWillStart(_:)")).toEventually(beTrue())
            }
            
            it("kicks off the web view load") {
                expect(visit.navigation).toNot(beNil())
            }
            
            it("becomes the navigation delegate") {
                expect(webView.navigationDelegate) === visit
            }
            
            it("notifies the delegate the visit did start") {
                visit.start()
                expect(visitDelegate.didCall("visitDidStart(_:)")).toEventually(beTrue())
            }
            
            it("ignores the call if already started") {
                visit.start()
                expect(visitDelegate.methodsCalled.contains("visitDidStart(_:)")).toEventually(beTrue())

                visitDelegate.methodsCalled.remove("visitDidStart(_:)")
                visit.start()
                expect(visitDelegate.didCall("visitDidStart(_:)")).toEventually(beFalse())
            }
        }
    }
}

private class TestVisitDelegate: VisitDelegate {
    var methodsCalled: Set<String> = []
    
    init() {
    }
    
    func didCall(_ method: String) -> Bool {
        methodsCalled.contains(method)
    }
    
    func visitDidInitializeWebView(_ visit: Visit) {
        record(#function)
    }
    
    func visitWillStart(_ visit: Visit) {
        record(#function)
    }
    
    func visitDidStart(_ visit: Visit) {
        record(#function)
    }
    
    func visitDidComplete(_ visit: Visit) {
        record(#function)
    }
    
    func visitDidFail(_ visit: Visit) {
        record(#function)
    }
    
    func visitDidFinish(_ visit: Visit) {
        record(#function)
    }
    
    func visitWillLoadResponse(_ visit: Visit) {
        record(#function)
    }
    
    func visitDidRender(_ visit: Visit) {
        record(#function)
    }
    
    func visitRequestDidStart(_ visit: Visit) {
        record(#function)
    }
    
    func visit(_ visit: Visit, requestDidFailWithError error: Error) {
        record(#function)
    }
    
    func visitRequestDidFinish(_ visit: Visit) {
        record(#function)
    }
    
    func visit(_ visit: Visit, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        record(#function)
    }
    
    private func record(_ string: String) {
        methodsCalled.insert(string)
    }
}
