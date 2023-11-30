import SafariServices
import UIKit
import WebKit

class TurboNavigationHierarchyController {
    let navigationController: UINavigationController
    let modalNavigationController: UINavigationController

    var rootViewController: UIViewController { navigationController }
    var activeNavigationController: UINavigationController {
        navigationController.presentedViewController != nil ? modalNavigationController : navigationController
    }

    enum NavigationStackType {
        case main
        case modal
    }

    func navController(for navigationType: NavigationStackType) -> UINavigationController {
        switch navigationType {
            case .main: navigationController
            case .modal: modalNavigationController
        }
    }

    init(delegate: TurboNavigationHierarchyControllerDelegate, navigationControler: UINavigationController = UINavigationController(), modalNavigationController: UINavigationController = UINavigationController()) {
        self.delegate = delegate
        self.navigationController = navigationControler
        self.modalNavigationController = modalNavigationController
    }

    func route(controller: UIViewController, proposal: VisitProposal) {
        if let alert = controller as? UIAlertController {
            presentAlert(alert)
        } else {
            switch proposal.presentation {
            case .default:
                navigate(with: controller, via: proposal)
            case .pop:
                pop()
            case .replace:
                replace(with: controller, via: proposal)
            case .refresh:
                refresh()
            case .clearAll:
                clearAll()
            case .replaceRoot:
                replaceRoot(with: controller)
            case .none:
                break // Do nothing.
            }
        }
    }

    // MARK: Private

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private unowned let delegate: TurboNavigationHierarchyControllerDelegate

    private func presentAlert(_ alert: UIAlertController) {
        if navigationController.presentedViewController != nil {
            modalNavigationController.present(alert, animated: true)
        } else {
            navigationController.present(alert, animated: true)
        }
    }

    private func navigate(with controller: UIViewController, via proposal: VisitProposal) {
        switch proposal.context {
        case .default:
            navigationController.dismiss(animated: true)
            pushOrReplace(on: navigationController, with: controller, via: proposal)
            if let visitable = controller as? Visitable {
                delegate.visit(visitable, on: .main, with: proposal.options)
            }
        case .modal:
            if navigationController.presentedViewController != nil {
                pushOrReplace(on: modalNavigationController, with: controller, via: proposal)
            } else {
                modalNavigationController.setViewControllers([controller], animated: true)
                navigationController.present(modalNavigationController, animated: true)
            }
            if let visitable = controller as? Visitable {
                delegate.visit(visitable, on: .modal, with: proposal.options)
            }
        }
    }

    private func pushOrReplace(on navigationController: UINavigationController, with controller: UIViewController, via proposal: VisitProposal) {
        if visitingSamePage(on: navigationController, with: controller, via: proposal.url) {
            navigationController.replaceLastViewController(with: controller)
        } else if visitingPreviousPage(on: navigationController, with: controller, via: proposal.url) {
            navigationController.popViewController(animated: true)
        } else if proposal.options.action == .advance {
            navigationController.pushViewController(controller, animated: true)
        } else {
            navigationController.replaceLastViewController(with: controller)
        }
    }

    private func visitingSamePage(on navigationController: UINavigationController, with controller: UIViewController, via url: URL) -> Bool {
        if let visitable = navigationController.topViewController as? Visitable {
            return visitable.visitableURL == url
        } else if let topViewController = navigationController.topViewController {
            return topViewController.isMember(of: type(of: controller))
        }
        return false
    }

    private func visitingPreviousPage(on navigationController: UINavigationController, with controller: UIViewController, via url: URL) -> Bool {
        guard navigationController.viewControllers.count >= 2 else { return false }

        let previousController = navigationController.viewControllers[navigationController.viewControllers.count - 2]
        if let previousVisitable = previousController as? VisitableViewController {
            return previousVisitable.visitableURL == url
        }
        return type(of: previousController) == type(of: controller)
    }

    private func pop() {
        if navigationController.presentedViewController != nil {
            if modalNavigationController.viewControllers.count == 1 {
                navigationController.dismiss(animated: true)
            } else {
                modalNavigationController.popViewController(animated: true)
            }
        } else {
            navigationController.popViewController(animated: true)
        }
    }

    private func replace(with controller: UIViewController, via proposal: VisitProposal) {
        switch proposal.context {
        case .default:
            navigationController.dismiss(animated: true)
            navigationController.replaceLastViewController(with: controller)
            if let visitable = controller as? Visitable {
                delegate.visit(visitable, on: .main, with: proposal.options)
            }
        case .modal:
            if navigationController.presentedViewController != nil {
                modalNavigationController.replaceLastViewController(with: controller)
            } else {
                modalNavigationController.setViewControllers([controller], animated: false)
                navigationController.present(modalNavigationController, animated: true)
            }
            if let visitable = controller as? Visitable {
                delegate.visit(visitable, on: .modal, with: proposal.options)
            }
        }
    }

    private func refresh() {
        if navigationController.presentedViewController != nil {
            if modalNavigationController.viewControllers.count == 1 {
                navigationController.dismiss(animated: true)
                delegate.refresh(navigationStack: .main)
            } else {
                modalNavigationController.popViewController(animated: true)
                delegate.refresh(navigationStack: .modal)
            }
        } else {
            navigationController.popViewController(animated: true)
            delegate.refresh(navigationStack: .main)
        }
    }

    private func clearAll() {
        navigationController.dismiss(animated: true)
        navigationController.popToRootViewController(animated: true)
        delegate.refresh(navigationStack: .main)
    }

    private func replaceRoot(with controller: UIViewController) {
        navigationController.dismiss(animated: true)
        navigationController.setViewControllers([controller], animated: true)

        if let visitable = controller as? Visitable {
            delegate.visit(visitable, on: .main, with: .init(action: .replace))
        }
    }
}
