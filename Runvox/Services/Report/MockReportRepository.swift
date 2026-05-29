import Foundation

/// Firestore 統合前の開発用モック実装
///
/// 本番では submit 時に Cloud Functions が運営宛メールを送る。
/// Mock では送信を模倣するだけ。"fail-network" を comment に含めるとエラー。
final class MockReportRepository: ReportRepository {
    enum MockError: LocalizedError {
        case network

        var errorDescription: String? {
            switch self {
            case .network: return "通信エラーが発生しました。時間をおいて再度お試しください"
            }
        }
    }

    private let simulatedLatency: Duration

    init(simulatedLatency: Duration = .milliseconds(400)) {
        self.simulatedLatency = simulatedLatency
    }

    func submitReport(_ draft: ReportDraft) async throws -> Report {
        try await Task.sleep(for: simulatedLatency)

        if draft.comment?.contains("fail-network") == true {
            throw MockError.network
        }

        return Report(
            id: UUID().uuidString,
            reporterId: draft.reporterId,
            targetType: draft.targetType,
            targetId: draft.targetId,
            reason: draft.reason,
            comment: draft.comment?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .nilIfEmpty,
            createdAt: Date()
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
