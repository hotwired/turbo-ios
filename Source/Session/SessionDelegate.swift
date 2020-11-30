import UIKit

public protocol SessionDelegate: AnyObject {
    func session(_ session: Session, didProposeVisitToURL URL: URL, options: VisitOptions, properties: PathProperties)
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error)
    func session(_ session: Session, openExternalURL URL: URL)
    func session(_ session: Session, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)

    func sessionDidLoadWebView(_ session: Session)
    func sessionDidStartRequest(_ session: Session)
    func sessionDidFinishRequest(_ session: Session)
}

public extension SessionDelegate {
    func sessionDidLoadWebView(_ session: Session) {
        session.webView.navigationDelegate = session
    }
    
    func session(_ session: Session, openExternalURL url: URL) {
        UIApplication.shared.open(url)
    }
    
    func sessionDidStartRequest(_ session: Session) {}
    func sessionDidFinishRequest(_ session: Session) {}
    
    func session(_ session: Session, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}
