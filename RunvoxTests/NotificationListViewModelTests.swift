@testable import Runvox
import XCTest

@MainActor
final class NotificationListViewModelTests: XCTestCase {
    private let userId = MockNotificationRepository.sampleUserId

    private func makeRepo(
        _ notifications: [AppNotification] = MockNotificationRepository.defaultNotifications
    ) -> MockNotificationRepository {
        MockNotificationRepository(simulatedLatency: .milliseconds(0), notifications: notifications)
    }

    private func makeVM(repo: MockNotificationRepository) -> NotificationListViewModel {
        NotificationListViewModel(userId: userId, repository: repo, limit: 50)
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM(repo: makeRepo())
        XCTAssertTrue(vm.notifications.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.unreadCount, 0)
        XCTAssertFalse(vm.hasUnread)
    }

    // MARK: - Load

    func test_loadIfNeeded_populatesAndSortsNewestFirst() async {
        let vm = makeVM(repo: makeRepo())
        await vm.loadIfNeeded()

        XCTAssertEqual(vm.notifications.count, MockNotificationRepository.defaultNotifications.count)
        // 新しい順
        let dates = vm.notifications.map { $0.createdAt }
        XCTAssertEqual(dates, dates.sorted(by: >))
    }

    func test_loadIfNeeded_skipsIfAlreadyLoaded() async {
        let vm = makeVM(repo: makeRepo())
        await vm.loadIfNeeded()
        let count = vm.notifications.count
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.notifications.count, count)
    }

    func test_unreadCount_reflectsSampleData() async {
        let vm = makeVM(repo: makeRepo())
        await vm.loadIfNeeded()
        // sample: n1, n2 が未読 / n3, n4 が既読
        XCTAssertEqual(vm.unreadCount, 2)
        XCTAssertTrue(vm.hasUnread)
    }

    // MARK: - Mark single read

    func test_markAsRead_decrementsUnread() async {
        let repo = makeRepo()
        let vm = makeVM(repo: repo)
        await vm.loadIfNeeded()
        let before = vm.unreadCount

        let unread = vm.notifications.first { !$0.isRead }!
        await vm.markAsRead(unread)

        XCTAssertEqual(vm.unreadCount, before - 1)
        XCTAssertTrue(vm.notifications.first { $0.id == unread.id }!.isRead)
    }

    func test_markAsRead_alreadyReadIsNoOp() async {
        let vm = makeVM(repo: makeRepo())
        await vm.loadIfNeeded()
        let before = vm.unreadCount

        let read = vm.notifications.first { $0.isRead }!
        await vm.markAsRead(read)
        XCTAssertEqual(vm.unreadCount, before)
    }

    // MARK: - Mark all read

    func test_markAllAsRead_clearsUnread() async {
        let vm = makeVM(repo: makeRepo())
        await vm.loadIfNeeded()
        XCTAssertTrue(vm.hasUnread)

        await vm.markAllAsRead()
        XCTAssertEqual(vm.unreadCount, 0)
        XCTAssertFalse(vm.hasUnread)
        XCTAssertTrue(vm.notifications.allSatisfy { $0.isRead })
    }

    // MARK: - Repository shared read-state

    func test_markAsRead_persistsToRepository() async {
        let repo = makeRepo()
        let vm = makeVM(repo: repo)
        await vm.loadIfNeeded()
        let unread = vm.notifications.first { !$0.isRead }!

        await vm.markAsRead(unread)

        // 別 VM で読み直しても既読が反映されている
        let count = try? await repo.unreadCount(userId: userId)
        XCTAssertEqual(count, 1)
    }

    // MARK: - Empty user

    func test_load_emptyForUnknownUser() async {
        let vm = NotificationListViewModel(
            userId: "stranger",
            repository: makeRepo(),
            limit: 50
        )
        await vm.loadIfNeeded()
        XCTAssertTrue(vm.notifications.isEmpty)
    }
}
