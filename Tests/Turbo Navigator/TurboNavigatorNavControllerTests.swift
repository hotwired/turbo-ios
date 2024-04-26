import SafariServices
@testable import Turbo
import XCTest

/// Tests are written in the following format:
/// `test_currentContext_givenContext_givenPresentation_modifiers_result()`
/// See the README for a more visually pleasing table.
final class TurboNavigationHierarchyNavControllerTests: XCTestCase {
    
    override func setUp() {
        navigationController = TestableNavigationController()
        modalNavigationController = TestableNavigationController()

        navigator = TurboNavigator(session: session, modalSession: modalSession)
        navigator.delegate = mockDelegate
        hierarchyController = TurboNavigationHierarchyController(delegate: navigator, navigationController: navigationController, modalNavigationController: modalNavigationController)
        navigator.hierarchyController = hierarchyController

        loadNavigationControllerInWindow()
    }
    
    func test_default_modal_default_presentsNavigationControllerModal() {
        navigationController.pushViewController(UIViewController(), animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        
        let proposal = VisitProposal(path: "/navigation_controller", context: .modal)
        navigator.route(proposal)
        
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertEqual(modalNavigationController.viewControllers.count, 0)
        XCTAssertNotIdentical(navigationController.presentedViewController, modalNavigationController)
    }
    
    // MARK: Private

    private enum Context {
        case main, modal
    }

    private let baseURL = URL(string: "https://example.com")!
    private lazy var oneURL = baseURL.appendingPathComponent("/one")
    private lazy var twoURL = baseURL.appendingPathComponent("/two")

    private let session = Session(webView: Turbo.config.makeWebView())
    private let modalSession = Session(webView: Turbo.config.makeWebView())

    private var navigator: TurboNavigator!
    private var mockDelegate = MockNavigatorDelegate()
    private var hierarchyController: TurboNavigationHierarchyController!
    private var navigationController: TestableNavigationController!
    private var modalNavigationController: TestableNavigationController!

    private let window = UIWindow()

    // Simulate a "real" app so presenting view controllers works under test.
    private func loadNavigationControllerInWindow() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        navigationController.loadViewIfNeeded()
    }

    private func assertVisited(url: URL, on context: Context) {
        switch context {
        case .main:
            XCTAssertEqual(navigator.session.activeVisitable?.visitableURL, url)
        case .modal:
            XCTAssertEqual(navigator.modalSession.activeVisitable?.visitableURL, url)
        }
    }
}

// MARK: - DElegate
private class MockNavigatorDelegate: TurboNavigatorDelegate {
    func handle(proposal: VisitProposal) -> ProposalResult {
        if proposal.url.path == "/navigation_controller" {
            let navController = UINavigationController(rootViewController: UIViewController())
            return .acceptCustom(navController)
        }
        
        return .accept
    }
}
