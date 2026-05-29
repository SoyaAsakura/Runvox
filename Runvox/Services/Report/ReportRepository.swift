import Foundation

/// 通報データへのアクセス抽象化
///
/// 本番（Firestore）では reports コレクションに保存し、
/// Cloud Functions が運営宛メール（moderation@runvox.app）を自動送信する。
protocol ReportRepository: Sendable {
    /// 通報を送信する
    func submitReport(_ draft: ReportDraft) async throws -> Report
}
