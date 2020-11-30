import Foundation

/// Simple function to help in debugging, a noop in Release builds
func debugLog(_ item: Any, _ method: String = #function) {
    #if DEBUG
    // Unix epoch in milliseconds for easy comparison in to timestamps provided by JavaScript
    let milliseconds = Date().timeIntervalSince1970 * 1000
    let timestamp = String(format: "%04d", Int(milliseconds) % 10000)
    
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
