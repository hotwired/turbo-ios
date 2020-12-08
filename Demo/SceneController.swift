import UIKit
import WebKit
import Turbo

final class SceneController: UIResponder {
    var window: UIWindow?
    private var navigationController: UINavigationController!
    
    // MARK: - Setup
    
    private func configureRootViewController() {
        guard let window = window else {
            fatalError()
        }
        
        if let navController = window.rootViewController as? UINavigationController {
            navigationController = navController
        } else {
            window.rootViewController = UINavigationController()
        }
    }
    
    // MARK: - Routing/Navigation
    
    private func route(url: URL, options: VisitOptions, properties: PathProperties) {
        // This is a simplified version of how you might build out the routing
        // and navigation functions of your app. In a real app, these would be separate objects
        
        // Dismiss any modals when receiving a new navigation
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true)
        }
        
        // - Create view controller appropriate for url/properties
        // - Navigate to that with the correct presentation
        // - Initiate the visit with Turbo
        let viewController = makeViewController(for: url, properties: properties)
        navigate(to: viewController, action: options.action, properties: properties)
        visit(viewController: viewController, modal: isModal(properties))
    }
    
    private func makeViewController(for url: URL, properties: PathProperties = [:]) -> UIViewController {
        // There are many options for determining how to map urls to view controllers
        // The demo uses the path configuration for determining which view controller and presentation
        // to use, but that's completely optional. You can use whatever logic you prefer to determine
        // how you navigate and route different URLs.
        
        if let viewController = properties["view-controller"] as? String, viewController == "numbers" {
            return NumbersViewController()
        } else {
            return ViewController(url: url)
        }
    }
    
    private func visit(viewController: UIViewController, modal: Bool = false) {
        guard let visitable = viewController as? Visitable else { return }
        
        // Each Session corresponds to a single web view. A good rule of thumb
        // is to use a session per navigation stack. Here we're using a different session
        // when presenting a modal. We keep that around for any modal presentations so
        // we don't have to create more than we need since each new session incurs a cold boot visit cost
        if modal {
            modalSession.visit(visitable)
        } else {
            session.visit(visitable)
        }
    }
    
    private func navigate(to viewController: UIViewController, action: VisitAction, properties: PathProperties = [:], animated: Bool = true) {
        // We support three types of navigation in the app: advance, replace, and modal
        
        if isModal(properties) {
            let modalNavController = UINavigationController(rootViewController: viewController)
            navigationController.present(modalNavController, animated: animated)
        } else if action == .replace {
            let viewControllers = Array(navigationController.viewControllers.dropLast()) + [viewController]
            navigationController.setViewControllers(viewControllers, animated: false)
        } else {
            navigationController.pushViewController(viewController, animated: animated)
        }
    }
    
    private func isModal(_ properties: PathProperties) -> Bool {
        // For simplicity, we're using string literals for various keys and values of the path configuration
        // but most likely you'll want to define your own enums these properties
        let presentation = properties["presentation"] as? String
        return presentation == "modal"
    }
    
    // MARK: - Sessions
    
    private lazy var session = makeSession()
    private lazy var modalSession = makeSession()
    
    private func makeSession() -> Session {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Turbo Native iOS"
        
        let session = Session(webViewConfiguration: configuration)
        session.delegate = self
        session.pathConfiguration = pathConfiguration
        return session
    }
    
    // MARK: - Path Configuration
    
    private lazy var pathConfiguration = PathConfiguration(sources: [
        .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
        .server(Demo.current.appendingPathComponent("path-configuration.json"))
    ])
}

extension SceneController: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = scene as? UIWindowScene else { return }
        
        configureRootViewController()
        route(url: Demo.current, options: VisitOptions(action: .replace), properties: [:])
    }
}

extension SceneController: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        route(url: proposal.url, options: proposal.options, properties: proposal.properties)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true)
    }
}
