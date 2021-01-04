# Overview

There only a few main types in Turbo iOS. The primary ones being the `Session` and `Visitable`.

## Session

The `Session` class is the central coordinator in a Turbo Native for iOS application. Each `Session` manages a single `WKWebView` instance, and lets your app choose how to handle link taps, present view controllers, and deal with network errors. You can create a `Session` in a few different ways depending on your needs:

### Creating a Session

```swift
// 1. Create with no parameters - automatically creates a WKWebView with default configuration
let session = Session()

// 2. Create with a custom web view configuration, automatically creates a WKWebView with
// the passed-in configuration, you'll most likely want to do this to set your application's
// custom user-agent
let configuration = WKWebViewConfiguration()
configuration.applicationNameForUserAgent = "MyApplication"
let session = Session(configuration: configuration)

// 3. Finally, if you need full control, such as a WKWebView subclass, you can pass an initialized web view into the session
let webView = WKWebView()
let session = Session(webView: webView)
```

In most cases, you 'll want to use option #2. However you create your session, you need to set the `Session` delegate and implement the required protocol methods:

```swift
session.delegate = self

extension MyObject: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        // Handle a visit proposal
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        // Handle a visit error
    }   
}
```

Turbo iOS calls the `session(_:didProposeVisit:)` method before every [application visit](https://github.com/turbolinks/turbolinks/blob/master/README.md#application-visits), such as when you tap a Turbo-enabled link or call `Turbo.visit(...)` in your web application. Implement this method to choose how to handle the specified URL and action. This is called a *proposal* since your application is not required to complete the visit.

See [Responding to Visit Proposals](#responding-to-visit-proposals) for more details.

```swift
func session(session: Session, didFailRequestForVisitable visitable: Visitable, error: Error)
```

Turbo calls `session:didFailRequestForVisitable:withError:` when a visit’s network request fails. Use this method to respond to the error by displaying an appropriate message, or by requesting authentication credentials in the case of an authorization failure.

See [Handling Failed Requests](#handling-failed-requests) for more details.

## Visitable

A `Visitable` is a `UIViewController` that can be visited by the `Session`. Each `Visitable` view controller provides a `VisitableView` instance, which acts as a container for the `Session`’s shared `WKWebView`. The `VisitableView` optionally has a pull-to-refresh control and an activity indicator. It also automatically displays a screenshot of its contents when the web view moves to another `VisitableView`.

Visitable view controllers must conform to the Visitable protocol by implementing the following three properties:

```swift
protocol Visitable {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var visitableView: VisitableView! { get }
    var visitableURL: URL! { get }
}
```

Turbo iOS provides a `VisitableViewController` class that implements the `Visitable` protocol for you and provides everything you need out of the box. This view controller displays the `VisitableView` as its single subview.

Most applications will probably need want to subclass `VisitableViewController` to customize its layout or add additional views. For example, the bundled demo application has a [ViewController subclass](Demo/ViewController.swift) that can display a custom error view in place of the `VisitableView`.

If your application’s design prevents you from subclassing `VisitableViewController`, you can implement the `Visitable` protocol yourself. See the [VisitableViewController implementation](Source/VisitableViewController.swift) for details.

Note: custom `Visitable` view controllers must notify their delegate of their `viewWillAppear` and `viewDidAppear` methods through the `VisitableDelegate`'s `visitableViewWillAppear` and `visitableViewDidAppear` methods. The `Session` uses these hooks to know when it should move the WKWebView from one VisitableView to another.

# Building Your Turbo Native Application

## Initiating a Visit

To visit a URL with Turbo, first instantiate a `Visitable` view controller. Then present the view controller and pass it to the Session’s `visit` method.

For example, to create, display, and visit using the built-in `VisitableViewController` in a `UINavigationController`-based application, you might write:

```swift
let visitable = VisitableViewController(url: yourAppURL)
navigationController.pushViewController(visitable, animated: true)
session.visit(visitable)
```

## Responding to Visit Proposals

When you tap a Turbo-enabled link, the visit details make their way from the web view to the Session as a `VisitProposal`. Your Session’s delegate must implement the `session:didProposeVisit:` method to choose how to act on each proposal.

Normally you’ll respond to a visit proposal by creating a view controller with the URL from the visit proposal and simply initiating a visit. See [Initiating a Visit](#initiating-a-visit) for more details.

You can also choose to intercept the proposed visit and display a native view controller instead. This lets you transparently upgrade pages to native views on a per-URL basis. See the demo application for an example.

### Implementing Visit Actions

Each proposed visit has a `VisitOptions` including an `Action`, which tell you how you should present the `Visitable`.

The default `Action` is `.advance`. In most cases you’ll respond to an advance visit by pushing a Visitable view controller for the URL onto the navigation stack.

When you follow a link annotated with `data-turbo-action="replace"`, the proposed Action will be `.replace`. Usually you’ll want to handle a replace visit by replacing the top-most visible view controller with a new one instead of pushing.

## Handling Failed Requests

Turbo iOS calls the `session:didFailRequestForVisitable:error:` method when a visit request fails. This might be because of a network error, or because the server returned an HTTP 4xx or 5xx status code. If it was a network error in the main cold boot visit, it will be the `NSError` returned by WebKit. If it was a HTTP error or a network error from a JavaScript visit the error will be a `TurboError` and you can retrieve the status code.

```swift
func session(session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
    if let turboError = error as? TurboError {
        switch turboError {
        case .http(let statusCode):
            // Display or handle the HTTP error code
        case .networkFailure, .timeoutFailure:
            // Display appropriate error messages
        }
    } else {
        // Display the network failure or retry the visit
    }
}
```

HTTP error codes are a good way for the server to communicate specific requirements to your Turbo Native application. For example, you might use a `401 Unauthorized` response as a signal to prompt the user for authentication.

See the demo app’s [SceneDelegate](Demo/SceneDelegate.swift) for a detailed example of how to present error messages and perform authorization.

## Setting Visitable Titles

By default, Turbo iOS sets your Visitable view controller’s `title` property to the page’s `<title>`.

If you want to customize the title or pull it from another element on the page, you can implement the `visitableDidRender` method on your Visitable:

```swift
func visitableDidRender() {
    title = formatTitle(visitableView.webView?.title)
}

func formatTitle(title: String) -> String {
    // ...
}
```

## Changing How Turbo Opens External URLs

By default, Turbo iOS opens external URLs in the default browser. You can change this behavior by implementing the Session delegate’s optional `session:openExternalURL:` method.

For example, to open external URLs in an in-app [SFSafariViewController](https://developer.apple.com/library/ios/documentation/SafariServices/Reference/SFSafariViewController_Ref/index.html), you might write:

```swift
import SafariServices

// ...

func session(session: Session, openExternalURL URL: NSURL) {
    let safariViewController = SFSafariViewController(URL: URL)
    presentViewController(safariViewController, animated: true, completion: nil)
}
```

### Becoming the Web View’s Navigation Delegate

 When doing the cold boot visit, Turbo will need to take over as the WKWebView’s `navigationDelegate` to know when the page loads. After that, it's likely your application will want to become the `navigationDelegate` so you can have full control over the various methods.
 
 For example, when Turbo ignores a link, that link activation will go through the `func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void)` method. From that method you can decide how to route that URL, possibly through a native view controller or opening in the browser. See the demo for an example of this.

To assign the web view’s `navigationDelegate` property, implement the Session delegate’s optional `sessionDidLoadWebView(_:)` method. Turbo calls this method after every “cold boot,” such as on the initial page load and after pulling to refresh the page.

```swift
func sessionDidLoadWebView(_ session: Session) {
    session.webView.navigationDelegate = self
}

func webView(_ webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
    decisionHandler(WKNavigationActionPolicy.Cancel)
    // Handle non-Turbo links
}
```

Once you assign your own navigation delegate, Turbo will no longer invoke the Session delegate’s `session:openExternalURL:` method.

Note that your application _must_ call the navigation delegate’s `decisionHandler` with `WKNavigationActionPolicy.Cancel` for main-frame link activation navigation to prevent external URLs from loading in the Turbo-managed web view.

### Sharing Cookies with Other Web Views

If you’re using a separate web view for authentication purposes, or if your application has more than one Turbo Session, you can use a single [WKProcessPool](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKProcessPool_Ref/index.html) to share cookies across all web views.

Create and retain a reference to a process pool in your application. Then configure your Turbo Session and any other web views you create to use this process pool.

```swift
let processPool = WKProcessPool()
// ...
configuration.processPool = processPool
```
