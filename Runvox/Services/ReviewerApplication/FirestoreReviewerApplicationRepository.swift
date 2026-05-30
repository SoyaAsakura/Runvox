import FirebaseFirestore
import Foundation

/// Firestore による本番 ReviewerApplicationRepository 実装
///
/// - コレクション: `reviewerApplications`
/// - `fetchLatest` は `userId` 一致 + `submittedAt` 降順の複合インデックスが必要
///   （`firestore.indexes.json` 参照）。再申請のたびに新規ドキュメントを作るため、
///   最新 1 件を取得する。
/// - 審査結果（approved / rejected）への `status` 更新は**運営（Admin）側**で行う想定。
///   クライアントは作成（申請）と最新取得のみ。
final class FirestoreReviewerApplicationRepository: ReviewerApplicationRepository {
    private var collection: CollectionReference {
        Firestore.firestore().collection("reviewerApplications")
    }

    func fetchLatest(userId: String) async throws -> ReviewerApplication? {
        let snapshot = try await collection
            .whereField("userId", isEqualTo: userId)
            .order(by: "submittedAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return Self.decode(doc.data(), id: doc.documentID)
    }

    func submit(_ draft: ReviewerApplicationDraft) async throws -> ReviewerApplication {
        let trimmedAch = draft.achievements.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedAch.count >= 10 else {
            throw ReviewerApplicationError.validation("実績は 10 文字以上で記入してください")
        }

        let ref = collection.document()
        let application = ReviewerApplication(
            id: ref.documentID,
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

        try await ref.setData(Self.encode(application))
        return application
    }

    // MARK: - Firestore mapping

    private static func encode(_ app: ReviewerApplication) -> [String: Any] {
        [
            "userId": app.userId,
            "status": app.status.rawValue,
            "achievements": app.achievements,
            "certifications": app.certifications,
            "referenceURL": app.referenceURL ?? NSNull(),
            "submittedAt": Timestamp(date: app.submittedAt),
            "reviewedAt": app.reviewedAt.map { Timestamp(date: $0) } ?? NSNull(),
            "assignedRank": app.assignedRank?.rawValue ?? NSNull(),
            "rejectionReason": app.rejectionReason ?? NSNull(),
        ]
    }

    private static func decode(_ data: [String: Any], id: String) -> ReviewerApplication? {
        guard
            let userId = data["userId"] as? String,
            let statusRaw = data["status"] as? String,
            let status = ApplicationStatus(rawValue: statusRaw),
            let achievements = data["achievements"] as? String
        else {
            return nil
        }

        return ReviewerApplication(
            id: id,
            userId: userId,
            status: status,
            achievements: achievements,
            certifications: data["certifications"] as? String ?? "",
            referenceURL: data["referenceURL"] as? String,
            submittedAt: (data["submittedAt"] as? Timestamp)?.dateValue() ?? Date(),
            reviewedAt: (data["reviewedAt"] as? Timestamp)?.dateValue(),
            assignedRank: (data["assignedRank"] as? String).flatMap(Rank.init(rawValue:)),
            rejectionReason: data["rejectionReason"] as? String
        )
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
