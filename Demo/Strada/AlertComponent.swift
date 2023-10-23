import Strada
import UIKit

class AlertComponent: BridgeComponent {
    override class var name: String { "alert" }

    override func onReceive(message: Message) {
        guard let controller = delegate.destination as? UIViewController else { return }

        let alert = UIAlertController(title: "Hello, world!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default) { _ in })
        controller.present(alert, animated: true)
    }
}
