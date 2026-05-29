import Foundation

/// 回答者審査申請データへのアクセス抽象化
///
/// 本番では Firestore + 運営宛通知メール送信（Cloud Functions）に差し替え
protocol ReviewerApplicationRepository: Sendable {
    /// 指定ユーザーの最新の申請を取得
    func fetchLatest(userId: String) async throws -> ReviewerApplication?

    /// 新規申請を送信
    func submit(_ draft: ReviewerApplicationDraft) async throws -> ReviewerApplication
}
