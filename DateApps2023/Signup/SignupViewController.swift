import UIKit

final class SignupViewController: UIViewController {
    @IBOutlet private var usernameLabel: UILabel!
    @IBOutlet private var usernameTextField: UITextField!
    @IBOutlet private var emailLabel: UILabel!
    @IBOutlet private var emailTextField: UITextField!
    @IBOutlet private var passwordLabel: UILabel!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var confirmPasswordLabel: UILabel!
    @IBOutlet private var confirmPasswordTextField: UITextField!
    @IBOutlet private var signupButton: UIButton!
    private let viewModel = AuthenticationModule.makeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        signupButton.layer.cornerRadius = 20
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    @IBAction private func signUpButtonTapped(_: UIButton) {
        viewModel.signUp(name: usernameTextField.text ?? "", email: emailTextField.text ?? "", password: passwordTextField.text ?? "", confirmation: confirmPasswordTextField.text ?? "")
    }

    private func render(_ state: AuthenticationViewModel.State) {
        signupButton.isEnabled = state != .submitting
        switch state {
        case .idle, .submitting: break
        case .authenticated: AuthenticationModule.showHome(from: self)
        case let .failed(message): AuthenticationModule.showError(message, from: self)
        }
    }
}
