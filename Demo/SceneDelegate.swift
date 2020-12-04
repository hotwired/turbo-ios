import UIKit
import Turbo

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private lazy var session: Session = {
        let session = Session()
        session.delegate = self
        session.pathConfiguration = PathConfiguration(sources: [
            .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!)
        ])
        return session
    }()
    
    private lazy var navigationController = UINavigationController()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let viewController = VisitableViewController(url: Demo.current)
        navigationController.viewControllers = [viewController]
        window?.rootViewController = navigationController
        self.session.visit(viewController)
    }
    
    private func route(url: URL, options: VisitOptions, properties: PathProperties) {
        // This is a simplified version of what you might do in your app
        // You can look at the path or properties and decide how to render and navigate
        // to each url. For example, here we look at the path and decide to load a native
        // view controller for "/numbers" screen
        let viewController: UIViewController
        
        switch url.path {
        case "/numbers":
            viewController = NumbersViewController()
        default:
            viewController = VisitableViewController(url: url)
        }
        
        navigate(to: viewController, action: options.action)
        
        if let visitable = viewController as? Visitable {
            session.visit(visitable)
        }
    }
    
    private func navigate(to viewController: UIViewController, action: VisitAction) {
        if action == .replace {
            navigationController.viewControllers = navigationController.viewControllers.dropLast() + [viewController]
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
    }
}

extension SceneDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        route(url: proposal.url, options: proposal.options, properties: proposal.properties)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true)
    }
}
