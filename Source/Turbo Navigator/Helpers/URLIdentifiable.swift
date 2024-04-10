import Foundation
import UIKit

public protocol URLIdentifiable: UIViewController {
    static var urlIdentifier: URL { get }
}
