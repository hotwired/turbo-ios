import UIKit

protocol ErrorPresenter: UIViewController {
    func presentError(_ error: Error)
}

extension ErrorPresenter {
    func presentError(_ error: Error) {
        let errorViewController = ErrorViewController()
        errorViewController.configure(with: error)
        
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
}

final class ErrorViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .systemBackground
        
        let vStack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        vStack.translatesAutoresizingMaskIntoConstraints = false
        vStack.axis = .vertical
        vStack.spacing = 16
        
        view.addSubview(vStack)
        NSLayoutConstraint.activate([
            vStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            vStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    func configure(with error: Error) {
        titleLabel.text = "Error loading page"
        bodyLabel.text = error.localizedDescription
    }
    
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

        return label
    }()
}
