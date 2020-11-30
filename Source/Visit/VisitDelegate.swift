import Foundation

protocol VisitDelegate: class {
    func visitDidInitializeWebView(_ visit: Visit)
    
    func visitWillStart(_ visit: Visit)
    func visitDidStart(_ visit: Visit)
    func visitDidComplete(_ visit: Visit)
    func visitDidFail(_ visit: Visit)
    func visitDidFinish(_ visit: Visit)
    
    func visitWillLoadResponse(_ visit: Visit)
    func visitDidRender(_ visit: Visit)
    
    func visitRequestDidStart(_ visit: Visit)
    func visit(_ visit: Visit, requestDidFailWithError error: NSError)
    func visitRequestDidFinish(_ visit: Visit)
    
    func visit(_ visit: Visit, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}
