import WebKit

struct ScriptMessage {
    let name: Name
    let data: [String: Any]

    var identifier: String? {
        data["identifier"] as? String
    }
    
    /// Milliseconds since unix epoch as provided by JavaScript Date.now()
    var timestamp: TimeInterval {
        data["timestamp"] as? TimeInterval ?? 0
    }
    
    var date: Date {
        Date(timeIntervalSince1970: timestamp / 1000.0)
    }

    var restorationIdentifier: String? {
        data["restorationIdentifier"] as? String
    }
   
    var location: URL? {
        guard let locationString = data["location"] as? String else { return nil }
        return URL(string: locationString)
    }

    var options: VisitOptions? {
        guard let options = data["options"] as? [String: Any] else { return nil }
        return VisitOptions(json: options)
    }
}

extension ScriptMessage {
    init?(message: WKScriptMessage) {
        guard let body = message.body as? [String: Any],
            let rawName = body["name"] as? String,
            let name = Name(rawValue: rawName),
            let data = body["data"] as? [String: Any]
        else {
            return nil
        }
        
        self.init(name: name, data: data)
    }
}

extension ScriptMessage {
    enum Name: String {
        case pageLoaded
        case errorRaised
        case visitProposed
        case visitStarted
        case visitRequestStarted
        case visitRequestCompleted
        case visitRequestFailed
        case visitRequestFinished
        case visitRendered
        case visitCompleted
        case pageInvalidated
        case log
    }
}
