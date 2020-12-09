# Turbo Native for iOS

**Build high-fidelity hybrid apps with native navigation and a single shared web view.** Turbo Native for iOS provides the tooling to wrap your [Turbo 7](https://github.com/turbolinks/turbolinks)-enabled web app in a native iOS shell. It manages a single WKWebView instance across multiple view controllers, giving you native navigation UI with all the client-side performance benefits of Turbolinks.

## Features

- **Deliver fast, efficient hybrid apps.** Avoid reloading JavaScript and CSS. Save memory by sharing one WKWebView.
- **Reuse mobile web views across platforms.** Create your views once, on the server, in HTML. Deploy them to iOS, [Android](https://github.com/turbolinks/turbolinks-android), and mobile browsers simultaneously. Ship new features without waiting on App Store approval.
- **Enhance web views with native UI.** Navigate web views using native patterns. Augment web UI with native controls.
- **Produce large apps with small teams.** Achieve baseline HTML coverage for free. Upgrade to native views as needed.

## Requirements

Turbo for iOS is written in Swift 5.3 and requires Xcode 12. It currently supports iOS 12 or higher, but we'll most likely drop iOS 12 support soon. It supports both Turbo 7 and Turbolinks 5 sites. The Turbo iOS framework has no dependencies.

**Note:** You should understand how Turbo works with web applications in the browser before attempting to use Turbo for iOS. See the [Turbo 7 documentation](https://github.com/turbolinks/turbolinks) for details.

## Installation

Install Turbo manually by building `Turbo.framework` and linking it to your project. Optionally, install using a dependency manager:

### Carthage

Add the following to your `Cartfile`:

```
github "basecamp/turbo-ios" ~> 1.0.0
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'Turbo', :git => 'https://github.com/basecamp/turbo-ios.git'
```

Then run `pod install`.

### Swift Package Manager

*TODO*

## Getting Started

We recommend playing with the demo app first to get familiar with the framework. To run the demo, clone this repo and open `Demo/Demo.xcworkspace` in Xcode and run the Demo target. See [Demo/README.md](Demo/README.md) for more details about the demo. When you’re ready to start your own application, see our [Quick Start Guide](Docs/QuickStartGuide.md) for step-by-step instructions to lay the foundation and then read the rest of the documentation.

## Documentation

- [Quick Start](Docs/QuickStartGuide.md)
- [Overview](Docs/Overview.md)
- [Authentication](Docs/Authentication.md)
- [Path Configuration](Docs/PathConfiguration.md)
- [Migration](Docs/Migration.md)

## Contributing to Turbo for iOS

Turbo for iOS is open-source software, freely distributable under the terms of an [MIT-style license](LICENSE). The [source code is hosted on GitHub](https://github.com/basecamp/turbo-ios).
Development is sponsored by [Basecamp](https://basecamp.com/).

We welcome contributions in the form of bug reports, pull requests, or thoughtful discussions in the [GitHub issue tracker](https://github.com/basecamp/turbo-ios/issues).

Please note that this project is released with a [Contributor Code of Conduct](CONDUCT.md). By participating in this project you agree to abide by its terms.

---

© 2020 Basecamp, LLC

