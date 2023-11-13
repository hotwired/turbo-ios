import SafariServices
import Strada
import Turbo
import UIKit
import WebKit

final class SceneController: UIResponder {
    var window: UIWindow?

    private let rootURL = Demo.current
    private lazy var navigator = TurboNavigator(pathConfiguration: pathConfiguration, delegate: self)

    // MARK: - Setup

    private func configureStrada() {
        Turbo.config.userAgent += " \(Strada.userAgentSubstring(for: BridgeComponent.allTypes))"

        Turbo.config.makeCustomWebView = { config in
            config.defaultWebpagePreferences?.preferredContentMode = .mobile

            let webView = WKWebView(frame: .zero, configuration: .appConfiguration)
            if #available(iOS 16.4, *) {
                webView.isInspectable = true
            }
            // Initialize Strada bridge.
            Bridge.initialize(webView)

            return webView
        }
    }

    private func configureRootViewController() {
        guard let window = window else {
            fatalError()
        }

        window.tintColor = .tint
        window.rootViewController = navigator.rootViewController
    }

    // MARK: - Authentication

    private func promptForAuthentication() {
        let authURL = rootURL.appendingPathComponent("/signin")
        navigator.route(authURL)
    }

    // MARK: - Path Configuration

    private lazy var pathConfiguration = PathConfiguration(sources: [
        .file(Bundle.main.url(forResource: "path-configuration", withExtension: "json")!),
    ])
}

extension SceneController: UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        window?.makeKeyAndVisible()

        configureStrada()
        configureRootViewController()

        navigator.route(rootURL)
    }
}

extension SceneController: TurboNavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        switch proposal.viewController {
        case "numbers":
            return .acceptCustom(NumbersViewController(url: proposal.url, navigator: navigator))
        case "numbersDetail":
            let alertController = UIAlertController(title: "Number", message: "\(proposal.url.lastPathComponent)", preferredStyle: .alert)
            alertController.addAction(.init(title: "OK", style: .default, handler: nil))
            return .acceptCustom(alertController)
        default:
            return .acceptCustom(TurboWebViewController(url: proposal.url))
        }
    }

    func visitableDidFailRequest(_ visitable: Visitable, error: Error, retry: @escaping RetryBlock) {
        if let turboError = error as? TurboError, case let .http(statusCode) = turboError, statusCode == 401 {
            promptForAuthentication()
        } else if let errorPresenter = visitable as? ErrorPresenter {
            errorPresenter.presentError(error, handler: retry)
        } else {
            let alert = UIAlertController(title: "Visit failed!", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            navigator.activeNavigationController.present(alert, animated: true)
        }
    }
}
