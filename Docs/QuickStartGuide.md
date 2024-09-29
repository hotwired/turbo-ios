# Quick Start Guide

This is a quick start guide to creating the most minimal Turbo iOS application from scratch get up and running in a few minutes. This will support basic back/forward navigation, but will not be a fully functional application.

1. First, create a new iOS app from the Xcode File > New > Project menu and choose the default iOS "App" template. Note: When using XCode >= 12, be sure to choose "Storyboard" under "Interface" and "UIKit App Delegate" under "Lifecycle" in the project creation dialog. 

2. Select your app's main top-level project in the Navigator panel, and select the project in the Project and Targets list, and go to the Dependencies tab and add the Turbo iOS dependency by entering in `https://github.com/hotwired/turbo-ios`.

3. In the Project and Targets List, select the main Target, and in the General tab, scroll down to Frameworks, Libraries, and Embedded Content. Add the Turbo Library within the Turbo Package.

4. Open the `SceneDelegate`, and replace the entire file with this code:
```swift
import UIKit
import Turbo

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private lazy var navigationController = UINavigationController()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
        window!.rootViewController = navigationController
        visit(url: URL(string: "https://turbo-native-demo.glitch.me")!)
    }
    
    private func visit(url: URL) {
        let viewController = VisitableViewController(url: url)
        navigationController.pushViewController(viewController, animated: true)
        session.visit(viewController)
    }
    
    private lazy var session: Session = {
        let session = Session()
        session.delegate = self
        return session
    }()
}

extension SceneDelegate: SessionDelegate {
    func session(_ session: Session, didProposeVisit proposal: VisitProposal) {
        visit(url: proposal.url)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, error: Error) {
        print("didFailRequestForVisitable: \(error)")
    }
    
    func sessionWebViewProcessDidTerminate(_ session: Session) {
        session.reload()
    }
}
```

5. Hit run, and you have a basic working app. You can now tap links and navigate the demo back and forth in the simulator. We've only touched the very core requirements here of creating a `Session` and handling a visit.

6. You can change the url we use for the initial visit to your web app. Note: if you're running your app locally without https, you'll need to adjust your `NSAppTransportSecurity` settings in the Info.plist to allow arbitrary loads.

7. A real application will want to customize the view controller, respond to different visit actions, gracefully handle errors, and build a more powerful routing system. Read the rest of the documentation to learn more.
