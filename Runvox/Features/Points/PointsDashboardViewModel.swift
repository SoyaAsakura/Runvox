import Foundation

/// ポイントダッシュボードの状態管理
@MainActor
final class PointsDashboardViewModel: ObservableObject {
    @Published private(set) var summary: UserPoints?
    @Published private(set) var transactions: [PointTransaction] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let userId: String
    private let repository: PointRepository
    private let limit: Int

    init(
        userId: String,
        repository: PointRepository = RepositoryFactory.makePointRepository(),
        limit: Int = 20
    ) {
        self.userId = userId
        self.repository = repository
        self.limit = limit
    }

    func loadIfNeeded() async {
        guard summary == nil, !isLoading else { return }
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
            async let summaryTask = repository.fetchSummary(userId: userId)
            async let txTask = repository.fetchTransactions(userId: userId, limit: limit)
            summary = try await summaryTask
            transactions = try await txTask
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
