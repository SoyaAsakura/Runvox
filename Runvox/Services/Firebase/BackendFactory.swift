import Foundation

/// Firebase が利用可能なら本番実装、なければ Mock を返すファクトリ。
///
/// `FirebaseBootstrap.configureIfAvailable()` を呼んだ後に使うこと。
enum BackendFactory {
    /// 認証バックエンド
    static func makeAuthBackend() -> AuthBackend {
        if FirebaseBootstrap.isAvailable {
            return FirebaseAuthBackend()
        }
        return MockAuthBackend()
    }
}
