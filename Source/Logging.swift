import Foundation

public typealias LoggingFunction = (String) -> Void

struct Logging {
    static var logger: LoggingFunction?
    
    static func log(_ message: @autoclosure () -> String) {
        if let logger = logger {
            logger(message())
        } else {
            #if DEBUG
            print("\(Date()) - \(message())")
            #endif
        }
    }
}

/// Simple function to help in debugging, a noop in Release builds
func debugLog(_ item: Any, _ method: String = #function) {
    let formatMessage: () -> String = {
        var message: String
        
        if let itemString = item as? String {
            message = itemString
        } else {
            // Support passing object directly instead of string to print class and function
            let component = String(describing: type(of: item))
            message = "[\(component)] \(method)"
        }
        
        return message
    }
    
    Logging.log(formatMessage())
}

func debugPrint(_ message: @autoclosure () -> String) {
    Logging.log(message())
}
