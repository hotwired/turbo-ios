import Foundation

/// Contract for handling navigation requests and actions
/// - Note: Methods  are __optional__ by default implementation in ``TurboNavigatorDelegate`` extension.
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
    func handle(proposal: VisitProposal) -> ProposalResult

    func handle(externalURL: URL) -> ExternalURLNavigationAction
    
    /// An error occurred loading the request, present it to the user.
    /// Retry the request by executing the closure.
    /// - Important: If not implemented, will present the error's localized description and a Retry button.
    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: RetryBlock?)

    /// Respond to authentication challenge presented by web servers behing basic auth.
    /// If not implemented, default handling will be performed.
    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    /// Optional. Called after a form starts a submission.
    /// If not implemented, no action is taken.
    func formSubmissionDidStart(to url: URL)

    /// Optional. Called after a form finishes a submission.
    /// If not implemented, no action is taken.
    func formSubmissionDidFinish(at url: URL)
}

public extension TurboNavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        .accept
    }
    
    func handle(externalURL: URL) -> ExternalURLNavigationAction {
        .openViaSafariController
    }

    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: RetryBlock?) {
        if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error, handler: retry)
        }
    }

    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }

    func formSubmissionDidStart(to url: URL) {}

    func formSubmissionDidFinish(at url: URL) {}
}
