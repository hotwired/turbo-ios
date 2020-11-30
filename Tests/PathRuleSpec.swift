import XCTest
import Quick
import Nimble
@testable import Turbo

class PathRuleSpec: QuickSpec {
    override func spec() {
        describe("subscript") {
            it("returns a String value for key") {
                let rule = PathRule(patterns: ["^/new$"], properties: ["color": "blue", "modal": false])
                
                expect(rule["color"]) == "blue"
                expect(rule["modal"]).to(beNil())
            }
        }
        
        describe(".match") {
            context("when path matches single pattern") {
                it("returns true") {
                    let rule = PathRule(patterns: ["^/new$"], properties: [:])
                    
                    expect(rule.match(path: "/new")) == true
                }
            }
            
            context("when path matches any pattern in array") {
                it("returns true") {
                    let rule = PathRule(patterns: ["^/new$", "^/edit"], properties: [:])
                    
                    expect(rule.match(path: "/edit/1")) == true
                }
            }
            
            context("when path doesn't match any patterns") {
                it("returns false") {
                    let rule = PathRule(patterns: ["^/new/bar"], properties: [:])
                    
                    expect(rule.match(path: "/new")) == false
                    expect(rule.match(path: "foo")) == false
                }
            }
        }
    }
}
