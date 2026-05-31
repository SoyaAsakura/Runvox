import FirebaseFirestore
import Foundation

/// Firestore による本番 RatingRepository 実装
///
/// クライアントは **評価値の記録のみ** を行う:
/// - `answers/{answerId}.rating` を更新
///
/// ポイント付与（`pointTransactions` / `userPoints`）と質問カードの `latestRating`
/// 反映は、Cloud Functions `awardPointsOnRating`（Admin 権限）が rating の変化を
/// トリガに実行する。これによりクライアントから残高を改ざんできない。
///
/// 返り値の `RatingResult` は UI フィードバック（「+Npt」表示）用に**クライアント側で
/// 算出するだけ**で、ポイントの書き込みはしない（サーバと同じ計算式）。
final class FirestoreRatingRepository: RatingRepository {
    func submitRating(
        answerId: String,
        stars: Int,
        answererRank: Rank
    ) async throws -> RatingResult {
        guard (1...5).contains(stars) else { throw RatingError.invalidStars }

        // クライアントは rating を立てるだけ。これをトリガに Cloud Functions が
        // ポイント付与と latestRating の denormalize を行う。
        try await Firestore.firestore()
            .collection("answers")
            .document(answerId)
            .updateData(["rating": stars])

        return RatingResult(
            answerId: answerId,
            stars: stars,
            basePoints: PointCalculator.basePoints[stars] ?? 0,
            rankMultiplier: answererRank.multiplier,
            pointsAwarded: PointCalculator.calculate(stars: stars, rank: answererRank)
        )
    }
}
