import Foundation

/// 認証状態を管理するアプリ全体のサービス
///
/// - View からは `@EnvironmentObject` で参照する
/// - 内部の `AuthBackend` を差し替えることで Mock / Firebase を切り替え可能
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var state: AuthState = .loading

    private let backend: AuthBackend

    /// - Parameters:
    ///   - backend: 認証バックエンド
    ///   - autoRestore: true で init 時に自動でセッション復元を開始。
    ///     テストでは false にして `restoreSession()` を明示的に await する
    init(backend: AuthBackend = MockAuthBackend(), autoRestore: Bool = true) {
        self.backend = backend
        if autoRestore {
            Task { await restoreSession() }
        }
    }

    // MARK: - Convenience accessors

    var currentUser: User? { state.currentUser }
    var isSignedIn: Bool { state.isSignedIn }

    // MARK: - Session

    func restoreSession() async {
        let user = await backend.restoreSession()
        state = user.map { .signedIn($0) } ?? .signedOut
    }

    // MARK: - Sign in / Sign up

    func signInWithEmail(email: String, password: String) async throws {
        let validEmail = try AuthValidator.validateEmail(email).get()
        let user = try await backend.signInWithEmail(email: validEmail, password: password)
        state = .signedIn(user)
    }

    func signUpWithEmail(email: String, password: String, nickname: String) async throws {
        let validEmail = try AuthValidator.validateEmail(email).get()
        let validPassword = try AuthValidator.validatePassword(password).get()
        let validNickname = try AuthValidator.validateNickname(nickname).get()
        let user = try await backend.signUpWithEmail(
            email: validEmail,
            password: validPassword,
            nickname: validNickname
        )
        state = .signedIn(user)
    }

    func signInWithApple() async throws {
        let user = try await backend.signInWithApple()
        state = .signedIn(user)
    }

    func sendPasswordReset(email: String) async throws {
        let validEmail = try AuthValidator.validateEmail(email).get()
        try await backend.sendPasswordReset(email: validEmail)
    }

    /// プロフィール更新（nickname / bio / isAnonymous）
    func updateProfile(nickname: String, bio: String?, isAnonymous: Bool) async throws {
        guard let current = currentUser else { throw AuthError.notSignedIn }
        let validNickname = try AuthValidator.validateNickname(nickname).get()

        var updated = current
        updated.nickname = validNickname
        updated.bio = bio?.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.isAnonymous = isAnonymous

        let saved = try await backend.updateProfile(updated)
        state = .signedIn(saved)
    }

    func signOut() async throws {
        try await backend.signOut()
        state = .signedOut
    }
}

// MARK: - Preview helper

extension AuthService {
    /// SwiftUI Preview / テスト用に状態を即座にセット
    static func previewSignedIn(
        _ user: User = .preview,
        latency: Duration = .milliseconds(400)
    ) -> AuthService {
        let service = AuthService(
            backend: MockAuthBackend(simulatedLatency: latency),
            autoRestore: false
        )
        service.state = .signedIn(user)
        return service
    }

    static func previewSignedOut() -> AuthService {
        let service = AuthService(backend: MockAuthBackend())
        service.state = .signedOut
        return service
    }
}

extension User {
    static let preview = User(
        id: "preview-user",
        email: "preview@runvox.app",
        nickname: "プレビュー太郎",
        bio: "サブ3.5を目指す市民ランナーです",
        role: .questioner
    )
}
