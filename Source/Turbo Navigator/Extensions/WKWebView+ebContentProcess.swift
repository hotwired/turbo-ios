import Foundation
import WebKit

enum WebContentProcessState {
    case active
    case terminated
}

extension WKWebView {
    /// Queries the state of the web content process asynchronously.
    ///
    /// This method evaluates a simple JavaScript function in the web view to determine if the web content process is active.
    ///
    /// - Parameter completionHandler: A closure to be called when the query completes. The closure takes a single argument representing the state of the web content process.
    ///
    /// - Note: The web content process is considered active if the JavaScript evaluation succeeds without error. 
    /// If an error occurs during evaluation, the process is considered terminated.
    func queryWebContentProcessState(completionHandler: @escaping (WebContentProcessState) -> Void) {
        evaluateJavaScript("(function() { return '1'; })();") { _, error in
            if let _ = error {
                completionHandler(.terminated)
                return
            }
            
            completionHandler(.active)
        }
    }
}
