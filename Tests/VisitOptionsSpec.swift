import Nimble
import Quick
@testable import Turbo

class VisitOptionsSpec: QuickSpec {
    override func spec() {
        describe("Decodable") {
            it("defaults to advance action when not provided") {
                let json = "{}".data(using: .utf8)!

                do {
                    let decoder = JSONDecoder()
                    let options = try decoder.decode(VisitOptions.self, from: json)
                    expect(options.action) == .advance
                    expect(options.response).to(beNil())
                } catch {
                    fail(error.localizedDescription)
                }
            }

            it("uses provided action when not nil") {
                let json = """
                    {"action": "restore"}
                """.data(using: .utf8)!

                do {
                    let decoder = JSONDecoder()
                    let options = try decoder.decode(VisitOptions.self, from: json)
                    expect(options.action) == .restore
                    expect(options.response).to(beNil())
                } catch {
                    fail(error.localizedDescription)
                }
            }

            it("can be initialized with response") {
                let json = """
                    {"response": {"statusCode": 200, "responseHTML": "<html></html>"}}
                """.data(using: .utf8)!

                do {
                    let decoder = JSONDecoder()
                    let options = try decoder.decode(VisitOptions.self, from: json)
                    expect(options.action) == .advance
                    expect(options.response).toNot(beNil())
                    expect(options.response!.statusCode) == 200
                    expect(options.response!.responseHTML) == "<html></html>"

                } catch {
                    fail(error.localizedDescription)
                }
            }
        }
    }
}
