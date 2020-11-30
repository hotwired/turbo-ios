import Quick
import Nimble
import WebKit
@testable import Turbo

class ColdBootVisitSpec: QuickSpec {
    override func spec() {
        var webView: WebView!
        var visit: ColdBootVisit!
        var visitDelegate: TestVisitDelegate!
        let url = URL(string: "http://localhost/")!
        
        beforeEach {
            webView = WebView(configuration: WKWebViewConfiguration())
            visitDelegate = TestVisitDelegate()
            visit = ColdBootVisit(visitable: TestVisitable(url: url), options: .defaultOptions, webView: webView)
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
                print(visitDelegate.methodsCalled)
            }
            
            it("kicks off the web view load") {
                
            }
            
            it("becomes the navigation delegate") {
                expect(webView.navigationDelegate) === visit
            }
            
            it("notifies the delegate the visit did start") {
                visit.start()
                expect(visitDelegate.didCall("visitDidStart(_:)")).toEventually(beTrue())
                print(visitDelegate.methodsCalled)
            }
            
            it("ignores the call if already started") {
                visit.start()
                expect(visitDelegate.methodsCalled.contains("visitDidStart(_:)")).toEventually(beTrue())
                print(visitDelegate.methodsCalled)

                visitDelegate.methodsCalled.remove("visitDidStart(_:)")
                visit.start()
                expect(visitDelegate.didCall("visitDidStart(_:)")).toEventually(beFalse())
            }
        }
    }
}


class TestVisitDelegate: VisitDelegate {
    var methodsCalled: Set<String> = []
    
    init() {
    }
    
    func didCall(_ method: String) -> Bool {
        methodsCalled.contains(method)
    }
    
    func visitDidInitializeWebView(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitWillStart(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitDidStart(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitDidComplete(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitDidFail(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitDidFinish(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitWillLoadResponse(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitDidRender(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visitRequestDidStart(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visit(_ visit: Visit, requestDidFailWithError error: NSError) {
        methodsCalled.insert(#function)
    }
    
    func visitRequestDidFinish(_ visit: Visit) {
        methodsCalled.insert(#function)
    }
    
    func visit(_ visit: Visit, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        methodsCalled.insert(#function)
    }
}
