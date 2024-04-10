import Foundation
import UIKit

public struct VisitProposal {
    public let url: URL
    public let options: VisitOptions
    public let properties: PathProperties
    public let viewController: UIViewController?
    
    public init(url: URL,
                options: VisitOptions,
                properties: PathProperties = [:],
                viewController: UIViewController? = nil) {
        self.url = url
        self.options = options
        self.properties = properties
        self.viewController = viewController
    }
}
