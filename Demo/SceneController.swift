import UIKit
import WebKit
import SafariServices
import Turbo

final class SceneController: UIResponder {
    private static var sharedProcessPool = WKProcessPool()
    
    var window: UIWindow?
    private let rootURL = Demo.current
    private var navigationController: TurboNavigationController!
    
    // MARK: - Setup
    
    private func configureRootViewController() {
        guard let window = window else {
            fatalError()
        }
        
        window.tintColor = UIColor(named: "Tint")
        
        let turboNavController: TurboNavigationController
        if let navController = window.rootViewController as? TurboNavigationController {
            turboNavController = navController
            navigationController = navController
        } else {
            turboNavController = TurboNavigationController()
            window.rootViewController = turboNavController
        }
        
        turboNavController.session = session
        turboNavController.modalSession = modalSession
    }
    
    // MARK: - Authentication
    
    private func promptForAuthentication() {
        let authURL = rootURL.appendingPathComponent("/signin")
        let properties = pathConfiguration.properties(for: authURL)
        route(url: authURL, options: VisitOptions(), properties: properties)
    }
    
    // MARK: - Sessions
    
    private lazy var session = makeSession()
    private lazy var modalSession = makeSession()
    
    private func makeSession() -> Session {
        let configuration = WKWebViewConfiguration()
        configuration.applicationNameForUserAgent = "Turbo Native iOS"
        configuration.processPool = Self.sharedProcessPool
        
        let session = Session(webViewConfiguration: configuration)
        session.delegate = self
        session.pathConfiguration = pathConfiguration
        return session
    }
    
    // MARK: - Path Configuration
    
    private lazy var pathConfiguration = PathConfiguration(sources: [
        .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
        .server(rootURL.appendingPathComponent("path-configuration.json"))
    ])
}

extension SceneController: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = scene as? UIWindowScene else { return }
        
        configureRootViewController()
        route(url: rootURL, options: VisitOptions(action: .replace), properties: [:])
    }
}

extension SceneController: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        route(url: proposal.url, options: proposal.options, properties: proposal.properties)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
            promptForAuthentication()
        } else if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error) { [weak self] in
                self?.session.reload()
            }
        } else {
            let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            navigationController.present(alert, animated: true)
        }
    }
    
    func sessionDidLoadWebView(_ session: Session) {
        session.webView.navigationDelegate = self
    }
}

extension SceneController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            // Any link that's not on the same domain as the Turbo root url will go through here
            // Other links on the domain, but that have an extension that is non-html will also go here
            // You can decide how to handle those, by default if you're not the navigationDelegate
            // the Session will open them in the default browser
            
            let url = navigationAction.request.url!
            
            // For this demo, we'll load files from our domain in a SafariViewController so you
            // don't need to leave the app. You might expand this in your app
            // to open all audio/video/images in a native media viewer
            if url.host == rootURL.host, !url.pathExtension.isEmpty {
                let safariViewController = SFSafariViewController(url: url)
                navigationController.present(safariViewController, animated: true)
            } else {
                UIApplication.shared.open(url)
            }
            
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}
