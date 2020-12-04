# Quick Start Guide

This guide will walk you through creating a minimal Turbo for iOS application.

We’ll use the demo app’s server in our examples, but you can adjust the URL below to point to your own application. See [Demo docs](../Docs/README.md) for more details

Note that for the sake of brevity, these examples use a `UINavigationController` and implement everything inside the AppDelegate. In a real application, you may not want to use a navigation controller, and you should consider factoring these responsibilities out of the AppDelegate and into separate classes.

## 1. Create a UINavigationController-based project

Create a new Xcode project using the Single View Application template. Then, open `AppDelegate.swift` and replace it with the following to create a UINavigationController and make it the window’s root view controller:

```swift
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var navigationController = UINavigationController()

    func applicationDidFinishLaunching(_ application: UIApplication) {
        window?.rootViewController = navigationController
    }
}
```

▶️ Build and run the app in the simulator to make sure it works. It won’t do anything interesting, but it should run without error.

## 2. Configure your project for Turbolinks

**Add Turbolinks to your project.** Install the Turbolinks framework using Carthage, CocoaPods, or manually by building `Turbolinks.framework` and linking it to your Xcode project. See [Installation](../README.md#installation) for more instructions.

**Configure NSAppTransportSecurity for the demo server.** By default, iOS versions 9 and later restrict access to unencrypted HTTP connections. In order for your application to connect to the demo server, you must configure it to allow insecure HTTP requests to `localhost`.

Run the following command with the path to your application’s `Info.plist` file:

```
plutil -insert NSAppTransportSecurity -json \
  '{"NSExceptionDomains":{"localhost":{"NSExceptionAllowsInsecureHTTPLoads":true}}}' \
  MyApp/Info.plist
```

See [Apple’s property list documentation](https://developer.apple.com/library/prerelease/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/CocoaKeys.html#//apple_ref/doc/uid/TP40009251-SW33) for more information about NSAppTransportSecurity.

## 3. Set up a Turbolinks Session and perform an initial visit

A Turbolinks Session manages a WKWebView instance and moves it between Visitable view controllers when you navigate. Your application is responsible for displaying a Visitable view controller, giving it a URL, and telling the Session to visit it. See [Understanding Turbolinks Concepts](../README.md#understanding-turbolinks-concepts) for details.

In your AppDelegate, create and retain a Session. Then, create a VisitableViewController with the demo server’s URL, and push it onto the navigation stack. Finally, call `session.visit()` with your view controller to perform the visit.

```swift
import UIKit
import Turbolinks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var navigationController = UINavigationController()
    var session = Session()

    func applicationDidFinishLaunching(_ application: UIApplication) {
        window?.rootViewController = navigationController
        startApplication()
    }

    func startApplication() {
        visit(URL: URL(string: "http://localhost:9292")!)
    }

    func visit(URL: URL) {
        let visitableViewController = VisitableViewController(url: URL)
        navigationController.pushViewController(visitableViewController, animated: true)
        session.visit(visitableViewController)
    }
}
```

▶️ Ensure the Turbolinks demo server is running and launch the application in the simulator. The demo page should load, but tapping a link will have no effect.

To handle link taps and initiate a Turbolinks visit, you must configure the Session’s delegate.

## 4. Configure the Session’s delegate

The Session notifies its delegate by proposing a visit whenever you tap a link. It also notifies its delegate when a visit request fails. The Session’s delegate is responsible for handling these events and deciding how to proceed. See [Creating a Session](../README.md#creating-a-session) for details.

First, assign the Session’s `delegate` property. For demonstration purposes, we’ll make AppDelegate the Session’s delegate.

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
    // ...

    func startApplication() {
        session.delegate = self
        visit(URL: URL(string: "http://localhost:9292")!)
    }
}
```

Next, implement the SessionDelegate protocol to handle proposed and failed visits by adding the following class extension just after the last closing brace in the file:

```swift
extension AppDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisitToURL URL: URL, withAction action: Action) {
        visit(URL: URL)
    }

    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        navigationController.present(alert, animated: true, completion: nil)
    }
}
```

We handle a proposed visit in the same way as the initial visit: by creating a VisitableViewController, pushing it onto the navigation stack, and visiting it with the Session. When a visit request fails, we display an alert.

▶️ Build the app and run it in the simulator. Congratulations! Tapping a link should now work.

## 5. Read the documentation

A real application will want to customize the view controller, respond to different visit actions, and gracefully handle errors. See [Building Your Turbolinks Application](../README.md#building-your-turbolinks-application) for detailed instructions.
