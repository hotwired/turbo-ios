# Installation

Turbo iOS supports many methods for installation. In every case you can get the version number from the [Releases](https://github.com/hotwired/turbo-ios/releases) on GitHub.

## Carthage

Add the following to your `Cartfile`:

```
github "hotwired/turbo-ios" ~> <latest-version>
```

## CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'Turbo', :git => 'https://github.com/hotwired/turbo-ios.git', :tag => '<latest-version>'
```

Then run `pod install`.

## Swift Package Manager

Add Turbo as a dependency through Xcode or directly to a Package.swift:

```
.package(url: "https://github.com/hotwired/turbo-ios", from: "<latest-version>")
```

## Manual

You can always integrate the framework manually if your prefer, such as by adding the repo as a submodule, and linking `Turbo.framework` to your project.
