import UIKit

protocol ErrorPresenter: UIViewController {
    typealias Handler = () -> Void

    func presentError(_ error: Error, handler: @escaping Handler)
}

extension ErrorPresenter {
    func presentError(_ error: Error, handler: @escaping Handler) {
        let errorViewController = ErrorViewController()
        errorViewController.configure(with: error) { [unowned self] in
            self.removeErrorViewController(errorViewController)
            handler()
        }
        
        let errorView = errorViewController.view!
        errorView.translatesAutoresizingMaskIntoConstraints = false
        
        addChild(errorViewController)
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: view.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        errorViewController.didMove(toParent: self)
    }
    
    private func removeErrorViewController(_ errorViewController: UIViewController) {
        errorViewController.willMove(toParent: nil)
        errorViewController.view.removeFromSuperview()
        errorViewController.removeFromParent()
    }
}

final class ErrorViewController: UIViewController {
    var handler: ErrorPresenter.Handler?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .systemBackground
        
        let vStack = UIStackView(arrangedSubviews: [imageView, titleLabel, bodyLabel, button])
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 16
        vStack.alignment = .center
        
        view.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            vStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 32),
            vStack.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -32),
        ])
    }
    
    func configure(with error: Error, handler: @escaping ErrorPresenter.Handler) {
        titleLabel.text = "Error loading page"
        bodyLabel.text = error.localizedDescription
        self.handler = handler
    }
    
    @objc func performAction(_ sender: UIButton) {
        handler?()
    }
    
    // MARK: - Views
    
    private let imageView: UIImageView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 38, weight: .semibold)
        let image = UIImage(systemName: "exclamationmark.triangle", withConfiguration: configuration)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle)
        label.textAlignment = .center

        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.textAlignment = .center
        label.numberOfLines = 0

        return label
    }()
    
    private let button: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.addTarget(self, action: #selector(performAction(_:)), for: .touchUpInside)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        
        return button
    }()
}
