import UIKit

@MainActor
enum AuthenticationModule {
    static func makeViewModel() -> AuthenticationViewModel {
        AuthenticationViewModel(useCase: AuthenticateAccountUseCase(repository: FirebaseAccountRepository()))
    }

    static func showHome(from viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Home", bundle: nil)
        let homeViewController = storyboard.instantiateViewController(withIdentifier: "home")
        viewController.navigationController?.pushViewController(homeViewController, animated: true)
    }

    static func showError(_ message: String, from viewController: UIViewController) {
        let alert = UIAlertController(title: "認証できませんでした", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        viewController.present(alert, animated: true)
    }
}
