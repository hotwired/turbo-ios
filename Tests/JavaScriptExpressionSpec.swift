import Nimble
import Quick
@testable import Turbo

class JavaScriptExpressionSpec: QuickSpec {
    override func spec() {
        describe(".string") {
            it("converts function and arguments into a valid expression") {
                let expression = JavaScriptExpression(function: "console.log", arguments: [])
                expect(expression.string) == "console.log()"

                let expression2 = JavaScriptExpression(function: "console.log", arguments: ["one", nil, 2])
                expect(expression2.string) == "console.log(\"one\",null,2)"
            }
        }

        describe(".wrapped") {
            it("wraps expression in IIFE and try/catch") {
                let expression = JavaScriptExpression(function: "console.log", arguments: [])
                let expected = """
                (function(result) {
                  try {
                    result.value = console.log()
                  } catch (error) {
                    result.error = error.toString()
                    result.stack = error.stack
                  }

                  return result
                })({})
                """

                expect(expression.wrappedString) == expected
            }
        }
    }
}
