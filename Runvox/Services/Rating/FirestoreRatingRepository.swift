import FirebaseFirestore
import Foundation

/// Firestore による本番 RatingRepository 実装
///
/// `submitRating` は 1 つの Transaction で以下を原子的に書き込む:
/// 1. `answers/{answerId}.rating` を評価値で更新
/// 2. `questions/{questionId}.latestRating` を更新（カード表示用に denormalize）
/// 3. `pointTransactions/{auto}` を作成（回答者への付与履歴）
/// 4. `userPoints/{answererId}` の残高・累積・今月を `FieldValue.increment` で加算
///
/// - Important: MVP ではポイント付与を**クライアント側**で行う。評価者が回答者の
///   `userPoints` を書き込むため、ルールも本人以外の write を許している（改ざん可能）。
///   本番リリース前に **Cloud Functions（onRatingCreate トリガ）へ移管**し、
///   `userPoints` / `pointTransactions` の write はサーバ（Admin）に限定すること。
final class FirestoreRatingRepository: RatingRepository {
    /// 評価から導出されるポイント付与情報のスナップショット
    private struct Award {
        let stars: Int
        let rank: Rank
        let basePoints: Int
        let multiplier: Double
        let points: Int

        init(stars: Int, rank: Rank) {
            self.stars = stars
            self.rank = rank
            self.basePoints = PointCalculator.basePoints[stars] ?? 0
            self.multiplier = rank.multiplier
            self.points = PointCalculator.calculate(stars: stars, rank: rank)
        }
    }

    func submitRating(
        answerId: String,
        stars: Int,
        answererRank: Rank
    ) async throws -> RatingResult {
        guard (1...5).contains(stars) else { throw RatingError.invalidStars }

        let award = Award(stars: stars, rank: answererRank)
        let db = Firestore.firestore()
        let answerRef = db.collection("answers").document(answerId)
        let txRef = db.collection("pointTransactions").document()

        _ = try await db.runTransaction { transaction, errorPointer in
            // --- reads（全 read を write より前に行う）---
            // 評価対象の回答は必須（無ければ answerNotFound）
            guard let answerData = Self.requireAnswer(answerRef, in: transaction, errorPointer) else {
                return nil
            }
            guard
                let answererId = answerData["answererId"] as? String,
                let questionId = answerData["questionId"] as? String
            else {
                errorPointer?.pointee = RatingError.answerNotFound as NSError
                return nil
            }

            // 質問は latestRating の denormalize 先。欠落していても致命ではないので寛容に読む。
            let questionRef = db.collection("questions").document(questionId)
            let questionSnap: DocumentSnapshot
            do {
                questionSnap = try transaction.getDocument(questionRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            // --- writes ---
            transaction.updateData(["rating": award.stars], forDocument: answerRef)
            if questionSnap.exists {
                transaction.updateData(["latestRating": award.stars], forDocument: questionRef)
            }
            transaction.setData(
                Self.transactionData(
                    answererId: answererId,
                    answerId: answerId,
                    questionTitle: questionSnap.data()?["title"] as? String ?? "",
                    award: award
                ),
                forDocument: txRef
            )
            transaction.setData(
                Self.incrementData(award),
                forDocument: db.collection("userPoints").document(answererId),
                merge: true
            )
            return nil
        }

        return RatingResult(
            answerId: answerId,
            stars: award.stars,
            basePoints: award.basePoints,
            rankMultiplier: award.multiplier,
            pointsAwarded: award.points
        )
    }

    // MARK: - Transaction helpers

    /// Transaction 内で「必須の回答ドキュメント」を read する。
    /// 欠落 / 読み取り失敗時は errorPointer を立てて nil を返す。
    private static func requireAnswer(
        _ ref: DocumentReference,
        in transaction: Transaction,
        _ errorPointer: NSErrorPointer
    ) -> [String: Any]? {
        do {
            let snapshot = try transaction.getDocument(ref)
            guard snapshot.exists, let data = snapshot.data() else {
                errorPointer?.pointee = RatingError.answerNotFound as NSError
                return nil
            }
            return data
        } catch let error as NSError {
            errorPointer?.pointee = error
            return nil
        }
    }

    private static func transactionData(
        answererId: String,
        answerId: String,
        questionTitle: String,
        award: Award
    ) -> [String: Any] {
        [
            "userId": answererId,
            "answerId": answerId,
            "questionTitle": questionTitle,
            "stars": award.stars,
            "rank": award.rank.rawValue,
            "basePoints": award.basePoints,
            "multiplier": award.multiplier,
            "pointsAwarded": award.points,
            "createdAt": Timestamp(date: Date()),
        ]
    }

    private static func incrementData(_ award: Award) -> [String: Any] {
        let delta = FieldValue.increment(Int64(award.points))
        return [
            "balance": delta,
            "lifetimeEarned": delta,
            "thisMonthEarned": delta,
        ]
    }
}
