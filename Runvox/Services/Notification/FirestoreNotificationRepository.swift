import FirebaseFirestore
import Foundation

/// Firestore による本番 NotificationRepository 実装
///
/// - コレクション: `notifications`（`userId` フィールドで宛先ユーザーに紐づく）
/// - 通知ドキュメントの**作成は Cloud Functions（Admin）側**で行う想定。
///   クライアントは読み取りと既読化のみ。
/// - `fetchNotifications` は `userId` 一致 + `createdAt` 降順の複合インデックスが必要
///   （`firestore.indexes.json` 参照）。
final class FirestoreNotificationRepository: NotificationRepository {
    private var db: Firestore { Firestore.firestore() }
    private var collection: CollectionReference { db.collection("notifications") }

    func fetchNotifications(userId: String, limit: Int) async throws -> [AppNotification] {
        let snapshot = try await collection
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { Self.decode($0.data(), id: $0.documentID) }
    }

    func markAsRead(notificationId: String) async throws {
        try await collection.document(notificationId).updateData(["isRead": true])
    }

    func markAllAsRead(userId: String) async throws {
        // userId + isRead の 2 つの等価フィルタは単一フィールドインデックスで処理されるため
        // 複合インデックス不要。
        let snapshot = try await collection
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
            .getDocuments()

        guard !snapshot.documents.isEmpty else { return }

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["isRead": true], forDocument: doc.reference)
        }
        try await batch.commit()
    }

    func unreadCount(userId: String) async throws -> Int {
        let query = collection
            .whereField("userId", isEqualTo: userId)
            .whereField("isRead", isEqualTo: false)
        let snapshot = try await query.count.getAggregation(source: .server)
        return snapshot.count.intValue
    }

    // MARK: - Firestore mapping

    private static func decode(_ data: [String: Any], id: String) -> AppNotification? {
        guard
            let userId = data["userId"] as? String,
            let typeRaw = data["type"] as? String,
            let type = NotificationType(rawValue: typeRaw),
            let title = data["title"] as? String,
            let body = data["body"] as? String
        else {
            return nil
        }

        return AppNotification(
            id: id,
            userId: userId,
            type: type,
            title: title,
            body: body,
            targetPath: data["targetPath"] as? String,
            isRead: data["isRead"] as? Bool ?? false,
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        )
    }
}
