import Foundation

enum JSONDecodingError: Error {
    case invalidJSON
}

protocol JSONCodable: Codable {
    init?(json: [String: Any])
    func toJSON() -> Any
}

// These methods are inefficient as they require extra conversion
// to/from Data and then reparsing, but in practice it should be so fast to not matter
extension JSONCodable {
    init?(json: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let decoder = JSONDecoder()
            self = try decoder.decode(Self.self, from: data)
        } catch {
            debugPrint("[json] *** Error decoding json: \(json) -> \(error)")
            return nil
        }
    }

    func toJSON() -> Any {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(self)
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            debugPrint("[json] *** Error encoding JSON: \(error)")
            return [:]
        }
    }
}
