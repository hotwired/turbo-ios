import Foundation
import SafariServices
import UIKit
import WebKit

class DefaultTurboNavigatorDelegate: NSObject, TurboNavigatorDelegate {}

/// Handles navigation to new URLs using the following rules:
/// [Turbo Navigator Handled Flows](https://github.com/hotwired/turbo-ios/Docs/TurboNavigator.md)
public class TurboNavigator {
    public unowned var delegate: TurboNavigatorDelegate

    public var rootViewController: UINavigationController { hierarchyController.navigationController }
    public var activeNavigationController: UINavigationController { hierarchyController.activeNavigationController }

    /// Set to handle customize behavior of the `WKUIDelegate`.
    ///
    /// Subclass `TurboWKUIController` to add additional behavior alongside alert/confirm dialogs.
    /// Or, provide a completely custom `WKUIDelegate` implementation.
    public var webkitUIDelegate: WKUIDelegate? {
        didSet {
            session.webView.uiDelegate = webkitUIDelegate
            modalSession.webView.uiDelegate = webkitUIDelegate
        }
    }

    /// Convenience initializer that doesn't require manually creating `Session` instances.
    /// - Parameters:
    ///   - pathConfiguration: _optional:_ remote configuration reference
    ///   - delegate: _optional:_ delegate to handle custom view controllers
    public convenience init(pathConfiguration: PathConfiguration? = nil, delegate: TurboNavigatorDelegate? = nil) {
        let session = Session(webView: Turbo.config.makeWebView())
        session.pathConfiguration = pathConfiguration

        let modalSession = Session(webView: Turbo.config.makeWebView())
        modalSession.pathConfiguration = pathConfiguration

        self.init(session: session, modalSession: modalSession, delegate: delegate)
    }

    /// Transforms `URL` -> `VisitProposal` -> `UIViewController`.
    /// Convenience function to routing a proposal directly.
    ///
    /// - Parameter url: the URL to visit
    /// - Parameter bundle: provide context relevant to `url`
    public func route(_ url: URL, parameters: [String: Any]? = nil) {
        let options = VisitOptions(action: .advance, response: nil)
        let properties = session.pathConfiguration?.properties(for: url) ?? PathProperties()
        route(VisitProposal(url: url, options: options, properties: properties, parameters: parameters))
    }

    /// Transforms `VisitProposal` -> `UIViewController`
    /// Given the `VisitProposal`'s properties, push or present this view controller.
    ///
    /// - Parameter proposal: the proposal to visit
    public func route(_ proposal: VisitProposal) {
        guard let controller = controller(for: proposal) else { return }
        hierarchyController.route(controller: controller, proposal: proposal)
    }
    
    /// Navigate to an external URL.
    ///
    /// - Parameters:
    ///   - externalURL: the URL to navigate to
    ///   - via: navigation action
    public func open(externalURL: URL, _ via: ExternalURLNavigationAction) {
        switch via {
            
        case .openViaSystem:
            UIApplication.shared.open(externalURL)
            
        case .openViaSafariController:
            /// SFSafariViewController will crash if we pass along a URL that's not valid.
            guard externalURL.scheme == "http" || externalURL.scheme == "https" else { return }
            
            let safariViewController = SFSafariViewController(url: externalURL)
            safariViewController.modalPresentationStyle = .pageSheet
            if #available(iOS 15.0, *) {
                safariViewController.preferredControlTintColor = .tintColor
            }
            
            activeNavigationController.present(safariViewController, animated: true)
            
        case .reject:
            return
        }
    }
    
    public func appDidBecomeActive() {
        appInBackground = false
        inspectAllSessions()
    }
    
    public func appDidEnterBackground() {
        appInBackground = true
    }

    // MARK: Internal

    var session: Session
    var modalSession: Session
    /// Modifies a UINavigationController according to visit proposals.
    lazy var hierarchyController = TurboNavigationHierarchyController(delegate: self)

    /// Internal initializer requiring preconfigured `Session` instances.
    ///
    /// User `init(pathConfiguration:delegate:)` to only provide a `PathConfiguration`.
    /// - Parameters:
    ///   - session: the main `Session`
    ///   - modalSession: the `Session` used for the modal navigation controller
    ///   - delegate: _optional:_ delegate to handle custom view controllers
    init(session: Session, modalSession: Session, delegate: TurboNavigatorDelegate? = nil) {
        self.session = session
        self.modalSession = modalSession

        self.delegate = delegate ?? navigatorDelegate

        self.session.delegate = self
        self.modalSession.delegate = self

        self.webkitUIDelegate = TurboWKUIController(delegate: self)
        session.webView.uiDelegate = webkitUIDelegate
        modalSession.webView.uiDelegate = webkitUIDelegate
    }

    // MARK: Private

    /// A default delegate implementation if none is provided.
    private let navigatorDelegate = DefaultTurboNavigatorDelegate()
    private var backgroundTerminatedWebViewSessions = [Session]()
    private var appInBackground = false

    private func controller(for proposal: VisitProposal) -> UIViewController? {
        switch delegate.handle(proposal: proposal) {
        case .accept:
            Turbo.config.defaultViewController(proposal.url)
        case .acceptCustom(let customViewController):
            customViewController
        case .reject:
            nil
        }
    }
}

// MARK: - SessionDelegate

