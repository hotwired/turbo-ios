import Foundation

public struct VisitResponse: Codable {
    public let redirected: Bool
    public let statusCode: Int
    public let responseHTML: String?
    
    public init(statusCode: Int, responseHTML: String? = nil, redirected: Bool = false) {
        self.statusCode = statusCode
        self.responseHTML = responseHTML
        self.redirected = redirected
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
