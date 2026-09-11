import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Firebase AuthenticationとFirestoreへ接続するRepository。
///
/// 登録は認証アカウントの作成、プロフィールの保存の順に行います。
/// プロフィール保存に失敗しても、作成済みの認証アカウントは削除しません。
@MainActor
final class FirebaseAccountRepository: AccountRepository {
    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            let outcome: Result<Void, Error>
            if let error = error {
                outcome = .failure(error)
            } else if result != nil {
                outcome = .success(())
            } else {
                outcome = .failure(RepositoryError.missingAccount)
            }
            Task { @MainActor in completion(outcome) }
        }
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                Task { @MainActor in completion(.failure(error)) }
                return
            }
            guard let result = result else {
                Task { @MainActor in completion(.failure(RepositoryError.missingAccount)) }
                return
            }
            let account = Account(id: result.user.uid, name: name)
            let timestamp = Timestamp(date: Date())
            Firestore.firestore().collection("users").document(account.id).setData([
                "name": account.name, "created_at": timestamp, "updated_at": timestamp,
            ]) { error in
                Task { @MainActor in
                    if let error = error {
                        completion(.failure(RepositoryError.profileCreationFailed(error)))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }

    private enum RepositoryError: LocalizedError {
        case missingAccount
        case profileCreationFailed(Error)

        var errorDescription: String? {
            switch self {
            case .missingAccount: return "アカウント情報を取得できませんでした。"
            case .profileCreationFailed:
                return "アカウントは作成されましたが、プロフィールの保存に失敗しました。管理者にお問い合わせください。"
            }
        }
    }
}
