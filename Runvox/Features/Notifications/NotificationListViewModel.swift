import Foundation

/// 通知一覧画面の状態管理
@MainActor
final class NotificationListViewModel: ObservableObject {
    @Published private(set) var notifications: [AppNotification] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let userId: String
    private let repository: NotificationRepository
    private let limit: Int

    init(
        userId: String,
        repository: NotificationRepository = RepositoryFactory.makeNotificationRepository(),
        limit: Int = 50
    ) {
        self.userId = userId
        self.repository = repository
        self.limit = limit
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var hasUnread: Bool { unreadCount > 0 }

    // MARK: - Load

    func loadIfNeeded() async {
        guard notifications.isEmpty, !isLoading else { return }
        await load()
    }

    func refresh() async {
        await load()
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            notifications = try await repository.fetchNotifications(userId: userId, limit: limit)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Mark read

    func markAsRead(_ notification: AppNotification) async {
        guard !notification.isRead else { return }
        // 楽観的更新
        updateLocal(id: notification.id, isRead: true)
        do {
            try await repository.markAsRead(notificationId: notification.id)
        } catch {
            // 失敗したら戻す
            updateLocal(id: notification.id, isRead: false)
            errorMessage = error.localizedDescription
        }
    }

    func markAllAsRead() async {
        guard hasUnread else { return }
        let snapshot = notifications
        notifications = notifications.map { var n = $0; n.isRead = true; return n }
        do {
            try await repository.markAllAsRead(userId: userId)
        } catch {
            notifications = snapshot
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func updateLocal(id: String, isRead: Bool) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[index].isRead = isRead
    }
}
