import Foundation

/// 認証フォームのバリデーション
enum AuthValidator {
    static let minPasswordLength = 8
    static let minNicknameLength = 2
    static let maxNicknameLength = 20

    /// メールアドレスの形式チェック
    static func validateEmail(_ email: String) -> Result<String, AuthError> {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard trimmed.range(of: pattern, options: .regularExpression) != nil else {
            return .failure(.invalidEmail)
        }
        return .success(trimmed)
    }

    /// パスワードの強度チェック
    /// - 8 文字以上 / 英数字を含む
    static func validatePassword(_ password: String) -> Result<String, AuthError> {
        guard password.count >= minPasswordLength else {
            return .failure(.weakPassword(
                "パスワードは \(minPasswordLength) 文字以上にしてください"
            ))
        }
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasDigit = password.rangeOfCharacter(from: .decimalDigits) != nil
        guard hasLetter, hasDigit else {
            return .failure(.weakPassword("英字と数字を両方含めてください"))
        }
        return .success(password)
    }

    /// ニックネームのチェック
    /// - 2〜20 文字 / 空白のみは不可
    static func validateNickname(_ nickname: String) -> Result<String, AuthError> {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= minNicknameLength else {
            return .failure(.invalidNickname(
                "ニックネームは \(minNicknameLength) 文字以上で入力してください"
            ))
        }
        guard trimmed.count <= maxNicknameLength else {
            return .failure(.invalidNickname(
                "ニックネームは \(maxNicknameLength) 文字以内にしてください"
            ))
        }
        return .success(trimmed)
    }
}
