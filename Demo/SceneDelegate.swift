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
}

extension SceneDelegate: SessionDelegate {
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true)
    }
    
    func session(_ session: Session, didProposeVisitToURL url: URL, options: VisitOptions, properties: PathProperties) {
        let viewController = VisitableViewController(url: url)
        
        if options.action == .replace {
            navigationController.viewControllers = navigationController.viewControllers.dropLast() + [viewController]
        } else {
            navigationController.pushViewController(viewController, animated: true)
        }
        
        session.visit(viewController)
    }
}
