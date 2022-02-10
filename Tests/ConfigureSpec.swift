import XCTest
import Quick
import Nimble
@testable import Turbo

class ConfigureSpec: QuickSpec {
    override func spec() {
        describe("configure") {
            context("logger") {
                var messageSink: String?
                let testMessage = "test message"

                beforeEach {
                    messageSink = nil
                    Turbo.configure { message in
                        messageSink = message()
                    }
                }
                
                it("uses provided logger function") {
                    debugPrint(testMessage)
                    expect(messageSink) == testMessage
                }
                
                it("stops using logger funtion when set to nil") {
                    Turbo.configure(logger: nil)
                    debugPrint(testMessage)
                    expect(messageSink).to(beNil())
                }
                
                it("only executes the autoclosure if necessary") {
                    var counter = 0
                    debugPrint("\(counter += 1)")
                    expect(counter) == 1    // incremented by 1

                    Turbo.configure { _ in
                        // do nothing
                    }
                    debugPrint("\(counter += 1)")
                    expect(counter) == 1    // didn't increment
                }
            }
        }
    }
}
