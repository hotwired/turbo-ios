import UIKit

/// As a convenience, a view controller may conform to `PathConfigurationIdentifiable`.
///
/// Use a view controller's `pathConfigurationIdentifier` property instead of `proposal.url` when deciding how to handle a proposal.
///
/// ```swift
/// func handle(proposal: VisitProposal) -> ProposalResult {
///    switch proposal.viewController {
///    case RecipeViewController.pathConfigurationIdentifier:
///        return .acceptCustom(RecipeViewController())
///    default:
///        return .accept
///    }
/// }
/// ```
/// - Note: See `VisitProposal.viewController` on how to use this in your configuration file.
public protocol PathConfigurationIdentifiable: UIViewController {
    static var pathConfigurationIdentifier: String { get }
}
