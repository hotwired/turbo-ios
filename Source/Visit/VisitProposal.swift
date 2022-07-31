import Foundation

public struct VisitProposal {
    public let url: URL
    public let options: VisitOptions
    public let properties: PathProperties

    public init(url: URL, options: VisitOptions, properties: PathProperties = [:]) {
        self.url = url
        self.options = options
        self.properties = properties
    }
}
