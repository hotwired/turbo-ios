@testable import Turbo
import XCTest

class VisitOptionsTests: XCTestCase {
    func test_Decodable_defaultsToAdvanceActionWhenNotProvided() throws {
        let json = "{}".data(using: .utf8)!

        let options = try JSONDecoder().decode(VisitOptions.self, from: json)
        XCTAssertEqual(options.action, .advance)
        XCTAssertNil(options.response)
    }

    func test_Decodable_usesProvidedActionWhenNotNil() throws {
        let json = """
        {"action": "restore"}
        """.data(using: .utf8)!

        let options = try JSONDecoder().decode(VisitOptions.self, from: json)
        XCTAssertEqual(options.action, .restore)
        XCTAssertNil(options.response)
    }

    func test_Decodable_canBeInitializedWithResponse() throws {
        let json = """
        {"response": {"statusCode": 200, "responseHTML": "<html></html>"}}
        """.data(using: .utf8)!

        let options = try JSONDecoder().decode(VisitOptions.self, from: json)
        XCTAssertEqual(options.action, .advance)

        let response = try XCTUnwrap(options.response)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.responseHTML, "<html></html>")
    }
}
