import Foundation

public struct VisitResponse: Codable {
    public let statusCode: Int
    public let responseHTML: String?
    
    public init(statusCode: Int, responseHTML: String? = nil) {
        self.statusCode = statusCode
        self.responseHTML = responseHTML
    }
    
    public var isSuccessful: Bool {
        switch statusCode {
        case 200...299:
            return true
        default:
            return false
        }
    }
}
