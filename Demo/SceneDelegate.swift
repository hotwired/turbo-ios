import UIKit
import Turbo

struct Demos {
    static let simple = URL(string: "https://turbo-native-simple-demo.glitch.me")!
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private var session: Session!
    private lazy var navigationController = UINavigationController()
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        session = Session()
        session.delegate = self
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        
        let viewController = VisitableViewController(url: Demos.simple)
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
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true)
    }
    
    func session(_ session: Session, didProposeVisitToURL url: URL, options: VisitOptions, properties: PathProperties) {
        route(url: url, options: options, properties: properties)
    }
}
