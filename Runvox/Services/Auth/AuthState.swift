import Foundation

/// 認証状態
enum AuthState: Equatable {
    case loading            // 起動直後のセッション復元中
    case signedOut          // 未ログイン
    case signedIn(User)     // ログイン済み

    var isSignedIn: Bool {
        if case .signedIn = self { return true }
        return false
    }

    var currentUser: User? {
        if case .signedIn(let user) = self { return user }
        return nil
    }
}
