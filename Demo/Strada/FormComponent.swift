import Foundation
import Strada
import UIKit

/// Bridge component to display a submit button in the native toolbar,
/// which will submit the form on the page when tapped.
final class FormComponent: BridgeComponent {
    override class var name: String { "form" }
    
    override func onReceive(message: Message) {
        guard let event = Event(rawValue: message.event) else {
            return
        }
        
        switch event {
        case .connect:
            handleConnectEvent(message: message)
        case .submitEnabled:
            handleSubmitEnabled()
        case .submitDisabled:
            handleSubmitDisabled()
        }
    }
    
    @objc func performAction() {
        reply(to: Event.connect.rawValue)
    }
    
    // MARK: Private
    
    private weak var submitBarButtonItem: UIBarButtonItem?
    private var viewController: UIViewController? {
        delegate.destination as? UIViewController
    }
    
    private func handleConnectEvent(message: Message) {
        guard let data: MessageData = message.data() else { return }
        configureBarButton(with: data.submitTitle)
    }
    
    private func handleSubmitEnabled() {
        submitBarButtonItem?.isEnabled = true
    }
    
    private func handleSubmitDisabled() {
        submitBarButtonItem?.isEnabled = false
    }
    
    private func configureBarButton(with title: String) {
        guard let viewController else { return }
        
        let item = UIBarButtonItem(title: title,
                                   style: .plain,
                                   target: self,
                                   action: #selector(performAction))
        
        viewController.navigationItem.rightBarButtonItem = item
        submitBarButtonItem = item
    }
}

// MARK: Events

private extension FormComponent {
    enum Event: String {
        case connect
        case submitEnabled
        case submitDisabled
    }
}

// MARK: Message data

private extension FormComponent {
    struct MessageData: Decodable {
        let submitTitle: String
    }
}

