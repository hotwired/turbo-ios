import UIKit

open class VisitableViewController: UIViewController, Visitable {
    open weak var visitableDelegate: VisitableDelegate?
    open var visitableURL: URL!

    public convenience init(url: URL) {
        self.init()
        self.visitableURL = url
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

    // MARK: Visitable

    open func visitableDidRender() {
        self.title = visitableView.webView?.title
    }
    
    open func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }
    
    open func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
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

    /*
     If the visitableView is a child of the main view, and anchored to its top and bottom, then it's
     unlikely you will need to customize the layout. But more complicated view hierarchies and layout 
     may require explicit control over the contentInset. Below is an example of setting the contentInset 
     to the layout guides.
     
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        visitableView.contentInset = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0)
    }
    */
}
