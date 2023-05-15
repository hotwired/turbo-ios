import UIKit
import WebKit

public protocol VisitableDelegate: AnyObject {
    func visitableViewWillAppear(_ visitable: Visitable)
    func visitableViewDidAppear(_ visitable: Visitable)
    func visitableDidRequestReload(_ visitable: Visitable)
    func visitableDidRequestRefresh(_ visitable: Visitable)
}

public protocol Visitable: AnyObject, VisitableViewDelegate {
    var visitableViewController: UIViewController { get }
    var visitableDelegate: VisitableDelegate? { get set } 
    var visitableView: VisitableView! { get }
    var visitableURL: URL! { get }
    
    func visitableDidRender()
    func showVisitableActivityIndicator()
    func hideVisitableActivityIndicator()
}

// MARK: VisitableViewDelegate
extension Visitable {
    public func didPullToRefresh(control: UIRefreshControl) {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }
}

extension Visitable {
    public func reloadVisitable() {
        visitableDelegate?.visitableDidRequestReload(self)
    }
    
    public func showVisitableActivityIndicator() {
        visitableView.showActivityIndicator()
    }

    public func hideVisitableActivityIndicator() {
        visitableView.hideActivityIndicator()
    }

    func activateVisitableWebView(_ webView: WKWebView) {
        visitableView.activateWebView(webView, delegate: self)
    }

    func deactivateVisitableWebView() {
        visitableView.deactivateWebView()
    }

    func updateVisitableScreenshot() {
        visitableView.updateScreenshot()
    }

    func showVisitableScreenshot() {
        visitableView.showScreenshot()
    }

    func hideVisitableScreenshot() {
        visitableView.hideScreenshot()
    }

    func clearVisitableScreenshot() {
        visitableView.clearScreenshot()
    }

    func visitableWillRefresh() {
        visitableView.refreshControl.beginRefreshing()
    }

    func visitableDidRefresh() {
        visitableView.refreshControl.endRefreshing()
    }

    func visitableViewDidRequestRefresh() {
        visitableDelegate?.visitableDidRequestRefresh(self)
    }
}

extension Visitable where Self: UIViewController {
    public var visitableViewController: UIViewController {
        self
    }
}
