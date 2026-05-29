import Foundation

/// Firestore 統合前の開発用モック実装
///
/// - 初期状態: 申請なし
/// - submit 成功で in-memory に保持
/// - 入力エラーの動作確認用に "fail" を achievements に含めるとエラー
final class MockReviewerApplicationRepository: ReviewerApplicationRepository {
    enum MockError: LocalizedError {
        case validation(String)
        case network

        var errorDescription: String? {
            switch self {
            case .validation(let msg): return msg
            case .network:             return "通信エラーが発生しました"
            }
        }
    }

    private let simulatedLatency: Duration
    private let lock = NSLock()
    private var stored: [String: ReviewerApplication]   // userId → 最新申請

    init(
        simulatedLatency: Duration = .milliseconds(400),
        initial: [String: ReviewerApplication] = [:]
    ) {
        self.simulatedLatency = simulatedLatency
        self.stored = initial
    }

    func fetchLatest(userId: String) async throws -> ReviewerApplication? {
        try await Task.sleep(for: simulatedLatency)
        return lock.withLock { stored[userId] }
    }

    func submit(_ draft: ReviewerApplicationDraft) async throws -> ReviewerApplication {
        try await Task.sleep(for: simulatedLatency)

        if draft.achievements.contains("fail-network") {
            throw MockError.network
        }
        let trimmedAch = draft.achievements.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAch.count >= 10 else {
            throw MockError.validation("実績は 10 文字以上で記入してください")
        }

        let application = ReviewerApplication(
            id: UUID().uuidString,
            userId: draft.userId,
            status: .submitted,
            achievements: trimmedAch,
            certifications: draft.certifications.trimmingCharacters(in: .whitespacesAndNewlines),
            referenceURL: draft.referenceURL?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            submittedAt: Date(),
            reviewedAt: nil,
            assignedRank: nil,
            rejectionReason: nil
        )
        lock.withLock { stored[draft.userId] = application }
        return application
    }
}

// MARK: - String helper

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
