import Foundation

/// Simple function to help in debugging, a noop in Release builds
func debugLog(_ item: Any, _ method: String = #function) {
    #if DEBUG
    let timestamp = Date()
    
    if let message = item as? String {
        log("\(timestamp) - \(message)")
    } else {
        // Support passing object directly instead of string to print class and function
        let component = String(describing: type(of: item))
        log("\(timestamp) - [\(component)] \(method)")
    }
    #endif
}

func debugPrint(_ message: String) {
    #if DEBUG
    log(message)
    #endif
}

private func log(_ message: String) {
    if !ProcessInfo.processInfo.arguments.contains("disableTurboLog") {
        print(message)
    }
}
