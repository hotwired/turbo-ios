import Foundation

public struct PathRule: Equatable {
    /// Array of regular expressions to match against
    public let patterns: [String]
    
    /// The properties to apply for matches
    public let properties: PathProperties
    
    /// Convenience method to retrieve a String value for a key
    /// Access `properties` directly to get a different type
    public subscript(key: String) -> String? {
        properties[key] as? String
    }
    
    init(patterns: [String], properties: PathProperties) {
        self.patterns = patterns
        self.properties = properties
    }
    
    /// Returns true if any pattern in this rule matches `path`
    public func match(path: String) -> Bool {
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            if regex.numberOfMatches(in: path, range: range) > 0 {
                return true
            }
        }
        
        return false
    }
}

extension PathRule {
    init(json: [String: Any]) throws {
        guard let patterns = json["patterns"] as? [String],
            let properties = json["properties"] as? [String: AnyHashable]
        else {
            throw JSONDecodingError.invalidJSON
        }
        
        self.init(patterns: patterns, properties: properties)
    }
}
