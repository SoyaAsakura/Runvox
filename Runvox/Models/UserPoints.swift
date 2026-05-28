import Foundation

/// ユーザーのポイント残高・実績サマリ
struct UserPoints: Equatable {
    let balance: Int               // 現在残高
    let lifetimeEarned: Int        // 累積獲得
    let thisMonthEarned: Int       // 今月の獲得
    let lastMonthDeltaPercent: Int // 先月比 (例: +18%)

    /// Phase 2 で予定している現金化しきい値（pt）
    static let cashoutThreshold: Int = 20_000

    /// 現金化までの進捗 (0.0 〜 1.0)
    var cashoutProgress: Double {
        guard Self.cashoutThreshold > 0 else { return 1.0 }
        return min(1.0, Double(balance) / Double(Self.cashoutThreshold))
    }

    /// 現金化まであと何 pt 必要か
    var pointsUntilCashout: Int {
        max(0, Self.cashoutThreshold - balance)
    }
}
