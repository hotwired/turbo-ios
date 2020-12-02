import Foundation

/// Simple function to help in debugging, a noop in Release builds
func debugLog(_ item: Any, _ method: String = #function) {
    #if DEBUG
    let timestamp = Date()
    
    if let message = item as? String {
        print("\(timestamp) - \(message)")
    } else {
        // Support passing object directly instead of string to print class and function
        let component = String(describing: type(of: item))
        print("\(timestamp) - [\(component)] \(method)")
    }
    #endif
}

func debugPrint(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
