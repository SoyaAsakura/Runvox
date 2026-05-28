import Foundation

/// ポイント情報へのアクセス抽象化
///
/// 後で `FirestorePointRepository` に差し替える
protocol PointRepository: Sendable {
    /// 残高・累積・月別サマリ
    func fetchSummary(userId: String) async throws -> UserPoints

    /// 直近のトランザクション
    func fetchTransactions(userId: String, limit: Int) async throws -> [PointTransaction]
}
