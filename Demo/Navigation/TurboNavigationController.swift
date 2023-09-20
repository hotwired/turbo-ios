//
//  TurboNavigationController.swift
//  Demo
//
//  Created by Fernando Olivares on 08/11/21.
//

import Foundation
import UIKit
import Turbo
import Strada

class TurboNavigationController : UINavigationController {
    
    var session: Session!
    var modalSession: Session!
    
    func push(url: URL) {
        let properties = session.pathConfiguration?.properties(for: url) ?? [:]
        route(url: url,
              options: VisitOptions(action: .advance),
              properties: properties)
    }
    
    func route(url: URL, options: VisitOptions, properties: PathProperties) {
        // This is a simplified version of how you might build out the routing
        // and navigation functions of your app. In a real app, these would be separate objects
        
        // Dismiss any modals when receiving a new navigation
        if presentedViewController != nil {
            dismiss(animated: true)
        }
        
        // Special case of navigating home, issue a reload
        if url.path == "/", !viewControllers.isEmpty {
            popViewController(animated: false)
            session.reload()
            return
        }
        
        // - Create view controller appropriate for url/properties
        // - Navigate to that with the correct presentation
        // - Initiate the visit with Turbo
        let viewController = makeViewController(for: url, properties: properties)
        navigate(to: viewController, action: options.action, properties: properties)
        visit(viewController: viewController, with: options, modal: isModal(properties))
    }
}

extension TurboNavigationController {
    
    private func isModal(_ properties: PathProperties) -> Bool {
        // For simplicity, we're using string literals for various keys and values of the path configuration
        // but most likely you'll want to define your own enums these properties
        let presentation = properties["presentation"] as? String
        return presentation == "modal"
    }
    
    private func makeViewController(for url: URL, properties: PathProperties = [:]) -> UIViewController {
        // There are many options for determining how to map urls to view controllers
        // The demo uses the path configuration for determining which view controller and presentation
        // to use, but that's completely optional. You can use whatever logic you prefer to determine
        // how you navigate and route different URLs.
        
        if let viewController = properties["view-controller"] as? String {
            switch viewController {
            case "numbers":
                let numbersVC = NumbersViewController()
                numbersVC.url = url
                return numbersVC
            case "numbersDetail":
                let alertController = UIAlertController(title: "Number", message: "\(url.lastPathComponent)", preferredStyle: .alert)
                alertController.addAction(.init(title: "OK", style: .default, handler: nil))
                return alertController
            default:
                assertionFailure("Invalid view controller, defaulting to WebView")
            }
        }
            
        return TurboWebViewController(url: url)
    }
    
    private func navigate(to viewController: UIViewController, action: VisitAction, properties: PathProperties = [:], animated: Bool = true) {
        // We support three types of navigation in the app: advance, replace, and modal
        
        if isModal(properties) {
            if viewController is UIAlertController {
                present(viewController, animated: animated, completion: nil)
            } else {
                let modalNavController = UINavigationController(rootViewController: viewController)
                present(modalNavController, animated: animated)
            }
        } else if action == .replace {
            let viewControllers = Array(viewControllers.dropLast()) + [viewController]
            setViewControllers(viewControllers, animated: false)
        } else {
            pushViewController(viewController, animated: animated)
        }
    }
    
    private func visit(viewController: UIViewController, with options: VisitOptions, modal: Bool = false) {
        guard let visitable = viewController as? Visitable else { return }
        // Each Session corresponds to a single web view. A good rule of thumb
        // is to use a session per navigation stack. Here we're using a different session
        // when presenting a modal. We keep that around for any modal presentations so
        // we don't have to create more than we need since each new session incurs a cold boot visit cost
        if modal {
            modalSession.visit(visitable, options: options)
        } else {
            session.visit(visitable, options: options)
        }
    }
}
