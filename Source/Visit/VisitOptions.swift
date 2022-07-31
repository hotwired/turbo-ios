import Foundation

public struct VisitOptions: Codable, JSONCodable {
    public let action: VisitAction
    public let response: VisitResponse?

    public init(action: VisitAction = .advance, response: VisitResponse? = nil) {
        self.action = action
        self.response = response
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.action = try container.decodeIfPresent(VisitAction.self, forKey: .action) ?? .advance
        self.response = try container.decodeIfPresent(VisitResponse.self, forKey: .response)
    }
}
