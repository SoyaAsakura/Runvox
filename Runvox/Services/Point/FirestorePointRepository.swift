import FirebaseFirestore
import Foundation

/// Firestore による本番 PointRepository 実装
///
/// - 残高サマリ: `userPoints/{userId}` ドキュメント（FirestoreRatingRepository が加算する）
/// - 付与履歴: `pointTransactions`（`userId` = 受領者でフィルタ、`createdAt` 降順）
///   → `userId` + `createdAt` の複合インデックスが必要（firestore.indexes.json 参照）
final class FirestorePointRepository: PointRepository {
    private var db: Firestore { Firestore.firestore() }

    func fetchSummary(userId: String) async throws -> UserPoints {
        let snapshot = try await db.collection("userPoints").document(userId).getDocument()
        guard let data = snapshot.data() else {
            // 未付与のユーザーはゼロサマリを返す
            return UserPoints(balance: 0, lifetimeEarned: 0, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        }
        return UserPoints(
            balance: data["balance"] as? Int ?? 0,
            lifetimeEarned: data["lifetimeEarned"] as? Int ?? 0,
            thisMonthEarned: data["thisMonthEarned"] as? Int ?? 0,
            lastMonthDeltaPercent: data["lastMonthDeltaPercent"] as? Int ?? 0
        )
    }

    func fetchTransactions(userId: String, limit: Int) async throws -> [PointTransaction] {
        let snapshot = try await db.collection("pointTransactions")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { Self.decode($0.data(), id: $0.documentID) }
    }

    // MARK: - Firestore mapping

    private static func decode(_ data: [String: Any], id: String) -> PointTransaction? {
        guard
            let userId = data["userId"] as? String,
            let answerId = data["answerId"] as? String,
            let stars = data["stars"] as? Int
        else {
            return nil
        }

        let rank = (data["rank"] as? String).flatMap(Rank.init(rawValue:)) ?? .b

        return PointTransaction(
            id: id,
            userId: userId,
            answerId: answerId,
            questionTitle: data["questionTitle"] as? String ?? "",
            stars: stars,
            rank: rank,
            basePoints: data["basePoints"] as? Int ?? 0,
            multiplier: data["multiplier"] as? Double ?? rank.multiplier,
            pointsAwarded: data["pointsAwarded"] as? Int ?? 0,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
