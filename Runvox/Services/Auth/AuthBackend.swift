import Foundation

/// 認証バックエンドの抽象化
///
/// MVP では `MockAuthBackend` を使用。Firebase 統合後は
/// `FirebaseAuthBackend` に差し替えるだけで AuthService / UI 層は無変更。
protocol AuthBackend: Sendable {
    /// 起動時のセッション復元（ログイン済みならユーザーを返す）
    func restoreSession() async -> User?

    /// メール + パスワードでログイン
    func signInWithEmail(email: String, password: String) async throws -> User

    /// メール + パスワード + ニックネームで新規登録
    func signUpWithEmail(email: String, password: String, nickname: String) async throws -> User

    /// Apple Sign In
    func signInWithApple() async throws -> User

    /// パスワードリセットメール送信
    func sendPasswordReset(email: String) async throws

    /// プロフィール更新（更新後のユーザーを返す）
    func updateProfile(_ user: User) async throws -> User

    /// ログアウト
    func signOut() async throws
}
