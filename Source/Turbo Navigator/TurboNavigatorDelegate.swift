import Foundation

public protocol TurboNavigatorDelegate: AnyObject {
    typealias RetryBlock = () -> Void

    /// Optional. Accept or reject a visit proposal.
    /// If accepted, you may provide a view controller to be displayed, otherwise a new `VisitableViewController` is displayed.
    /// If rejected, no changes to navigation occur.
    /// If not implemented, proposals are accepted and a new `VisitableViewController` is displayed.
    ///
    /// - Parameter proposal: navigation destination
    /// - Returns: how to react to the visit proposal
    func handle(proposal: VisitProposal) -> ProposalResult

    /// Optional. An error occurred loading the request, present it to the user.
    /// Retry the request by executing the closure.
    /// If not implemented, will present the error's localized description and a Retry button.
    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: @escaping RetryBlock)

    /// Optional. Respond to authentication challenge presented by web servers behing basic auth.
    /// If not implemented, default handling will be performed.
    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    
    /// Optional. Called when a form is submitted.
    /// If not implemented, no action is taken.
    func didSubmitForm(at url: URL)
}

public extension TurboNavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        .accept
    }

    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: @escaping RetryBlock) {
        if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error, handler: retry)
        }
    }

    func didReceiveAuthenticationChallenge(_ challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
    }
    
    func didSubmitForm(at url: URL) {}
}
