import SafariServices
@testable import Turbo
import XCTest

final class TurboNavigationDelegateTests: TurboNavigator {
//    func test_controllerForProposal_defaultsToVisitableViewController() throws {
//        let url = URL(string: "https://example.com")!
//
//        let result = delegate.handle(proposal: VisitProposal(url: url))
//
//        XCTAssertEqual(result, .accept)
//    }
//
//    func test_openExternalURL_presentsSafariViewController() throws {
//        let url = URL(string: "https://example.com")!
//        let controller = TestableNavigationController()
//
//        delegate.openExternalURL(url, from: controller)
//
//        XCTAssert(controller.presentedViewController is SFSafariViewController)
//        XCTAssertEqual(controller.modalPresentationStyle, .pageSheet)
//    }

    // MARK: Private

//    private let delegate = DefaultDelegate()
}

// MARK: - DefaultDelegate

private class DefaultDelegate {
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {}
}

// MARK: - VisitProposal extension

private extension VisitProposal {
    init(url: URL) {
        let url = url
        let options = VisitOptions(action: .advance, response: nil)
        self.init(url: url, options: options)
    }
}
