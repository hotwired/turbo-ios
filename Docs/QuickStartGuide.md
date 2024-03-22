# Quick Start Guide

This is a quick start guide to creating the most minimal Turbo iOS application from scratch get up and running in a few minutes. This will support basic back/forward navigation, but will not be a fully functional application.

1. First, create a new iOS app from the Xcode File > New > Project menu and choose the default iOS "App" template. Note: When using XCode >= 12, be sure to choose "Storyboard" under "Interface" and "UIKit App Delegate" under "Lifecycle" in the project creation dialog. 

2. Select your app's main top-level project, go to the Swift Packages tab and add the Turbo iOS dependency by entering in `https://github.com/hotwired/turbo-ios`.

3. Open the `SceneDelegate`, and replace the entire file with this code:

```swift
import Turbo
import UIKit

private let rootURL = URL(string: "https://turbo-native-demo.glitch.me")!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    private lazy var navigator = TurboNavigator()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }

        window!.rootViewController = navigator.rootViewController
        navigator.route(rootURL)
    }
}
```

4. Hit run, and you have a basic working app. You can now tap links and navigate the demo back and forth in the simulator. We've only touched the very core requirements here of creating a `Turbo Navigator` and handling a visit.

5. You can change the url we use for the initial visit to your web app.

6. A real application will want to customize the view controller, respond to different visit actions, and build a more powerful routing system. Read the rest of the documentation to learn more.
