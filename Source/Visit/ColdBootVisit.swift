import Foundation
import WebKit

/// A "Cold Boot" visit is the initial visit to load the page, including all resources
/// Subsequent visits go through Turbo and use `JavaScriptVisit`
final class ColdBootVisit: Visit {
    private(set) var navigation: WKNavigation?

    override func startVisit() {
        log("startVisit")

        webView.navigationDelegate = self
        bridge.pageLoadDelegate = self

        if let response = options.response, response.isSuccessful, let body = response.responseHTML {
            navigation = webView.loadHTMLString(body, baseURL: location)
        } else {
            navigation = webView.load(URLRequest(url: location))
        }

        delegate?.visitDidStart(self)
        startRequest()
    }

    override func cancelVisit() {
        log("cancelVisit")
        
        removeNavigationDelegate()
        webView.stopLoading()
        finishRequest()
    }

    override func completeVisit() {
        log("completeVisit")
        
        removeNavigationDelegate()
        delegate?.visitDidInitializeWebView(self)
    }

    override func failVisit() {
        log("failVisit")
        
        removeNavigationDelegate()
        finishRequest()
    }

    private func removeNavigationDelegate() {
        guard webView.navigationDelegate === self else { return }
        webView.navigationDelegate = nil
    }
    
    private func log(_ name: String) {
        debugLog("[ColdBootVisit] \(name) \(location.absoluteString)")
    }
}

extension ColdBootVisit: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard navigation == self.navigation else { return }
        finishRequest()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Ignore any clicked links before the cold boot finishes navigation
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let httpResponse = navigationResponse.response as? HTTPURLResponse {
            if httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                fail(with: TurboError.http(statusCode: httpResponse.statusCode))
            }
        } else {
            if (navigationResponse.response.url?.scheme == "blob") {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
                fail(with: TurboError.http(statusCode: 0))
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard navigation == self.navigation else { return }
        fail(with: error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard navigation == self.navigation else { return }
        fail(with: error)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.visit(self, didReceiveAuthenticationChallenge: challenge, completionHandler: completionHandler)
    }
}

extension ColdBootVisit: WebViewPageLoadDelegate {
    func webView(_ bridge: WebViewBridge, didLoadPageWithRestorationIdentifier restorationIdentifier: String) {
        self.restorationIdentifier = restorationIdentifier
        delegate?.visitDidRender(self)
        complete()
    }
}
