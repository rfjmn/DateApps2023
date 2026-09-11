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
        if case .profilePending = viewModel.state {
            viewModel.retryProfile()
            return
        }
        viewModel.signUp(name: usernameTextField.text ?? "", email: emailTextField.text ?? "", password: passwordTextField.text ?? "", confirmation: confirmPasswordTextField.text ?? "")
    }

    private func render(_ state: AuthenticationViewModel.State) {
        let isProfilePending: Bool
        if case .profilePending = state { isProfilePending = true } else { isProfilePending = false }
        signupButton.isEnabled = state != .submitting
        signupButton.setTitle(isProfilePending ? "登録を完了する" : "登録", for: .normal)
        [usernameTextField, emailTextField, passwordTextField, confirmPasswordTextField].forEach {
            $0?.isEnabled = state != .submitting && !isProfilePending
        }
        switch state {
        case .idle, .submitting: break
        case .authenticated: AuthenticationModule.showHome(from: self)
        case let .failed(message), let .profilePending(message): AuthenticationModule.showError(message, from: self)
        }
    }
}
