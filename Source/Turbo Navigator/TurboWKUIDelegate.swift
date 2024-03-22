import Foundation
import WebKit

public protocol TurboWKUIDelegate: AnyObject {
    func present(_ alert: UIAlertController, animated: Bool)
}

open class TurboWKUIController: NSObject, WKUIDelegate {
    private unowned var delegate: TurboWKUIDelegate

    public init(delegate: TurboWKUIDelegate!) {
        self.delegate = delegate
    }

    open func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default) { _ in
            completionHandler()
        })
        delegate.present(alert, animated: true)
    }

    open func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .destructive) { _ in
            completionHandler(true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        })
        delegate.present(alert, animated: true)
    }
}
