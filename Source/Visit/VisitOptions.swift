import Foundation

public struct VisitOptions: Codable, JSONCodable {
    public let action: Action
    public let response: VisitResponse?
    
    public static let defaultOptions = VisitOptions(action: .advance, response: nil)
    
    public init(action: Action = .advance, response: VisitResponse? = nil) {
        self.action = action
        self.response = response
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try container.decodeIfPresent(Action.self, forKey: .action) ?? .advance
        self.response = try container.decodeIfPresent(VisitResponse.self, forKey: .response)
    }
}

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
