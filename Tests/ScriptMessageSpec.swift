import Nimble
import Quick
@testable import Turbo
import WebKit
import XCTest

class ScriptMessageSpec: QuickSpec {
    override func spec() {
        describe(".parse") {
            context("with valid data") {
                it("returns message") {
                    let data: [String: Any] = ["identifier": "123", "restorationIdentifier": "abc", "options": ["action": "advance"], "location": "http://turbo.test"]
                    let script = FakeScriptMessage(body: ["name": "pageLoaded", "data": data])

                    guard let message = ScriptMessage(message: script) else {
                        fail("Error parsing script message")
                        return
                    }

                    expect(message.name) == .pageLoaded
                    expect(message.identifier) == "123"
                    expect(message.restorationIdentifier) == "abc"
                    expect(message.options!.action) == .advance
                    expect(message.location) == URL(string: "http://turbo.test")!
                }
            }

            context("with invalid body") {
                it("returns nil") {
                    let script = FakeScriptMessage(body: "foo")

                    let message = ScriptMessage(message: script)
                    expect(message).to(beNil())
                }
            }

            context("with invalid name") {
                it("returns nil") {
                    let script = FakeScriptMessage(body: ["name": "foobar"])

                    let message = ScriptMessage(message: script)
                    expect(message).to(beNil())
                }
            }

            context("with missing data") {
                it("returns nil") {
                    let script = FakeScriptMessage(body: ["name": "pageLoaded"])

                    let message = ScriptMessage(message: script)
                    expect(message).to(beNil())
                }
            }
        }
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
