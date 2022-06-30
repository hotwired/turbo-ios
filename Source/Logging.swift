import Foundation

/// Simple function to help in debugging, a noop in Release builds
func debugLog(_ text: String, _ arguments: [String: Any] = [:]) {
    #if DEBUG
    let timestamp = Date()
    
    print("\(timestamp) \(text) \(arguments)")
    
    #endif
}

func debugPrint(_ message: String) {
    #if DEBUG
    print(message)
    #endif
}
