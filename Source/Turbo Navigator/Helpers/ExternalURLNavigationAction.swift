import Foundation

/// When TurboNavigator encounters an external URL, its delegate may handle it with any of these actions.
public enum ExternalURLNavigationAction {
    /// Attempts to open via an embedded `SafariViewController` so the user stays in-app.
    /// Silently fails if you pass a URL that's not `http` or `https`.
    case openViaSafariController
    
    /// Attempts to open via `openURL(_:options:completionHandler)`.
    /// This is useful if the external URL is a deeplink.
    case openViaSystem
    
    /// Will do nothing with the external URL.
    case reject
}
