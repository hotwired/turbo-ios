import Foundation

// https://github.com/hotwired/turbo/blob/main/src/core/drive/visit.ts#L56-L60
public enum TurboError: LocalizedError, Equatable {
    case networkFailure
    case timeoutFailure
    case contentTypeMismatch
    case pageLoadFailure
    case http(statusCode: Int)

    init(statusCode: Int) {
        switch statusCode {
        case 0:
            self = .networkFailure
        case -1:
            self = .timeoutFailure
        case -2:
            self = .contentTypeMismatch
        default:
            self = .http(statusCode: statusCode)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .networkFailure:
            return "A network error occurred."
        case .timeoutFailure:
            return "A network timeout occurred."
        case .contentTypeMismatch:
            return "The server returned an invalid content type."
        case .pageLoadFailure:
            return "The page could not be loaded due to a configuration error."
        case .http(let statusCode):
            return "There was an HTTP error (\(statusCode))."
        }
    }
}
