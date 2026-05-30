import Foundation

/// 通報モーダルの状態管理
@MainActor
final class ReportViewModel: ObservableObject {
    let targetType: ReportTargetType
    private let targetId: String
    private let reporterId: String
    private let repository: ReportRepository

    @Published var selectedReason: ReportReason?
    @Published var comment: String = ""
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var errorMessage: String?

    static let maxCommentLength = 500

    init(
        targetType: ReportTargetType,
        targetId: String,
        reporterId: String,
        repository: ReportRepository = RepositoryFactory.makeReportRepository()
    ) {
        self.targetType = targetType
        self.targetId = targetId
        self.reporterId = reporterId
        self.repository = repository
    }

    var canSubmit: Bool {
        selectedReason != nil
            && comment.count <= Self.maxCommentLength
            && !isSubmitting
    }

    /// 通報送信。成功で true。
    func submit() async -> Bool {
        guard let reason = selectedReason, canSubmit else { return false }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        let draft = ReportDraft(
            reporterId: reporterId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            comment: comment.isEmpty ? nil : comment
        )

        do {
            _ = try await repository.submitReport(draft)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
