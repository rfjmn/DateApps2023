import UIKit

final class LoginViewController: UIViewController {
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordLabel: UILabel!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var loginButton: UIButton!
    private let viewModel = AuthenticationModule.makeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.layer.cornerRadius = 20
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    @IBAction private func signInButtonTapped(_: UIButton) {
        viewModel.signIn(email: emailTextField.text ?? "", password: passwordTextField.text ?? "")
    }

    private func render(_ state: AuthenticationViewModel.State) {
        loginButton.isEnabled = state != .submitting
        switch state {
        case .idle, .submitting: break
        case .authenticated: AuthenticationModule.showHome(from: self)
        case let .failed(message), let .profilePending(message): AuthenticationModule.showError(message, from: self)
        }
    }
}
