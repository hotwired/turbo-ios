import SafariServices
@testable import Turbo
import XCTest

final class TurboNavigationDelegateTests: TurboNavigator {
    func test_controllerForProposal_defaultsToVisitableViewController() throws {
        let url = URL(string: "https://example.com")!

        let proposal = VisitProposal(url: url, options: VisitOptions())
        let result = delegate.handle(proposal: proposal)

        XCTAssertEqual(result, .accept)
    }
}
