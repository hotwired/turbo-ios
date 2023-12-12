import Foundation

public protocol TurboNavigatorDelegate: AnyObject {
    typealias RetryBlock = () -> Void

    /// Accept or reject a visit proposal.
    /// There are three `ProposalResult` cases:
    ///    - term `accept`: Proposals are accepted and a new `VisitableViewController` is displayed.
    ///    - term `acceptCustom(UIViewController)`: You may provide a view controller to be displayed, otherwise a new `VisitableViewController` is displayed.
    ///    - term `reject`: No changes to navigation occur.
    ///
    /// - Parameter proposal: `VisitProposal` navigation destination
    /// - Returns:`ProposalResult` - how to react to the visit proposal
    /// - Note: optional
    func handle(proposal: VisitProposal) -> ProposalResult

    func handle(externalURL: URL) -> ExternalURLNavigationAction
    
    /// An error occurred loading the request, present it to the user.
    /// Retry the request by executing the closure.
    /// - Important: If not implemented, will present the error's localized description and a Retry button.
    /// - Note: optional
    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: @escaping RetryBlock)

    /// Respond to authentication challenge presented by web servers behing basic auth.
    /// If not implemented, default handling will be performed.
    /// - Note: optional
    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
}

public extension TurboNavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        .accept
    }
    
    func handle(externalURL: URL) -> ExternalURLNavigationAction {
        .openViaSafariController
    }

    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: @escaping RetryBlock) {
        if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error, handler: retry)
        }
    }

    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
}
