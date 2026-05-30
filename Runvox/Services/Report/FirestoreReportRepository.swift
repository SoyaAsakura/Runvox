import FirebaseFirestore
import Foundation

/// Firestore による本番 ReportRepository 実装
///
/// - コレクション: `reports`
/// - 通報はモデレーション用。クライアントからの読み取りは不可（Admin のみ）。
/// - 本番では作成をトリガに Cloud Functions が運営宛メールを送る想定。
final class FirestoreReportRepository: ReportRepository {
    private var collection: CollectionReference {
        Firestore.firestore().collection("reports")
    }

    func submitReport(_ draft: ReportDraft) async throws -> Report {
        let ref = collection.document()
        let comment = draft.comment?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfEmpty

        let report = Report(
            id: ref.documentID,
            reporterId: draft.reporterId,
            targetType: draft.targetType,
            targetId: draft.targetId,
            reason: draft.reason,
            comment: comment,
            createdAt: Date()
        )

        try await ref.setData([
            "reporterId": report.reporterId,
            "targetType": report.targetType.rawValue,
            "targetId": report.targetId,
            "reason": report.reason.rawValue,
            "comment": comment ?? NSNull(),
            "createdAt": Timestamp(date: report.createdAt),
        ])

        return report
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
