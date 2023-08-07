import UIKit
import WebKit

open class VisitableViewController: UIViewController, Visitable {
    open weak var visitableDelegate: VisitableDelegate?
    open var visitableURL: URL!

    public convenience init(url: URL) {
        self.init()
        self.visitableURL = url
    }
    
    // MARK: View Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        installVisitableView()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        visitableDelegate?.visitableViewWillAppear(self)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        visitableDelegate?.visitableViewDidAppear(self)
    }

    // MARK: Visitable

    open func visitableDidRender() {
        title = visitableView.webView?.title
    }
    
    open func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }
    
    open func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
    }
    
    open func visitableDidActivateWebView(_ webView: WKWebView) {
        // No-op
    }
    
    open func visitableDidDeactivateWebView() {
        // No-op
    }
    
    // MARK: Visitable View

    open private(set) lazy var visitableView: VisitableView! = {
        let view = VisitableView(frame: CGRect.zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private func installVisitableView() {
        view.addSubview(visitableView)
        NSLayoutConstraint.activate([
            visitableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            visitableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            visitableView.topAnchor.constraint(equalTo: view.topAnchor),
            visitableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
