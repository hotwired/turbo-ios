# Configuration

A few options can be configured on the library.

## Logging

Enable debug logging, including every interaction with the Turbo Session, Bridge, and visits.

```swift
#if DEBUG
TurboLog.debugLoggingEnabled = true
#endif
```

## Activity indicator animation delay

Delay the initial animation and display of the activity indicator (spinner) when loading requests, in seconds.

```swift
Turbo.activityIndicatorViewDelay = 0.5
```
