import Foundation
import Turbo

/// A bridge "back" to Turbo world from native.
/// See `NumbersViewController` for an example of navigating from native to web.
protocol Navigator: AnyObject {
    func route(_ url: URL)
}

extension TurboNavigator: Navigator {
    func route(_ url: URL) {
        route(url, options: VisitOptions(action: .advance), parameters: nil)
    }
}
