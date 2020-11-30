import Foundation

public let ErrorDomain = "com.basecamp.Turbo"

public enum ErrorCode: Int {
    case httpFailure
    case networkFailure
}

extension NSError {
    convenience init(code: ErrorCode, localizedDescription: String) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: localizedDescription])
    }
    
    convenience init(httpStatusCode statusCode: Int) {
        if statusCode == 0 {
            self.init(code: .networkFailure, localizedDescription: "A network error occurred.")
        } else {
            self.init(code: .httpFailure, statusCode: statusCode)
        }
    }
   
    convenience init(code: ErrorCode, statusCode: Int) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["statusCode": statusCode, NSLocalizedDescriptionKey: "HTTP Error: \(statusCode)"])
    }

    convenience init(code: ErrorCode, error: NSError) {
        self.init(domain: ErrorDomain, code: code.rawValue, userInfo: ["error": error, NSLocalizedDescriptionKey: error.localizedDescription])
    }
}
