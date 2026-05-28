import Foundation

/// Firebase 統合前の検証用モック実装
///
/// - 起動時は未ログイン状態として復元する
/// - メール / Apple Sign In ともに 0.4 秒の遅延でユーザーを返す
/// - 一部のメールアドレスでエラーパスをテスト可能（下記参照）
///
/// テスト用エラー誘発メール:
/// - `taken@example.com` → emailAlreadyInUse
/// - `notfound@example.com` → userNotFound
/// - `wrong@example.com` → wrongPassword
/// - `network@example.com` → networkError
final class MockAuthBackend: AuthBackend {
    private let simulatedLatency: Duration

    init(simulatedLatency: Duration = .milliseconds(400)) {
        self.simulatedLatency = simulatedLatency
    }

    func restoreSession() async -> User? {
        try? await Task.sleep(for: .milliseconds(200))
        return nil
    }

    func signInWithEmail(email: String, password: String) async throws -> User {
        try await Task.sleep(for: simulatedLatency)
        switch email.lowercased() {
        case "notfound@example.com":
            throw AuthError.userNotFound
        case "wrong@example.com":
            throw AuthError.wrongPassword
        case "network@example.com":
            throw AuthError.networkError
        default:
            return Self.makeUser(email: email, nickname: Self.nicknameFromEmail(email))
        }
    }

    func signUpWithEmail(email: String, password: String, nickname: String) async throws -> User {
        try await Task.sleep(for: simulatedLatency)
        switch email.lowercased() {
        case "taken@example.com":
            throw AuthError.emailAlreadyInUse
        case "network@example.com":
            throw AuthError.networkError
        default:
            if nickname.lowercased() == "taken" {
                throw AuthError.nicknameAlreadyTaken
            }
            return Self.makeUser(email: email, nickname: nickname)
        }
    }

    func signInWithApple() async throws -> User {
        try await Task.sleep(for: simulatedLatency)
        return Self.makeUser(
            email: "apple-user@privaterelay.appleid.com",
            nickname: "Appleユーザー"
        )
    }

    func sendPasswordReset(email: String) async throws {
        try await Task.sleep(for: simulatedLatency)
        if email.lowercased() == "network@example.com" {
            throw AuthError.networkError
        }
    }

    func signOut() async throws {
        try await Task.sleep(for: .milliseconds(100))
    }

    // MARK: - Helpers

    private static func makeUser(email: String, nickname: String) -> User {
        User(
            id: UUID().uuidString,
            email: email,
            nickname: nickname,
            role: .questioner,
            createdAt: Date()
        )
    }

    private static func nicknameFromEmail(_ email: String) -> String {
        String(email.split(separator: "@").first ?? "ランナー")
    }
}
