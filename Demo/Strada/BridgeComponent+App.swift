import Foundation
import Strada

extension BridgeComponent {
    static var allTypes: [BridgeComponent.Type] {
        [
            FormComponent.self,
            MenuComponent.self,
            OverflowMenuComponent.self
        ]
    }
}
