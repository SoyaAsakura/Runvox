@testable import Runvox
import XCTest

@MainActor
final class AuthServiceTests: XCTestCase {
    /// テストでは autoRestore: false で deterministic に
    private func makeService() async -> AuthService {
        let service = AuthService(
            backend: MockAuthBackend(simulatedLatency: .milliseconds(0)),
            autoRestore: false
        )
        await service.restoreSession()
        return service
    }

    // MARK: - Initial state

    func test_initialState_isLoadingBeforeRestore() {
        let service = AuthService(
            backend: MockAuthBackend(simulatedLatency: .milliseconds(0)),
            autoRestore: false
        )
        XCTAssertEqual(service.state, .loading)
    }

    func test_afterRestoreSession_becomesSignedOut() async {
        let service = await makeService()
        XCTAssertEqual(service.state, .signedOut)
    }

    // MARK: - Sign in

    func test_signInWithEmail_successfullySignsIn() async throws {
        let service = await makeService()

        try await service.signInWithEmail(
            email: "user@example.com",
            password: "Password123"
        )

        XCTAssertTrue(service.isSignedIn)
        XCTAssertEqual(service.currentUser?.email, "user@example.com")
    }

    func test_signInWithEmail_invalidEmailThrows() async throws {
        let service = await makeService()

        do {
            try await service.signInWithEmail(email: "invalid", password: "Password123")
            XCTFail("Should throw invalidEmail")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        }
        XCTAssertFalse(service.isSignedIn)
    }

    func test_signInWithEmail_userNotFoundThrows() async throws {
        let service = await makeService()

        do {
            try await service.signInWithEmail(
                email: "notfound@example.com",
                password: "Password123"
            )
            XCTFail("Should throw userNotFound")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userNotFound)
        }
    }

    func test_signInWithEmail_wrongPasswordThrows() async throws {
        let service = await makeService()

        do {
            try await service.signInWithEmail(
                email: "wrong@example.com",
                password: "Password123"
            )
            XCTFail("Should throw wrongPassword")
        } catch let error as AuthError {
            XCTAssertEqual(error, .wrongPassword)
        }
    }

    // MARK: - Sign up

    func test_signUpWithEmail_successfullyCreatesUser() async throws {
        let service = await makeService()

        try await service.signUpWithEmail(
            email: "new@example.com",
            password: "Password123",
            nickname: "ランナー太郎"
        )

        XCTAssertTrue(service.isSignedIn)
        XCTAssertEqual(service.currentUser?.nickname, "ランナー太郎")
    }

    func test_signUpWithEmail_takenEmailThrows() async throws {
        let service = await makeService()

        do {
            try await service.signUpWithEmail(
                email: "taken@example.com",
                password: "Password123",
                nickname: "ランナー"
            )
            XCTFail("Should throw emailAlreadyInUse")
        } catch let error as AuthError {
            XCTAssertEqual(error, .emailAlreadyInUse)
        }
    }

    func test_signUpWithEmail_weakPasswordThrowsBeforeBackend() async throws {
        let service = await makeService()

        do {
            try await service.signUpWithEmail(
                email: "new@example.com",
                password: "short",
                nickname: "ランナー"
            )
            XCTFail("Should throw weakPassword")
        } catch let error as AuthError {
            if case .weakPassword = error {
                // expected
            } else {
                XCTFail("expected weakPassword, got \(error)")
            }
        }
    }

    // MARK: - Apple

    func test_signInWithApple_setsSignedIn() async throws {
        let service = await makeService()

        try await service.signInWithApple()

        XCTAssertTrue(service.isSignedIn)
    }

    // MARK: - Sign out

    func test_signOut_resetsToSignedOut() async throws {
        let service = await makeService()

        try await service.signInWithEmail(
            email: "user@example.com",
            password: "Password123"
        )
        XCTAssertTrue(service.isSignedIn)

        try await service.signOut()
        XCTAssertEqual(service.state, .signedOut)
    }
}
