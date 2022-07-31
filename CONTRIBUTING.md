# Contributing to turbo-ios

To set up your development environment:

1. Clone the repo
2. Install the test dependencies
3. Run the tests via Xcode

```bash
$ bin/carthage.sh bootstrap --cache-builds --use-xcframeworks --platform ios
```

Open `Turbo.xcodeproj` and run the tests via Product → Test or <kbd>⌘</kbd>+<kbd>U</kbd>
