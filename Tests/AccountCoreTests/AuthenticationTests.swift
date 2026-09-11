@testable import AccountCore
import XCTest

final class AuthenticationTests: XCTestCase {
    @MainActor func testSignInNormalizesEmailWithoutChangingPassword() {
        let repository = RepositorySpy()
        let useCase = AuthenticateAccountUseCase(repository: repository)
        useCase.signIn(email: " person@example.technology \n", password: " secret ") { _ in }
        XCTAssertEqual(repository.email, "person@example.technology")
        XCTAssertEqual(repository.password, " secret ")
        XCTAssertEqual(repository.signInCount, 1)
    }

    @MainActor func testInvalidCredentialsDoNotReachRepository() {
        let repository = RepositorySpy()
        let useCase = AuthenticateAccountUseCase(repository: repository)
        for email in ["", "a", "a@", "@example.com", "a@@example.com", "a@ example.com"] {
            useCase.signIn(email: email, password: "secret") { result in
                guard case let .failure(error) = result else { return XCTFail("Expected validation failure") }
                XCTAssertEqual(error as? AccountValidationError, .invalidEmail)
            }
        }
        useCase.signIn(email: "a@example.com", password: "short") { result in
            guard case let .failure(error) = result else { return XCTFail("Expected validation failure") }
            XCTAssertEqual(error as? AccountValidationError, .invalidPassword)
        }
        XCTAssertEqual(repository.signInCount, 0)
    }

    @MainActor func testRegistrationValidatesNameAndConfirmation() {
        let repository = RepositorySpy()
        let useCase = AuthenticateAccountUseCase(repository: repository)
        useCase.signUp(name: " \n", email: "a@example.com", password: "secret", confirmation: "secret") { result in
            guard case let .failure(error) = result else { return XCTFail() }
            XCTAssertEqual(error as? AccountValidationError, .missingName)
        }
        useCase.signUp(name: "Rio", email: "a@example.com", password: "secret", confirmation: "other") { result in
            guard case let .failure(error) = result else { return XCTFail() }
            XCTAssertEqual(error as? AccountValidationError, .passwordsDoNotMatch)
        }
        XCTAssertEqual(repository.signUpCount, 0)
        useCase.signUp(name: " Rio ", email: "a@example.com", password: "secret", confirmation: "secret") { _ in }
        XCTAssertEqual(repository.name, "Rio")
        XCTAssertEqual(repository.signUpCount, 1)
    }

    @MainActor func testViewModelPreventsDuplicateRequestsAndPublishesSuccess() {
        let repository = RepositorySpy()
        let viewModel = AuthenticationViewModel(useCase: AuthenticateAccountUseCase(repository: repository))
        var states: [AuthenticationViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }
        viewModel.signIn(email: "a@example.com", password: "secret")
        viewModel.signIn(email: "a@example.com", password: "secret")
        XCTAssertEqual(repository.signInCount, 1)
        XCTAssertEqual(states, [.submitting])
        repository.completion?(.success(()))
        XCTAssertEqual(states, [.submitting, .authenticated])
    }

    @MainActor func testFailureAllowsRetry() {
        let repository = RepositorySpy()
        let viewModel = AuthenticationViewModel(useCase: AuthenticateAccountUseCase(repository: repository))
        viewModel.signIn(email: "a@example.com", password: "secret")
        repository.completion?(.failure(AccountValidationError.invalidPassword))
        XCTAssertEqual(viewModel.state, .failed(AccountValidationError.invalidPassword.localizedDescription))
        viewModel.signIn(email: "a@example.com", password: "secret")
        XCTAssertEqual(repository.signInCount, 2)
    }

    @MainActor func testPendingRequestDoesNotRetainViewModel() {
        let repository = RepositorySpy()
        var viewModel: AuthenticationViewModel? = AuthenticationViewModel(useCase: AuthenticateAccountUseCase(repository: repository))
        weak var weakViewModel = viewModel
        viewModel?.signIn(email: "a@example.com", password: "secret")
        viewModel = nil
        XCTAssertNil(weakViewModel)
        repository.completion?(.success(()))
    }
}

@MainActor
private final class RepositorySpy: AccountRepository {
    private(set) var signInCount = 0
    private(set) var signUpCount = 0
    private(set) var email: String?
    private(set) var password: String?
    private(set) var name: String?
    var completion: ((Result<Void, Error>) -> Void)?

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        signInCount += 1
        self.email = email
        self.password = password
        self.completion = completion
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        signUpCount += 1
        self.name = name
        self.email = email
        self.password = password
        self.completion = completion
    }
}
