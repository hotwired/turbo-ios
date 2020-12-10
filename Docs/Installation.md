# Installation

We recommend Carthage as that's what we use for our apps and what we're most familiar with.

## Carthage

Add the following to your `Cartfile`:

```
github "basecamp/turbo-ios" ~> 7.0.0
```

## CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'Turbo', :git => 'https://github.com/basecamp/turbo-ios.git'
```

Then run `pod install`.

## Swift Package Manager

Add Turbo as a dependency through Xcode or directly to a Package.swift:

```
.package(url: "https://github.com/basecamp/turbo-ios", from: "7.0.0")
```

## Manual

You can always integrate the framework manually if your prefer, such as by adding the repo as a submodule, and linking `Turbo.framework` to your project.
