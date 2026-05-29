import Foundation

/// Firestore 統合前の開発用モック実装
///
/// 既読状態をまたいで共有させたい（ホームのバッジ ↔ 一覧）ため、
/// `.shared` の単一インスタンスを各 View のデフォルトに使う。
/// テストでは個別インスタンスを注入する。
final class MockNotificationRepository: NotificationRepository {
    /// ホームのバッジと通知一覧で既読状態を共有するための共有インスタンス
    static let shared = MockNotificationRepository()

    private let simulatedLatency: Duration
    private let lock = NSLock()
    private var store: [AppNotification]

    init(
        simulatedLatency: Duration = .milliseconds(300),
        notifications: [AppNotification] = MockNotificationRepository.defaultNotifications
    ) {
        self.simulatedLatency = simulatedLatency
        self.store = notifications
    }

    func fetchNotifications(userId: String, limit: Int) async throws -> [AppNotification] {
        try await Task.sleep(for: simulatedLatency)
        return lock.withLock {
            let filtered = store
                .filter { $0.userId == userId }
                .sorted { $0.createdAt > $1.createdAt }
            return Array(filtered.prefix(limit))
        }
    }

    func markAsRead(notificationId: String) async throws {
        try await Task.sleep(for: .milliseconds(50))
        lock.withLock {
            if let index = store.firstIndex(where: { $0.id == notificationId }) {
                store[index].isRead = true
            }
        }
    }

    func markAllAsRead(userId: String) async throws {
        try await Task.sleep(for: .milliseconds(50))
        lock.withLock {
            for index in store.indices where store[index].userId == userId {
                store[index].isRead = true
            }
        }
    }

    func unreadCount(userId: String) async throws -> Int {
        try await Task.sleep(for: .milliseconds(50))
        return lock.withLock {
            store.filter { $0.userId == userId && !$0.isRead }.count
        }
    }

    // MARK: - Sample data

    static let sampleUserId = "preview-user"

    static let defaultNotifications: [AppNotification] = [
        AppNotification(
            id: "n1",
            userId: sampleUserId,
            type: .ratingReceived,
            title: "評価が付きました",
            body: "「30km走の頻度は？」への回答に ★5 が付きました（+500pt）",
            targetPath: "/questions/q-old-1",
            isRead: false,
            createdAt: Date().addingTimeInterval(-15 * 60)
        ),
        AppNotification(
            id: "n2",
            userId: sampleUserId,
            type: .answerReceived,
            title: "回答が届きました",
            body: "「サブ3.5を狙うための30km走の頻度は？」に田中コーチが回答しました",
            targetPath: "/questions/q1",
            isRead: false,
            createdAt: Date().addingTimeInterval(-2 * 60 * 60)
        ),
        AppNotification(
            id: "n3",
            userId: sampleUserId,
            type: .pointConfirmed,
            title: "ポイントが確定しました",
            body: "今週の獲得ポイントが確定しました。累計 12,450pt",
            targetPath: nil,
            isRead: true,
            createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60)
        ),
        AppNotification(
            id: "n4",
            userId: sampleUserId,
            type: .rallyReceived,
            title: "追加質問が届きました",
            body: "「カーボローディングは何時間前から？」で追加質問があります",
            targetPath: "/questions/q3",
            isRead: true,
            createdAt: Date().addingTimeInterval(-3 * 24 * 60 * 60)
        ),
    ]
}
