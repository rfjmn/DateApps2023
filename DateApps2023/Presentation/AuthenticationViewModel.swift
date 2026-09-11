import Foundation

/// 認証フォームの送信状態と結果を管理するViewModel。送信中の重複操作は無視します。
@MainActor
final class AuthenticationViewModel {
    enum State: Equatable {
        case idle, submitting, authenticated, failed(String)
    }

    private(set) var state: State = .idle {
        didSet { onStateChange?(state) }
    }

    /// 状態の変更後に呼ばれる通知先。画面を参照するクロージャでは弱参照を使用します。
    var onStateChange: ((State) -> Void)?
    private let useCase: AuthenticateAccountUseCase

    init(useCase: AuthenticateAccountUseCase) {
        self.useCase = useCase
    }

    func signIn(email: String, password: String) {
        guard state != .submitting else { return }
        state = .submitting
        useCase.signIn(email: email, password: password) { [weak self] result in
            self?.handle(result)
        }
    }

    func signUp(name: String, email: String, password: String, confirmation: String) {
        guard state != .submitting else { return }
        state = .submitting
        useCase.signUp(name: name, email: email, password: password, confirmation: confirmation) { [weak self] result in
            self?.handle(result)
        }
    }

    private func handle(_ result: Result<Void, Error>) {
        switch result {
        case .success: state = .authenticated
        case let .failure(error): state = .failed(error.localizedDescription)
        }
    }
}
