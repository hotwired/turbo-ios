import Foundation
import WebKit
import Strada

enum WebViewPool {
    static var shared = WKProcessPool()
}

extension WKWebViewConfiguration {
    static var appConfiguration: WKWebViewConfiguration {
        // TODO: Add strada components
        let stradaSubstring = Strada.userAgentSubstring(for: [])
        let userAgent = "Turbo Native iOS \(stradaSubstring)"
        
        let configuration = WKWebViewConfiguration()
        configuration.processPool = WebViewPool.shared
        configuration.applicationNameForUserAgent = userAgent
        configuration.defaultWebpagePreferences?.preferredContentMode = .mobile
        
        return configuration
    }
}
