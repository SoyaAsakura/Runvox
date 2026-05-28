import Foundation

/// ユーザー情報（プロフィール）へのアクセス抽象化
protocol UserRepository: Sendable {
    /// 回答者プロフィールを取得
    /// - Returns: 該当ユーザーがいなければ nil
    func fetchAnswererProfile(userId: String) async throws -> AnswererProfile?
}
