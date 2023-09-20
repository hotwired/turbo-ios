import UIKit
import Turbo
import Strada
import WebKit

final class TurboWebViewController: VisitableViewController,
                                    ErrorPresenter,
                                    BridgeDestination {
    
    private lazy var bridgeDelegate: BridgeDelegate = {
        BridgeDelegate(location: visitableURL.absoluteString,
                       destination: self,
                       componentTypes: BridgeComponent.allTypes)
    }()
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backButtonDisplayMode = .minimal
        view.backgroundColor = .systemBackground
        
        if presentingViewController != nil {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        }
        bridgeDelegate.onViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bridgeDelegate.onViewWillAppear()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bridgeDelegate.onViewDidAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bridgeDelegate.onViewWillDisappear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bridgeDelegate.onViewDidDisappear()
    }
    
    // MARK: Visitable
    
    override func visitableDidActivateWebView(_ webView: WKWebView) {
        bridgeDelegate.webViewDidBecomeActive(webView)
    }
    
    override func visitableDidDeactivateWebView() {
        bridgeDelegate.webViewDidBecomeDeactivated()
    }
    
    // MARK: Actions
    
    @objc func dismissModal() {
        dismiss(animated: true)
    }
}
