import UIKit

/// Manipulate a navigation controller under test.
/// Ensures `viewControllers` is updated synchronously.
/// Manages `presentedViewController` directly because it isn't updated on the same thread.
class TestableNavigationController: UINavigationController {
    override var presentedViewController: UIViewController? {
        get { _presentedViewController }
        set { _presentedViewController = newValue }
    }

    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
    }

    override func popViewController(animated: Bool) -> UIViewController? {
        super.popViewController(animated: false)
    }

    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        super.popToRootViewController(animated: false)
    }

    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: false)
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        _presentedViewController = viewControllerToPresent
        super.present(viewControllerToPresent, animated: false, completion: completion)
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        _presentedViewController = nil
        super.dismiss(animated: false, completion: completion)
    }

    // MARK: Private

    private var _presentedViewController: UIViewController?
}
