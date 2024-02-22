import UIKit

public extension VisitProposal {
    var context: TurboNavigation.Context {
        if let rawValue = properties["context"] as? String {
            return TurboNavigation.Context(rawValue: rawValue) ?? .default
        }
        return .default
    }

    var presentation: TurboNavigation.Presentation {
        if let rawValue = properties["presentation"] as? String {
            return TurboNavigation.Presentation(rawValue: rawValue) ?? .default
        }
        return .default
    }

    var modalStyle: TurboNavigation.ModalStyle {
        if let rawValue = properties["modal_style"] as? String {
            return TurboNavigation.ModalStyle(rawValue: rawValue) ?? .large
        }
        return .large
    }

    var pullToRefreshEnabled: Bool {
        properties["pull_to_refresh_enabled"] as? Bool ?? true
    }

    /// Used to identify a custom native view controller if provided in the path configuration properties of a given pattern.
    ///
    /// For example, given the following configuration file:
    ///
    /// ```json
    /// {
    ///   "rules": [
    ///     {
    ///       "patterns": [
    ///         "/recipes/*"
    ///       ],
    ///       "properties": {
    ///         "view_controller": "recipes",
    ///       }
    ///     }
    ///  ]
    /// }
    /// ```
    ///
    /// A VisitProposal to `https://example.com/recipes/` will have 
    /// ```swift
    /// proposal.viewController == "recipes"
    /// ```
    ///
    /// - Important: A default value is provided in case the view controller property is missing from the configuration file. This will route the default `VisitableViewController`.
    /// - Note: A `ViewController` must conform to `PathConfigurationIdentifiable` to couple the identifier with a view controlelr.
    var viewController: String {
        if let viewController = properties["view_controller"] as? String {
            return viewController
        }

        return VisitableViewController.pathConfigurationIdentifier
    }
}
