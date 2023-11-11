import UIKit

/// As a convenience, your view controller may conform to `PathConfigurationIdentifiable`.
/// You may then use the view controller's `pathConfigurationIdentifier` property instead of `proposal.url` when deciding how to handle a proposal. See `VisitProposal.viewController` on how to use this in your configuration file.
///
/// ```
/// func handle(proposal: VisitProposal) -> ProposalResult {
///    switch proposal.viewController {
///    case RecipeViewController.pathConfigurationIdentifier:
///        return .accept(RecipeViewController.new)
///    default:
///        return .accept
///    }
/// }
/// ```
public protocol PathConfigurationIdentifiable: UIViewController {
    static var pathConfigurationIdentifier: String { get }
}
