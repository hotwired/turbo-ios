import UIKit
import Turbo

final class ViewController: VisitableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        }
    }
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}
