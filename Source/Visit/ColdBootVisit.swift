import Foundation
import WebKit

final class ColdBootVisit: Visit, WKNavigationDelegate, WebViewPageLoadDelegate {
    private var navigation: WKNavigation?

    override func startVisit() {
        debugLog(self)

        webView.navigationDelegate = self
        webView.pageLoadDelegate = self

        if let response = options.response, response.isSuccessful, let body = response.responseHTML {
            navigation = webView.loadHTMLString(body, baseURL: location)
        } else {
            navigation = webView.load(URLRequest(url: location))
        }

        delegate?.visitDidStart(self)
        startRequest(at: Date())
    }

    override func cancelVisit() {
        removeNavigationDelegate()
        webView.stopLoading()
        finishRequest(at: Date())
    }

    override func completeVisit() {
        removeNavigationDelegate()
        delegate?.visitDidInitializeWebView(self)
    }

    override func failVisit() {
        removeNavigationDelegate()
        finishRequest(at: Date())
    }

    private func removeNavigationDelegate() {
        guard webView.navigationDelegate === self else { return }
        webView.navigationDelegate = nil
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard navigation == self.navigation else { return }
        finishRequest(at: Date())
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
            decisionHandler(.cancel)
            fail(with: TurboError.http(statusCode: 0))
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

    // MARK: - WebViewPageLoadDelegate

    func webView(_ webView: WebView, didLoadPageWithRestorationIdentifier restorationIdentifier: String) {
        self.restorationIdentifier = restorationIdentifier
        delegate?.visitDidRender(self)
        complete()
    }
}
