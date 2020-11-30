import Foundation

/// Internal struct for simplifying decoding
/// since the public PathConfiguration can have multiple sources
/// that update async
struct PathConfigurationDecoder: Equatable {
    let settings: [String: AnyHashable]
    let rules: [PathRule]
    
    init(settings: [String: AnyHashable] = [:], rules: [PathRule] = []) {
        self.settings = settings
        self.rules = rules
    }
}

extension PathConfigurationDecoder {
    init(json: [String: Any]) throws {
        // rules must be present, settings are optional
        guard let rulesArray = json["rules"] as? [[String: AnyHashable]] else {
            throw JSONDecodingError.invalidJSON
        }
        
        let rules = try rulesArray.compactMap(PathRule.init)
        let settings = (json["settings"] as? [String: AnyHashable]) ?? [:]
        
        self.init(settings: settings, rules: rules)
    }
}
