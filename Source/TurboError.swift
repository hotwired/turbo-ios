import Foundation

public enum TurboError: LocalizedError, Equatable {
    case http(statusCode: Int)
    
    public var errorDescription: String? {
        switch self {
        case .http(let statusCode):
            return "HTTP Error: \(statusCode)."
        }
    }
}
