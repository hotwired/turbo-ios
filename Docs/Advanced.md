# Advanced Topics

## Multiple Sessions

Each `Session` is 1:1 with a `WKWebView`. This means you can never have two pages active at the same time. You can create as many separate session as you need, though it's recommended to make as few as a possible. Every session you make will require a cold-boot visit which is likely to the be the slowest page load in your app. Each web view also uses additional resources.

One place you'll definitely want multiple sessions is for modals since non full-screen modals don't work out of the box with a single session. The demo shows a way to do this by lazily creating a reusable modal session whenever a modal is used. This is efficient, works well with any modal type, and makes the app feel better since we don't need to alter the main session at all to present/dismiss a modal.

A `UITabBarController` based app should work with a single session, but you may want to use multiple session there as well. A good rule of thumb is that you'll likely want a separate session for each navigation context you have (most likely a session per `UINavigationController`).

## Native <-> JavaScript Integration

You can send messages from your native app to the web view by using the `session.webView.evaluateJavaScript()` method. You can receive messages by adding a `WKScriptMessageHandler` to the web view and implementing the required protocols. That allows for two-way async communication. This is fine for simple tasks, but we've found we need something more comprehensive for our apps, which is why we created a new framework called Strada. This is a library in 3 parts (web, iOS, and Android) for integrating Turbo Native apps with their hosted web apps. This is separate and optional, but can dramatically improve the experience of your app. See the Strada repo for details (*coming soon*).

## Alert/Confirm/Prompt dialogs

By default `WKWebView`s don't present JavaScript `alert`, `confirm`, or `prompt` dialogs. You need to implement a [`WKUIDelegate`](https://developer.apple.com/documentation/webkit/wkuidelegate), then implement `runJavaScriptAlertPanelWithMessage`, `runJavaScriptConfirmPanelWithMessage`, and `runJavaScriptTextInputPanelWithPrompt`.

Turbo-ios implements these methods for you. The default implementations display a `UIAlertController` with the appropriate `UIAlertAction`s. If you prefer to provide your own implementation, override the delegate:

```swift
class ApplicationController: UINavigationController {

	// ...

    private func makeSession() -> Session {
        let session = Session(webViewConfiguration: configuration)
        session.delegate = self
        session.webView.uiDelegate = self // add this line, then implement the required methods
        return session
    }

    // ...
```
