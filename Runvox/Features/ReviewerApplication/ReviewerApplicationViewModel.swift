import Foundation

/// 回答者審査申請画面の状態管理
@MainActor
final class ReviewerApplicationViewModel: ObservableObject {
    @Published private(set) var application: ReviewerApplication?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    // フォーム入力
    @Published var achievements: String = ""
    @Published var certifications: String = ""
    @Published var referenceURL: String = ""

    @Published private(set) var isSubmitting: Bool = false

    static let minAchievementsLength = 10
    static let maxAchievementsLength = 2000

    private let userId: String
    private let repository: ReviewerApplicationRepository

    init(
        userId: String,
        repository: ReviewerApplicationRepository = MockReviewerApplicationRepository()
    ) {
        self.userId = userId
        self.repository = repository
    }

    // MARK: - Derived state

    /// 既存申請が存在する場合 (status 表示モード)
    var hasExistingApplication: Bool { application != nil }

    /// 新規入力フォームを表示すべきか
    var shouldShowForm: Bool {
        guard let app = application else { return true }
        return app.canResubmit
    }

    var canSubmit: Bool {
        let trimmed = achievements.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= Self.minAchievementsLength
            && trimmed.count <= Self.maxAchievementsLength
            && !isSubmitting
    }

    var achievementsCount: Int {
        achievements.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    // MARK: - Load

    func loadIfNeeded() async {
        guard application == nil, !isLoading else { return }
        await load()
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            application = try await repository.fetchLatest(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Submit

    func submit() async -> Bool {
        guard canSubmit else { return false }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        let draft = ReviewerApplicationDraft(
            userId: userId,
            achievements: achievements,
            certifications: certifications,
            referenceURL: referenceURL.isEmpty ? nil : referenceURL
        )

        do {
            application = try await repository.submit(draft)
            // 入力欄クリア
            achievements = ""
            certifications = ""
            referenceURL = ""
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
