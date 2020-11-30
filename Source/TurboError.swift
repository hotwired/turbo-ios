import Foundation

public enum TurboError: LocalizedError, Equatable {
    case http(statusCode: Int)
    case network
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .http(let statusCode):
            return "HTTP Error: \(statusCode)."
        case .network:
            return "A network error occurred."
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
