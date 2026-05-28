import Foundation

/// 認証エラー
enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword(String)
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case invalidNickname(String)
    case nicknameAlreadyTaken
    case networkError
    case appleSignInCancelled
    case appleSignInFailed
    case notSignedIn
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません"
        case .weakPassword(let detail):
            return detail
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使われています"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .wrongPassword:
            return "パスワードが間違っています"
        case .invalidNickname(let detail):
            return detail
        case .nicknameAlreadyTaken:
            return "このニックネームは既に使われています"
        case .networkError:
            return "通信エラーが発生しました。電波の良い場所で再度お試しください"
        case .appleSignInCancelled:
            return "Apple サインインがキャンセルされました"
        case .appleSignInFailed:
            return "Apple サインインに失敗しました"
        case .notSignedIn:
            return "ログインしていません"
        case .unknown(let message):
            return message
        }
    }
}
