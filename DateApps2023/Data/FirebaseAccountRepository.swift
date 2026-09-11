import FirebaseAuth
import FirebaseFirestore
import Foundation

/// Firebase AuthenticationとFirestoreの境界。認証アカウント作成とプロフィール保存を独立して再利用できます。
@MainActor
final class FirebaseAccountRepository: AccountRepository {
    private let auth: Auth
    private let database: Firestore

    init(auth: Auth = .auth(), database: Firestore = .firestore()) {
        self.auth = auth
        self.database = database
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error { completion(.failure(error)) }
                else if result != nil { completion(.success(())) }
                else { completion(.failure(RepositoryError.missingAccount)) }
            }
        }
    }

    func createAccount(name: String, email: String, password: String, completion: @escaping (Result<Account, Error>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            Task { @MainActor in
                if let error = error { completion(.failure(error)) }
                else if let result = result { completion(.success(Account(id: result.user.uid, name: name))) }
                else { completion(.failure(RepositoryError.missingAccount)) }
            }
        }
    }

    /// ログイン中の本人のドキュメントだけを保存します。同じIDへの再試行では文書を増やしません。
    func saveProfile(for account: Account, completion: @escaping (Result<Void, Error>) -> Void) {
        guard auth.currentUser?.uid == account.id else {
            completion(.failure(RepositoryError.accountChanged))
            return
        }
        let document = database.collection("users").document(account.id)
        database.runTransaction({ transaction, errorPointer in
            do {
                let existing = try transaction.getDocument(document)
                var fields: [String: Any] = ["name": account.name, "updated_at": FieldValue.serverTimestamp()]
                if !existing.exists { fields["created_at"] = FieldValue.serverTimestamp() }
                transaction.setData(fields, forDocument: document, merge: true)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }) { _, error in
            Task { @MainActor in
                if let error = error { completion(.failure(error)) }
                else { completion(.success(())) }
            }
        }
    }

    private enum RepositoryError: LocalizedError {
        case missingAccount, accountChanged
        var errorDescription: String? {
            switch self {
            case .missingAccount: return "アカウント情報を取得できませんでした。"
            case .accountChanged: return "ログイン状態が変わりました。ログインし直してください。"
            }
        }
    }
}
