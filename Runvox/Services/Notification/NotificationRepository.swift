import Foundation

/// アプリ内通知へのアクセス抽象化
///
/// 本番では Firestore の notifications コレクションに差し替え
protocol NotificationRepository: Sendable {
    /// 通知一覧を取得（新しい順）
    func fetchNotifications(userId: String, limit: Int) async throws -> [AppNotification]

    /// 1 件を既読にする
    func markAsRead(notificationId: String) async throws

    /// 全件を既読にする
    func markAllAsRead(userId: String) async throws

    /// 未読件数
    func unreadCount(userId: String) async throws -> Int
}
