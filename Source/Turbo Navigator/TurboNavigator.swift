import Foundation
import SafariServices
import UIKit
import WebKit

class DefaultTurboNavigatorDelegate: NSObject, TurboNavigatorDelegate {}

/// Handles navigation to new URLs using the following rules:
/// https://github.com/hotwired/turbo-ios/Docs/TurboNavigator.md
public class TurboNavigator {
    public unowned var delegate: TurboNavigatorDelegate

    public var rootViewController: UINavigationController { hierarchyController.navigationController }
    public var activeNavigationController: UINavigationController { hierarchyController.activeNavigationController }

    /// Set to handle customize behavior of the `WKUIDelegate`.
    /// Subclass `TurboWKUIController` to add additional behavior alongside alert/confirm dialogs.
    /// Or, provide a completely custom `WKUIDelegate` implementation.
    public var webkitUIDelegate: WKUIDelegate? {
        didSet {
            session.webView.uiDelegate = webkitUIDelegate
            modalSession.webView.uiDelegate = webkitUIDelegate
        }
    }

    /// Default initializer requiring preconfigured `Session` instances.
    /// User `init(pathConfiguration:delegate)` to only provide a `PathConfiguration`.
    /// - Parameters:
    ///   - session: the main `Session`
    ///   - modalSession: the `Session` used for the modal navigation controller
    ///   - delegate: an optional delegate to handle custom view controllers
    public init(session: Session, modalSession: Session, delegate: TurboNavigatorDelegate? = nil) {
        self.session = session
        self.modalSession = modalSession

        self.delegate = delegate ?? navigatorDelegate

        self.session.delegate = self
        self.modalSession.delegate = self

        self.webkitUIDelegate = TurboWKUIController(delegate: self)
        session.webView.uiDelegate = webkitUIDelegate
        modalSession.webView.uiDelegate = webkitUIDelegate
    }

    /// Convenience initializer that doesn't require manually creating `Session` instances.
    /// - Parameters:
    ///   - pathConfiguration: an optional remote configuration reference
    ///   - delegate: an optional delegate to handle custom view controllers
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
    public func route(_ url: URL) {
        let options = VisitOptions(action: .advance, response: nil)
        let properties = session.pathConfiguration?.properties(for: url) ?? PathProperties()
        route(VisitProposal(url: url, options: options, properties: properties))
    }

    /// Transforms `VisitProposal` -> `UIViewController`
    /// Given the `VisitProposal`'s properties, push or present this view controller.
    ///
    /// - Parameter proposal: the proposal to visit
    public func route(_ proposal: VisitProposal) {
        guard let controller = controller(for: proposal) else { return }
        hierarchyController.route(controller: controller, proposal: proposal)
    }

    let session: Session
    let modalSession: Session

    /// Modifies a UINavigationController according to visit proposals.
    lazy var hierarchyController = TurboNavigationHierarchyController(delegate: self)

    /// A default delegate implementation if none is provided.
    private let navigatorDelegate = DefaultTurboNavigatorDelegate()

    private func controller(for proposal: VisitProposal) -> UIViewController? {
        switch delegate.handle(proposal: proposal) {
            case .accept:
                return VisitableViewController(url: proposal.url)
            case .acceptCustom(let customViewController):
                return customViewController
            case .reject:
                return nil
        }
    }
}

// MARK: - SessionDelegate

extension TurboNavigator: SessionDelegate {
    public func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        guard let controller = controller(for: proposal) else { return }
        hierarchyController.route(controller: controller, proposal: proposal)
    }

    public func sessionDidFinishFormSubmission(_ session: Session) {
        if session == modalSession {
            self.session.clearSnapshotCache()
        }
    }

    public func session(_ session: Session, openExternalURL url: URL) {
        let navigationType: TurboNavigationHierarchyController.NavigationStackType = session === modalSession ? .modal : .main
        hierarchyController.openExternal(url: url, navigationType: navigationType)
    }

    public func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        delegate.visitableDidFailRequest(visitable, error: error) {
            session.reload()
        }
    }

    public func sessionWebViewProcessDidTerminate(_ session: Session) {
        session.reload()
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
    func visit(_ controller: Visitable, on navigationStack: TurboNavigationHierarchyController.NavigationStackType, with: VisitOptions) {
        switch navigationStack {
            case .main: session.visit(controller, action: .advance)
            case .modal: modalSession.visit(controller, action: .advance)
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
