@testable import Turbo
import XCTest

class JavaScriptExpressionTests: XCTestCase {
    func test_string_convertsFunctionAndArgumentsIntoAValidExpression() {
        let expression = JavaScriptExpression(function: "console.log", arguments: [])
        XCTAssertEqual(expression.string, "console.log()")

        let expression2 = JavaScriptExpression(function: "console.log", arguments: ["one", nil, 2])
        XCTAssertEqual(expression2.string, "console.log(\"one\",null,2)")
    }

    func test_wrapped_wrapsExpressionIn_IIFE_AndTryCatch() {
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

        XCTAssertEqual(expression.wrappedString, expected)
    }
}
