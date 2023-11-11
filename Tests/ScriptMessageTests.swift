@testable import Turbo
import WebKit
import XCTest

class ScriptMessageTests: XCTestCase {
    func test_parse_withValidData_returnsMessage() throws {
        let data = ["identifier": "123", "restorationIdentifier": "abc", "options": ["action": "advance"], "location": "http://turbo.test"] as [String: Any]
        let script = FakeScriptMessage(body: ["name": "pageLoaded", "data": data] as [String: Any])

        let message = try XCTUnwrap(ScriptMessage(message: script))
        XCTAssertEqual(message.name, .pageLoaded)
        XCTAssertEqual(message.identifier, "123")
        XCTAssertEqual(message.restorationIdentifier, "abc")
        let options = try XCTUnwrap(message.options)
        XCTAssertEqual(options.action, .advance)
        XCTAssertEqual(message.location, URL(string: "http://turbo.test")!)
    }

    func test_parse_withInvalidBody_returnsNil() {
        let script = FakeScriptMessage(body: "foo")

        let message = ScriptMessage(message: script)
        XCTAssertNil(message)
    }

    func test_parse_withInvalidName_returnsNil() {
        let script = FakeScriptMessage(body: ["name": "foobar"])

        let message = ScriptMessage(message: script)
        XCTAssertNil(message)
    }

    func test_parse_withMissingData_returnsNil() {
        let script = FakeScriptMessage(body: ["name": "pageLoaded"])

        let message = ScriptMessage(message: script)
        XCTAssertNil(message)
    }
}

// Can't instantiate a WKScriptMessage directly
private class FakeScriptMessage: WKScriptMessage {
    override var body: Any {
        return actualBody
    }

    var actualBody: Any

    init(body: Any) {
        self.actualBody = body
    }
}
