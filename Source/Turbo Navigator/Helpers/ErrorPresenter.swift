import SwiftUI

public protocol ErrorPresenter: UIViewController {
    typealias Handler = () -> Void

    func presentError(_ error: Error, handler: Handler?)
}

public extension ErrorPresenter {
    func presentError(_ error: Error, handler: Handler?) {
        let errorView = ErrorView(error: error,
                                  shouldShowRetryButton: (handler != nil)) { [unowned self] in
            handler?()
            self.removeErrorViewController()
        }

        let controller = UIHostingController(rootView: errorView)
        addChild(controller)
        addFullScreenSubview(controller.view)
        controller.didMove(toParent: self)
    }

    private func removeErrorViewController() {
        if let child = children.first(where: { $0 is UIHostingController<ErrorView> }) {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
}

extension UIViewController: ErrorPresenter {}

// MARK: Private

private struct ErrorView: View {
    let error: Error
    let shouldShowRetryButton: Bool
    let handler: ErrorPresenter.Handler?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 38, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("Error loading page")
                .font(.largeTitle)

            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)

            if shouldShowRetryButton {
                Button("Retry") {
                    handler?()
                }
                .font(.system(size: 17, weight: .bold))
            }
        }
        .padding(32)
    }
}

private struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        return ErrorView(error: NSError(
            domain: "com.example.error",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: "Could not connect to the server."]
        ), shouldShowRetryButton: true) {}
    }
}

private extension UIViewController {
    func addFullScreenSubview(_ subview: UIView) {
        view.addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
