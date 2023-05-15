import UIKit
import WebKit

public protocol VisitableViewDelegate : AnyObject {
    func didPullToRefresh(control: UIRefreshControl)
}

/// `VisitableView`'s purpose is to manage implementation details regarding visibility for:
/// - a webView running Turbo
/// - a screenshot container view
/// - an activity indicator view
open class VisitableView: UIView {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        installActivityIndicatorView()
    }

    // MARK: Web View

    open weak var webView: WKWebView?
    
    private weak var delegate: VisitableViewDelegate?

    open func activateWebView(_ webView: WKWebView, delegate: VisitableViewDelegate) {
        self.webView = webView
        self.delegate = delegate
        addSubview(webView)
        addFillConstraints(for: webView)
        installRefreshControl()
        showOrHideWebView()
    }

    open func deactivateWebView() {
        removeRefreshControl()
        webView?.removeFromSuperview()
        webView = nil
    }

    private func showOrHideWebView() {
        webView?.isHidden = isShowingScreenshot
    }

    // MARK: Refresh Control

    open lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        return refreshControl
    }()

    open var allowsPullToRefresh: Bool = true {
        didSet {
            if allowsPullToRefresh {
                installRefreshControl()
            } else {
                removeRefreshControl()
            }
        }
    }

    open var isRefreshing: Bool {
        refreshControl.isRefreshing
    }

    private func installRefreshControl() {
        guard let scrollView = webView?.scrollView, allowsPullToRefresh else { return }
        
        #if !targetEnvironment(macCatalyst)
        scrollView.addSubview(refreshControl)
        #endif
    }

    private func removeRefreshControl() {
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
    }

    @objc func refresh(_ sender: AnyObject) {
        delegate?.didPullToRefresh(control: refreshControl)
    }

    // MARK: Activity Indicator

    open lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = UIColor.gray
        view.hidesWhenStopped = true
        return view
    }()

    private func installActivityIndicatorView() {
        addSubview(activityIndicatorView)
        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    open func showActivityIndicator() {
        guard !isRefreshing else { return }

        activityIndicatorView.startAnimating()
        bringSubviewToFront(activityIndicatorView)
    }

    open func hideActivityIndicator() {
        activityIndicatorView.stopAnimating()
    }

    // MARK: Screenshots

    private lazy var screenshotContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = self.backgroundColor
        return view
    }()

    private var screenshotView: UIView?

    var isShowingScreenshot: Bool {
        screenshotContainerView.superview != nil
    }

    open func updateScreenshot() {
        guard !isShowingScreenshot, let webView = self.webView, let screenshot = webView.snapshotView(afterScreenUpdates: false) else { return }

        screenshotView?.removeFromSuperview()
        screenshot.translatesAutoresizingMaskIntoConstraints = false
        screenshotContainerView.addSubview(screenshot)

        NSLayoutConstraint.activate([
            screenshot.centerXAnchor.constraint(equalTo: screenshotContainerView.centerXAnchor),
            screenshot.topAnchor.constraint(equalTo: screenshotContainerView.topAnchor),
            screenshot.widthAnchor.constraint(equalToConstant: screenshot.bounds.size.width),
            screenshot.heightAnchor.constraint(equalToConstant: screenshot.bounds.size.height)
        ])

        screenshotView = screenshot        
    }

    open func showScreenshot() {
        guard !isShowingScreenshot, !isRefreshing else { return }

        addSubview(screenshotContainerView)
        addFillConstraints(for: screenshotContainerView)
        showOrHideWebView()
    }

    open func hideScreenshot() {
        screenshotContainerView.removeFromSuperview()
        showOrHideWebView()
    }

    open func clearScreenshot() {
        screenshotView?.removeFromSuperview()
    }

    // MARK: - Constraints
    
    private func addFillConstraints(for view: UIView) {
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor),
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
