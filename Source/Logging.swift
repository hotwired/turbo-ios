import Foundation

/// Simple function to help in debugging.
/// Add the `turbo:log` argument in Xcode to enable.
func debugLog(_ text: String, _ arguments: [String: Any] = [:]) {
    let timestamp = Date()
    log("\(timestamp) \(text) \(arguments)")
}

func debugPrint(_ message: String) {
    log(message)
}

private func log(_ message: String) {
    if ProcessInfo.processInfo.arguments.contains("turbo:log") {
        print(message)
    }
}
