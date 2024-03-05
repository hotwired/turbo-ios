import SafariServices
import WebKit

/// Implement to be notified when certain navigations are performed
/// or to render a native controller instead of a Turbo web visit.
protocol TurboNavigationHierarchyControllerDelegate: AnyObject {
    func visit(_ : Visitable, on: NavigationStackType, with: VisitOptions)
    func refresh(navigationStack: NavigationStackType)
}
