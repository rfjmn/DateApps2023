import Foundation

struct Account: Equatable {
    let id: String
    let name: String
}

@MainActor
protocol AccountRepository {
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
    func signUp(name: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void)
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

@MainActor
final class AuthenticateAccountUseCase {
    private let repository: AccountRepository

    init(repository: AccountRepository) {
        self.repository = repository
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try validate(email: email, password: password)
            repository.signIn(email: email, password: password, completion: completion)
        } catch {
            completion(.failure(error))
        }
    }

    func signUp(name: String, email: String, password: String, confirmation: String,
                completion: @escaping (Result<Void, Error>) -> Void)
    {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            guard !name.isEmpty else { throw AccountValidationError.missingName }
            try validate(email: email, password: password)
            guard password == confirmation else { throw AccountValidationError.passwordsDoNotMatch }
            repository.signUp(name: name, email: email, password: password, completion: completion)
        } catch {
            completion(.failure(error))
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
