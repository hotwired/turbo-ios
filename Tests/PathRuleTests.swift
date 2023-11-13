@testable import Turbo
import XCTest

class PathRuleTests: XCTestCase {
    func test_subscript_returnsAStringValueForKey() {
        let rule = PathRule(patterns: ["^/new$"], properties: ["color": "blue", "modal": false])

        XCTAssertEqual(rule["color"], "blue")
        XCTAssertNil(rule["modal"])
    }

    func test_match_whenPathMatchesSinglePattern_returnsTrue() {
        let rule = PathRule(patterns: ["^/new$"], properties: [:])

        XCTAssertTrue(rule.match(path: "/new"))
    }

    func test_match_whenPathMatchesAnyPatternInArray_returnsTrue() {
        let rule = PathRule(patterns: ["^/new$", "^/edit"], properties: [:])

        XCTAssertTrue(rule.match(path: "/edit/1"))
    }

    func test_match_whenPathDoesntMatchAnyPatterns_returnsFalse() {
        let rule = PathRule(patterns: ["^/new/bar"], properties: [:])

        XCTAssertFalse(rule.match(path: "/new"))
        XCTAssertFalse(rule.match(path: "foo"))
    }
}
