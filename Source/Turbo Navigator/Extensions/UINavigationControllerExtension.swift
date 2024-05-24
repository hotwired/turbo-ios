import UIKit

extension UINavigationController {
    func replaceLastViewController(with viewController: UIViewController) {
        let viewControllers = viewControllers.dropLast()
        setViewControllers(viewControllers + [viewController], animated: false)
    }

    func setModalPresentationStyle(via proposal: VisitProposal) {
        switch proposal.modalStyle {
        case .custom:
            break
        case .medium:
            modalPresentationStyle = .automatic
            if #available(iOS 15.0, *) {
                if let sheet = sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                }
            }
        case .large:
            modalPresentationStyle = .automatic
        case .full:
            modalPresentationStyle = .fullScreen
        }
    }
}
