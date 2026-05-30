import Foundation

/// 評価送信の結果
struct RatingResult: Equatable {
    let answerId: String
    let stars: Int            // 1〜5
    let basePoints: Int       // ★ごとの基本ポイント
    let rankMultiplier: Double
    let pointsAwarded: Int    // 最終付与額
}

/// 評価データへのアクセス抽象化
///
/// 後で `FirestoreRatingRepository` に差し替える
/// (Firestore Transaction で rating + point_transaction を原子的に書き込む想定)
protocol RatingRepository: Sendable {
    /// 回答に評価を付与する
    /// - Parameters:
    ///   - answerId: 評価対象の回答 ID
    ///   - stars: 1〜5 の評価値
    ///   - answererRank: 評価時点の回答者ランク（スナップショット）
    func submitRating(
        answerId: String,
        stars: Int,
        answererRank: Rank
    ) async throws -> RatingResult
}

/// 評価送信時のドメインエラー
enum RatingError: LocalizedError {
    /// 評価値が 1〜5 の範囲外
    case invalidStars
    /// 評価対象の回答が見つからない
    case answerNotFound

    var errorDescription: String? {
        switch self {
        case .invalidStars:
            return "評価値は 1〜5 を指定してください"
        case .answerNotFound:
            return "評価対象の回答が見つかりませんでした"
        }
    }
}
