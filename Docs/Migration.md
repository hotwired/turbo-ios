# Migrating from Turbolinks.framework to Turbo.framework

If you were using the [Turbolinks iOS](https://github.com/turbolinks/turbolinks-ios) framework, we recommend migrating to Turbo. Though Turbo iOS is a new a framework, it is not a major change from the old Turbolinks iOS framework. Most of the code is the same, but has been improved, refactored, and better tested. It is compatible both with Turbolinks 5 and Turbo 7 JS on the server. There are some breaking API changes, but mostly in name.

Follow these steps, and you should be up and running in no time. I was able to update Basecamp 3 and HEY in about 15 minutes to give you an idea of the scope:

1. Update your dependency manager to point to `hotwired/turbo-ios` instead `turbolinks/turbolinks-ios`, see the [installation](Installation.md) doc for more info.
2. Change all your imports from `import Turbolinks` to `import Turbo`. This also would apply if you have any place you're using the full module for a type, like `Turbolinks.Session` would need to change to `Turbo.Session`
3. Try to build, at which point you should start to see a few errors for API changes.
4. `session(_ session: Session, didPropseVisitToURL url: URL, withAction action: Action)` is now `session(_ session: Session, didProposeVisit proposal: VisitProposal)`. The new `VisitProposal` type includes the url, action, and a new `VisitOptions` type
5. `func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError)` is now `func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error)`. What was previously an `NSError` is now an `Error`. To access the statusCode from a failure, you can check if the error is a new `TurboError` type like so: `let turboError = error as? TurboError, case .http(let statusCode) = turboError`
6. That should be the major code changes, please test your app first and open an issue if you run into blockers during migration. Note: the old Turbolinks.framework is now deprecated, but you can continue to use it as long as it works for you.


## Changes from turbolinks-ios
1. Requires iOS 12 and later. Most likely we will also drop support for iOS 12 in the near future. 
2. Fixed numerous scroll inset issues with the web view. Almost all of these culminated from underlying WebKit bug across versions iOS 10 and iOS 11. It seems they were all fixed in iOS 12, so that's why iOS 12 is now required. That means we could drop our hacks for getting the correct inset for the web view and rely on the iOS to do it automatically. The web view now sits full under the nav bar/tab bars and works as expected as far as scroll positioning and restoration


## Whats new in Turbo iOS?
1. Introduced a new `PathConfiguration` concept, documented here - [PathConfiguration](PathConfiguration.md)
2. Support for Turbo 7 apps as well as new `VisitOptions` provided by Turbo 7
3. Support for Swift Package Manager now that as of Swift 5.3 it supports resources
4. Bug fixes and additional tests
