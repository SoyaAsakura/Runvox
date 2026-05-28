import Foundation

/// 回答評価で発生したポイント付与のトランザクション
struct PointTransaction: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String              // 受領者（回答者）
    let answerId: String
    let questionTitle: String       // 表示用に denormalize
    let stars: Int                  // 1〜5
    let rank: Rank                  // 投稿時点のランク
    let basePoints: Int
    let multiplier: Double
    let pointsAwarded: Int
    let createdAt: Date

    /// 「5/24」のような短縮日付
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter.string(from: createdAt)
    }
}
