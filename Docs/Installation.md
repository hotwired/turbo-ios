# Installation

Turbo iOS supports the following methods for installation:

## Carthage

Add the following to your `Cartfile`:

```
github "hotwired/turbo-ios" ~> 7.0.0-beta.1
```

## CocoaPods

Add the following to your `Podfile`:

```ruby
use_frameworks!
pod 'Turbo', :git => 'https://github.com/hotwired/turbo-ios.git', :tag => '7.0.0-beta.1'
```

Then run `pod install`.

## Swift Package Manager

Add Turbo as a dependency through Xcode or directly to a Package.swift:

```
.package(url: "https://github.com/hotwired/turbo-ios", from: "7.0.0-beta.1")
```

## Manual

You can always integrate the framework manually if your prefer, such as by adding the repo as a submodule, and linking `Turbo.framework` to your project.
