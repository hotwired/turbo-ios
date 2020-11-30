import Quick
import Nimble
@testable import Turbo

class PathConfigurationSpec: QuickSpec {
    override func spec() {
        let fileURL = Bundle(for: type(of: self)).url(forResource: "test-configuration", withExtension: "json")!
        var configuration: PathConfiguration!
        
        beforeEach {
            configuration = PathConfiguration(sources: [.file(fileURL)])
            expect(configuration.rules.count).toEventually(beGreaterThan(0))
        }
        
        describe("init") {
            it("automatically loads the configuration from the specified location") {
                expect(configuration.settings.count) == 2
                expect(configuration.rules.count) == 4
            }
        }
        
        describe("settings") {
            it("returns current settings") {
                expect(configuration.settings) == [
                    "some-feature-enabled": true,
                    "server": "beta"
                ]
            }
        }
        
        describe("properties(for: path)") {
            context("when path matches") {
                it("returns properties") {
                    expect(configuration.properties(for: "/")) == [
                        "page": "root"
                    ]
                }
            }
            
            context("when path matches multiple rules") {
                it("merges properties") {
                    expect(configuration.properties(for: "/new")) ==  [
                        "context": "modal",
                        "background_color": "black"
                    ]
                    
                    expect(configuration.properties(for: "/edit")) ==  [
                        "context": "modal",
                        "background_color": "white"
                    ]
                }
            }
            
            context("when no match") {
                it("returns empty properties") {
                    expect(configuration.properties(for: "/missing")) == [:]
                }
            }
        }
        
        describe("subscript") {
            it("is a convenience method for properties(for path)") {
                expect(configuration.properties(for: "/new")) == configuration["/new"]
                expect(configuration.properties(for: "/edit")) == configuration["/edit"]
                expect(configuration.properties(for: "/")) == configuration["/"]
                expect(configuration.properties(for: "/missing")) == configuration["/missing"]
            }
        }
    }
}

class PathConfigSpec: QuickSpec {
    override func spec() {
        describe("json") {
            context("with valid json") {
                it("decodes successfully") {
                    let fileURL = Bundle(for: type(of: self)).url(forResource: "test-configuration", withExtension: "json")!

                    do {
                        let data = try Data(contentsOf: fileURL)
                        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
                        let config = try PathConfigurationDecoder(json: json)
                       
                       expect(config.settings.count) == 2
                       expect(config.rules.count) == 4
                    } catch {
                        fail("Error decoding from JSON: \(error)")
                    }
                }
            }
            
            context("with missing rules key") {
                it("fails to decode") {
                    do {
                        _ = try PathConfigurationDecoder(json: [:])
                        fail("Path config should not have decoded invalid json")
                    } catch {
                        expect(error).to(matchError(JSONDecodingError.invalidJSON))
                    }
                }
            }
        }
    }
}

