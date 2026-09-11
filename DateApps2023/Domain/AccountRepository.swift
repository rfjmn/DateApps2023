import Foundation

/// 認証サービスのユーザーIDと、保存するプロフィール名。
struct Account: Equatable {
    let id: String
    let name: String
}

/// 認証とプロフィール作成をデータ層へ委譲する境界。呼び出しと結果通知はMainActor上で行います。
@MainActor
protocol AccountRepository: AnyObject {
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
    func createAccount(name: String, email: String, password: String, completion: @escaping (Result<Account, Error>) -> Void)
    func saveProfile(for account: Account, completion: @escaping (Result<Void, Error>) -> Void)
}

/// 認証アカウントは作成済みで、プロフィールの保存だけを再試行できる失敗。
enum AccountRegistrationError: LocalizedError {
    case profilePending(Account, Error)

    var errorDescription: String? {
        "アカウントは作成済みです。通信状態を確認し、登録を完了してください。"
    }
}

enum AccountValidationError: LocalizedError, Equatable {
    case missingName, invalidEmail, invalidPassword, passwordsDoNotMatch

    var errorDescription: String? {
        switch self {
        case .missingName: return "名前を入力してください。"
        case .invalidEmail: return "メールアドレスを確認してください。"
        case .invalidPassword: return "パスワードは6文字以上で入力してください。"
        case .passwordsDoNotMatch: return "確認用パスワードが一致しません。"
        }
    }
}

/// 入力を検証・正規化してから、ログインまたは登録をRepositoryへ依頼するUseCase。
@MainActor
final class AuthenticateAccountUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    /// メールアドレス前後の空白を除去し、入力条件を満たす場合にログインを依頼します。
    ///
    /// パスワードは変更しません。入力不正の場合はRepositoryを呼ばずに失敗を通知します。
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try validate(email: email, password: password)
            repository.signIn(email: email, password: password, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    /// 名前・メールアドレス・パスワード・確認入力を検証し、名前とメールアドレスの前後の空白を除去して登録を依頼します。
    func signUp(name: String, email: String, password: String, confirmation: String,
                completion: @escaping (Result<Void, Error>) -> Void)
    {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            guard !name.isEmpty else { throw AccountValidationError.missingName }
            try validate(email: email, password: password)
            guard password == confirmation else { throw AccountValidationError.passwordsDoNotMatch }
            repository.createAccount(name: name, email: email, password: password) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case let .success(account): self.saveProfile(for: account, completion: completion)
                case let .failure(error): completion(.failure(error))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// 作成済みアカウントのプロフィールだけを保存します。認証アカウントは再作成しません。
    func saveProfile(for account: Account, completion: @escaping (Result<Void, Error>) -> Void) {
        repository.saveProfile(for: account) { result in
            completion(result.mapError { AccountRegistrationError.profilePending(account, $0) })
        }
    }

    private func validate(email: String, password: String) throws {
        // Basic input validation only; the authentication provider validates the address.
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, parts[1].contains("."),
              !parts[1].hasPrefix("."), !parts[1].hasSuffix("."),
              email.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
        else {
            throw AccountValidationError.invalidEmail
        }
        guard password.count >= 6 else { throw AccountValidationError.invalidPassword }
    }
}