extension TurboNavigator: SessionDelegate {
    public func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        guard let controller = controller(for: proposal) else { return }
        hierarchyController.route(controller: controller, proposal: proposal)
    }

    public func sessionDidStartFormSubmission(_ session: Session) {
        if let url = session.topmostVisitable?.visitableURL {
            delegate.formSubmissionDidStart(to: url)
        }
    }

    public func sessionDidFinishFormSubmission(_ session: Session) {
        if session == modalSession {
            self.session.markSnapshotCacheAsStale()
        }
        if let url = session.topmostVisitable?.visitableURL {
            delegate.formSubmissionDidFinish(at: url)
        }
    }

    public func session(_ session: Session, openExternalURL externalURL: URL) {
        let decision = delegate.handle(externalURL: externalURL)
        open(externalURL: externalURL, decision)
    }

    public func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        delegate.visitableDidFailRequest(visitable, error: error) {
            session.reload()
        }
    }

    public func sessionWebViewProcessDidTerminate(_ session: Session) {
        reloadIfPermitted(session)
    }

    public func session(_ session: Session, didReceiveAuthenticationChallenge challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate.didReceiveAuthenticationChallenge(challenge, completionHandler: completionHandler)
    }

    public func sessionDidFinishRequest(_ session: Session) {
        guard let url = session.activeVisitable?.visitableURL else { return }

        WKWebsiteDataStore.default().httpCookieStore.getAllCookies { cookies in
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: url)
        }
    }

    public func sessionDidLoadWebView(_ session: Session) {
        session.webView.navigationDelegate = session
    }
}

// MARK: - TurboNavigationHierarchyControllerDelegate

extension TurboNavigator: TurboNavigationHierarchyControllerDelegate {
    func visit(_ controller: Visitable, on navigationStack: TurboNavigationHierarchyController.NavigationStackType, with options: VisitOptions) {
        switch navigationStack {
        case .main: session.visit(controller, options: options)
        case .modal: modalSession.visit(controller, options: options)
        }
    }

    func refresh(navigationStack: TurboNavigationHierarchyController.NavigationStackType) {
        switch navigationStack {
        case .main: session.reload()
        case .modal: modalSession.reload()
        }
    }
}

extension TurboNavigator: TurboWKUIDelegate {
    public func present(_ alert: UIAlertController, animated: Bool) {
        hierarchyController.activeNavigationController.present(alert, animated: animated)
    }
}

// MARK: - Session and web view reloading

extension TurboNavigator {
    private func inspectAllSessions() {
        [session, modalSession].forEach { inspect($0) }
    }
    
    private func reloadIfPermitted(_ session: Session) {
        /// If the web view process is terminated, it leaves the web view with a white screen, so we need to reload it.
        /// However, if the web view is no longer onscreen, such as after visiting a page and going back to a native view,
        /// then reloading will unnecessarily fetch all the content, and on next visit,
        /// it will trigger various bridge messages since the web view will be added to the window and call all the connect() methods.
        ///
        /// We don't want to reload a view controller not on screen, since that can have unwanted
        /// side-effects for the next visit (like showing the wrong bridge components). We can't just
        /// check if the view controller is visible, since it may be further back in the stack of a navigation controller.
        /// Seeing if there is a parent was the best solution I could find.
        guard let viewController = session.activeVisitable?.visitableViewController,
              viewController.parent != nil else {
            return
        }
        
        if appInBackground {
            /// Don't reload the web view if the app is in the background.
            /// Instead, save the session in `backgroundTerminatedWebViewSessions`
            /// and reload it when the app is back in foreground.
            backgroundTerminatedWebViewSessions.append(session)
            return
        }
        
        reload(session)
    }
    
    private func reload(_ session: Session) {
        session.reload()
    }
    
    /// Inspects the provided session to handle terminated web view process and reloads or recreates the web view accordingly.
    ///
    /// - Parameter session: The session to inspect.
    ///
    /// This method checks if the web view associated with the session has terminated in the background. 
    /// If so, it removes the session from the list of background terminated web view processes, reloads the session, and returns.
    /// If the session's topmost visitable URL is not available, the method returns without further action.
    /// If the web view's content process state is non-recoverable/terminated, it recreates the web view for the session.
    private func inspect(_ session: Session) {
        if let index = backgroundTerminatedWebViewSessions.firstIndex(where: { $0 === session }) {
            backgroundTerminatedWebViewSessions.remove(at: index)
            reload(session)
            return
        }
        
        guard let _ = session.topmostVisitable?.visitableURL else {
            return
        }
        
        session.webView.queryWebContentProcessState { [weak self] state in
            guard case .terminated = state else { return }
            self?.recreateWebView(for: session)
        }
    }
    
    /// Recreates the web view and session for the given session and performs a `replace` visit.
    ///
    /// - Parameter session: The session to recreate.
    private func recreateWebView(for session: Session) {
        guard let _ = session.activeVisitable?.visitableViewController,
              let url = session.activeVisitable?.visitableURL else { return }
        
        let newSession = Session(webView: Turbo.config.makeWebView())
        newSession.pathConfiguration = session.pathConfiguration
        newSession.delegate = self
        newSession.webView.uiDelegate = webkitUIDelegate
        
        if session == self.session {
            self.session = newSession
        } else {
            self.modalSession = newSession
        }
        
        let options = VisitOptions(action: .replace, response: nil)
        let properties = session.pathConfiguration?.properties(for: url) ?? PathProperties()
        route(VisitProposal(url: url, options: options, properties: properties))
    }
}
