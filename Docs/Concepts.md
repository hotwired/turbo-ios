# Turbo Native Concepts

The `Session` class is the central coordinator in a Turbo Native for iOS application. Each `Session` manages a single `WKWebView` instance, and lets your app choose how to handle link taps, present view controllers, and deal with network errors.

A `Visitable` is a `UIViewController` that can be visited by the `Session`. Each `Visitable` view controller provides a `VisitableView` instance, which acts as a container for the `Session`’s shared `WKWebView`. The `VisitableView` optionally has a pull-to-refresh control and an activity indicator. It also automatically displays a screenshot of its contents when the web view moves to another `VisitableView`.

When you tap a Turbo-enabled link in the web view, the `Session` asks your application how to handle the link’s URL. Most of the time, your application will visit the URL by creating and presenting a `Visitable`. But it might also choose to present a native view controller for the URL, or to ignore the URL entirely.

## Creating a Session

To create a `Session`, first create a [WKWebViewConfiguration](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKWebViewConfiguration_Ref/index.html) and configure it as needed (see [Customizing the Web View Configuration](#customizing-the-web-view-configuration) for details). Then pass this configuration to the `Session` initializer and set the `delegate` property on the returned instance.

The `Session`’s delegate must implement the following method.

```swift
func session(session: Session, didProposeVisitToURL url: URL, options: VisitOptions, properties: PathProperties)
```

Turbo for iOS calls the `session:didProposeVisitToURL:options:properties:` method before every [application visit](https://github.com/turbolinks/turbolinks/blob/master/README.md#application-visits), such as when you tap a Turbo-enabled link or call `Turbolinks.visit(...)` in your web application. Implement this method to choose how to handle the specified URL and action.

See [Responding to Visit Proposals](#responding-to-visit-proposals) for more details.

```swift
func session(session: Session, didFailRequestForVisitable visitable: Visitable, error: Error)
```

Turbolinks calls `session:didFailRequestForVisitable:withError:` when a visit’s network request fails. Use this method to respond to the error by displaying an appropriate message, or by requesting authentication credentials in the case of an authorization failure.

See [Handling Failed Requests](#handling-failed-requests) for more details.

## Working with Visitables

Visitable view controllers must conform to the Visitable protocol by implementing the following three properties:

```swift
protocol Visitable {
    weak var visitableDelegate: VisitableDelegate? { get set }
    var visitableView: VisitableView! { get }
    var visitableURL: URL! { get }
}
```

Turbolinks for iOS provides a VisitableViewController class that implements the Visitable protocol for you. This view controller displays the VisitableView as its single subview.

Most applications will want to subclass VisitableViewController to customize its layout or add additional views. For example, the bundled demo application has a [DemoViewController subclass](TurbolinksDemo/DemoViewController.swift) that can display a custom error view in place of the VisitableView.

If your application’s design prevents you from subclassing VisitableViewController, you can implement the Visitable protocol yourself. See the [VisitableViewController implementation](Turbolinks/VisitableViewController.swift) for details.

Note that custom Visitable view controllers must forward their `viewWillAppear` and `viewDidAppear` methods to the Visitable delegate’s `visitableViewWillAppear` and `visitableViewDidAppear` methods. The Session uses these hooks to know when it should move the WKWebView from one VisitableView to another.


# Building Your Turbolinks Application

## Initiating a Visit

To visit a URL with Turbolinks, first instantiate a Visitable view controller. Then present the view controller and pass it to the Session’s `visit` method.

For example, to create, display, and visit Turbolinks’ built-in VisitableViewController in a UINavigationController-based application, you might write:

```swift
let visitable = VisitableViewController()
visitable.URL = NSURL(string: "http://localhost:9292/")!

navigationController.pushViewController(visitable, animated: true)
session.visit(visitable)
```

## Responding to Visit Proposals

When you tap a Turbolinks-enabled link, the link’s URL and action make their way from the web view to the Session as a proposed visit. Your Session’s delegate must implement the `session:didProposeVisitToURL:withAction:` method to choose how to act on each proposal.

Normally you’ll respond to a visit proposal by simply initiating a visit and loading the URL with Turbolinks. See [Initiating a Visit](#initiating-a-visit) for more details.

You can also choose to intercept the proposed visit and display a native view controller instead. This lets you transparently upgrade pages to native views on a per-URL basis. See the demo application for an example.

### Implementing Visit Actions

Each proposed visit has an Action, which tells you how you should present the Visitable.

The default Action is `.advance`. In most cases you’ll respond to an advance visit by pushing a Visitable view controller for the URL onto the navigation stack.

When you follow a link annotated with `data-turbolinks-action="replace"`, the proposed Action will be `.replace`. Usually you’ll want to handle a replace visit by popping the topmost view controller from the navigation stack and pushing a new Visitable for the proposed URL without animation.

## Handling Form Submission

By default, Turbolinks for iOS prevents standard HTML form submissions. This is because a form submission often results in redirection to a different URL, which means the Visitable view controller’s URL would change in place.

Instead, we recommend submitting forms with JavaScript using XMLHttpRequest, and using the response to tell Turbolinks where to navigate afterwards. See [Redirecting After a Form Submission](https://github.com/turbolinks/turbolinks#redirecting-after-a-form-submission) in the Turbolinks documentation for more details.

## Handling Failed Requests

Turbolinks for iOS calls the `session:didFailRequestForVisitable:withError:` method when a visit request fails. This might be because of a network error, or because the server returned an HTTP 4xx or 5xx status code.

The NSError object provides details about the error. Access its `code` property to see why the request failed.

An error code of `.HTTPFailure` indicates that the server returned an HTTP error. You can access the HTTP status code in the error object's `userInfo` dictionary under the key `"statusCode"`.

An error code of `.NetworkFailure` indicates a problem with the network connection: the connection may be offline, the server may be unavailable, or the request may have timed out without receiving a response.

```swift
func session(session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
    guard let errorCode = ErrorCode(rawValue: error.code) else { return }

    switch errorCode {
    case .HTTPFailure:
        let statusCode = error.userInfo["statusCode"] as! Int
        // Display or handle the HTTP error code
    case .NetworkFailure:
        // Display the network failure or retry the visit
    }
}
```

HTTP error codes are a good way for the server to communicate specific requirements to your Turbolinks application. For example, you might use a `401 Unauthorized` response as a signal to prompt the user for authentication.

See the demo app’s [ApplicationController](TurbolinksDemo/ApplicationController.swift) for a detailed example of how to present error messages and perform authorization.

## Setting Visitable Titles

By default, Turbo for iOS sets your Visitable view controller’s `title` property to the page’s `<title>`.

If you want to customize the title or pull it from another element on the page, you can implement the `visitableDidRender` method on your Visitable:

```swift
func visitableDidRender() {
    title = formatTitle(visitableView.webView?.title)
}

func formatTitle(title: String) -> String {
    // ...
}
```

## Starting and Stopping the Global Network Activity Indicator

Implement the optional `sessionDidStartRequest:` and `sessionDidFinishRequest:` methods in your application’s Session delegate to show the global network activity indicator in the status bar while Turbolinks issues network requests.

```swift
func sessionDidStartRequest(_ session: Session) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
}

func sessionDidFinishRequest(_ session: Session) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
}
```

Note that the network activity indicator is a shared resource, so your application will need to perform its own reference counting if other background operations update the indicator state.

## Changing How Turbolinks Opens External URLs

By default, Turbolinks for iOS opens external URLs in Safari. You can change this behavior by implementing the Session delegate’s optional `session:openExternalURL:` method.

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

Your application may require precise control over the web view’s navigation policy. If so, you can assign yourself as the WKWebView’s `navigationDelegate` and implement the [`webView:decidePolicyForNavigationAction:decisionHandler:`](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKNavigationDelegate_Ref/#//apple_ref/occ/intfm/WKNavigationDelegate/webView:decidePolicyForNavigationAction:decisionHandler:) method.

To assign the web view’s `navigationDelegate` property, implement the Session delegate’s optional `sessionDidLoadWebView:` method. Turbolinks calls this method after every “cold boot,” such as on the initial page load and after pulling to refresh the page.

```swift
func sessionDidLoadWebView(_ session: Session) {
    session.webView.navigationDelegate = self
}

func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> ()) {
    decisionHandler(WKNavigationActionPolicy.Cancel)
    // ...
}
```

Once you assign your own navigation delegate, Turbolinks will no longer invoke the Session delegate’s `session:openExternalURL:` method.

Note that your application _must_ call the navigation delegate’s `decisionHandler` with `WKNavigationActionPolicy.Cancel` for main-frame navigation to prevent external URLs from loading in the Turbolinks-managed web view.

## Customizing the Web View Configuration

Turbolinks allows your application to provide a [WKWebViewConfiguration](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKWebViewConfiguration_Ref/index.html) when you instantiate a Session. Use this configuration to set a custom user agent, share cookies with other web views, or install custom JavaScript message handlers.

```swift
let configuration = WKWebViewConfiguration()
let session = Session(webViewConfiguration: configuration)
```

Note that changing this configuration after creating the Session has no effect.

### Setting a Custom User Agent

Set the `applicationNameForUserAgent` property to include a custom string in the `User-Agent` header. You can check for this string on the server and use it to send specialized markup or assets to your application.

```swift
configuration.applicationNameForUserAgent = "MyApplication"
```

### Sharing Cookies with Other Web Views

If you’re using a separate web view for authentication purposes, or if your application has more than one Turbolinks Session, you can use a single [WKProcessPool](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKProcessPool_Ref/index.html) to share cookies across all web views.

Create and retain a reference to a process pool in your application. Then configure your Turbolinks Session and any other web views you create to use this process pool.

```swift
let processPool = WKProcessPool()
// ...
configuration.processPool = processPool
```

### Passing Messages from JavaScript to Your Application

You can register a [WKScriptMessageHandler](https://developer.apple.com/library/ios/documentation/WebKit/Reference/WKScriptMessageHandler_Ref/index.html) on the configuration’s user content controller to send messages from JavaScript to your iOS application.

```swift
class ScriptMessageHandler: WKScriptMessageHandler {
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // ...
    }
}

let scriptMessageHandler = ScriptMessageHandler()
configuration.userContentController.addScriptMessageHandler(scriptMessageHandler, name: "myApplication")
```

```js
document.addEventListener("click", function() {
    webkit.messageHandlers.myApplication.postMessage("Hello!")
})
```
