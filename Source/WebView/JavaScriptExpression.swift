import Foundation

struct JavaScriptExpression {
    let function: String
    let arguments: [Any?]
    
    var string: String? {
        guard let encodedArguments = encode(arguments: arguments) else { return nil }
        return "\(function)(\(encodedArguments))"
    }
    
    var wrappedString: String? {
        guard let encodedArguments = encode(arguments: arguments) else { return nil }
        return wrap(function: function, encodedArguments: encodedArguments)
    }
    
    private func wrap(function: String, encodedArguments arguments: String) -> String {
        return """
        (function(result) {
          try {
            result.value = \(function)(\(arguments))
          } catch (error) {
            result.error = error.toString()
            result.stack = error.stack
          }
        
          return result
        })({})
        """
    }
    
    private func encode(arguments: [Any?]) -> String? {
        let arguments = arguments.map { $0 == nil ? NSNull() : $0! }
        
        guard let data = try? JSONSerialization.data(withJSONObject: arguments),
            let string = String(data: data, encoding: .utf8) else {
                return nil
        }
        
        // Strip leading/trailing [] so we have a list of arguments suitable for inserting between parens
        return String(string.dropFirst().dropLast())
    }
}
