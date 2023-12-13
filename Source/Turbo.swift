import WebKit

public enum Turbo {
    public static var config = TurboConfig()
}

public class TurboConfig {
    public typealias WebViewBlock = (_ configuration: WKWebViewConfiguration) -> WKWebView

    /// Override to set a custom user agent.
    /// Include "Turbo Native" to use `turbo_native_app?` on your Rails server.
    public var userAgent = "Turbo Native iOS"

    /// The view controller used in `TurboNavigator` for web requests. Must be
    /// a `VisitableViewController` or subclass.
    public var defaultViewController: (URL) -> VisitableViewController = { url in
        VisitableViewController(url: url)
    }

    /// Optionally customize the web views used by each Turbo Session.
    /// Ensure you return a new instance each time.
    public var makeCustomWebView: WebViewBlock = { (configuration: WKWebViewConfiguration) in
        WKWebView(frame: .zero, configuration: configuration)
    }

    public var debugLoggingEnabled = false {
        didSet {
            TurboLogger.debugLoggingEnabled = debugLoggingEnabled
        }
    }

    // MARK: - Internal

    public func makeWebView() -> WKWebView {
        makeCustomWebView(makeWebViewConfiguration())
    }

    // MARK: - Private

    private let sharedProcessPool = WKProcessPool()

    // A method (not a property) because we need a new instance for each web view.
    private func makeWebViewConfiguration() -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = userAgent
        configuration.processPool = sharedProcessPool
        return configuration
    }
}
