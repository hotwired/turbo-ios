import UIKit
import Turbo

final class ViewController: VisitableViewController, ErrorPresenter {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .minimal
        }
        
        view.backgroundColor = visitableView.webView?.themeColor ?? .systemBackground
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        }
    }
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}
