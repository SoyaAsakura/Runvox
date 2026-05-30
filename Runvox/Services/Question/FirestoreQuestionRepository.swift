import FirebaseFirestore
import Foundation

/// Firestore による本番 QuestionRepository 実装
///
/// - コレクション: `questions`
/// - `QuestionStatus` は associated value（rallyActive）を持つため、
///   `status` 文字列 + `rallyUsed` / `rallyMax` のフラットなフィールドに分解して保存する。
/// - `searchQuestions` は Firestore が部分一致検索を持たないため、
///   直近 `searchScanLimit` 件を取得してクライアント側でフィルタする（MVP 実装）。
///   将来は Algolia 等の全文検索か、トークン配列 + array-contains に置き換える。
final class FirestoreQuestionRepository: QuestionRepository {
    /// search 時にスキャンする最大件数（クライアント側フィルタ用）
    private let searchScanLimit: Int

    init(searchScanLimit: Int = 200) {
        self.searchScanLimit = searchScanLimit
    }

    private var collection: CollectionReference {
        Firestore.firestore().collection("questions")
    }

    // MARK: - Fetch

    func fetchQuestions(
        category: QuestionCategory?,
        limit: Int
    ) async throws -> [Question] {
        var query: Query = collection
        if let category {
            // category + createdAt の複合インデックスが必要（firestore.indexes.json 参照）
            query = query.whereField("category", isEqualTo: category.rawValue)
        }
        query = query
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { Self.decode($0.data(), id: $0.documentID) }
    }

    // MARK: - Create

    func createQuestion(_ draft: NewQuestionDraft) async throws -> Question {
        let ref = collection.document()
        let question = Question(
            id: ref.documentID,
            askerId: draft.askerId,
            askerNickname: draft.askerNickname,
            category: draft.category,
            title: draft.title,
            body: draft.body,
            status: .waiting,
            createdAt: Date(),
            latestAnswerer: nil,
            latestRating: nil
        )
        try await ref.setData(Self.encode(question))
        return question
    }

    // MARK: - Search

    func searchQuestions(query: String, limit: Int) async throws -> [Question] {
        let lowered = query.lowercased()
        guard !lowered.isEmpty else { return [] }

        let snapshot = try await collection
            .order(by: "createdAt", descending: true)
            .limit(to: searchScanLimit)
            .getDocuments()

        let matched = snapshot.documents
            .compactMap { Self.decode($0.data(), id: $0.documentID) }
            .filter {
                $0.title.lowercased().contains(lowered)
                    || $0.body.lowercased().contains(lowered)
            }
        return Array(matched.prefix(limit))
    }

    // MARK: - Firestore mapping

    /// Question → Firestore データ。nil の任意項目は NSNull() で明示クリアできるようにする。
    private static func encode(_ question: Question) -> [String: Any] {
        var data: [String: Any] = [
            "askerId": question.askerId,
            "askerNickname": question.askerNickname,
            "category": question.category.rawValue,
            "title": question.title,
            "body": question.body,
            "createdAt": Timestamp(date: question.createdAt),
            "latestRating": question.latestRating ?? NSNull(),
            "latestAnswererId": question.latestAnswerer?.userId ?? NSNull(),
            "latestAnswererNickname": question.latestAnswerer?.nickname ?? NSNull(),
            "latestAnswererRank": question.latestAnswerer?.rank?.rawValue ?? NSNull(),
        ]

        switch question.status {
        case .waiting:
            data["status"] = "waiting"
        case .answered:
            data["status"] = "answered"
        case .rallyActive(let used, let max):
            data["status"] = "rallyActive"
            data["rallyUsed"] = used
            data["rallyMax"] = max
        }

        return data
    }

    /// Firestore データ → Question。必須項目が欠ける壊れたドキュメントは nil（読み飛ばす）。
    private static func decode(_ data: [String: Any], id: String) -> Question? {
        guard
            let askerId = data["askerId"] as? String,
            let askerNickname = data["askerNickname"] as? String,
            let categoryRaw = data["category"] as? String,
            let category = QuestionCategory(rawValue: categoryRaw),
            let title = data["title"] as? String,
            let body = data["body"] as? String
        else {
            return nil
        }

        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Question(
            id: id,
            askerId: askerId,
            askerNickname: askerNickname,
            category: category,
            title: title,
            body: body,
            status: decodeStatus(data),
            createdAt: createdAt,
            latestAnswerer: decodeAnswerer(data),
            latestRating: data["latestRating"] as? Int
        )
    }

    private static func decodeStatus(_ data: [String: Any]) -> QuestionStatus {
        switch data["status"] as? String {
        case "answered":
            return .answered
        case "rallyActive":
            return .rallyActive(
                used: data["rallyUsed"] as? Int ?? 0,
                max: data["rallyMax"] as? Int ?? 0
            )
        default:
            return .waiting
        }
    }

    private static func decodeAnswerer(_ data: [String: Any]) -> AnswererPreview? {
        guard
            let userId = data["latestAnswererId"] as? String,
            let nickname = data["latestAnswererNickname"] as? String
        else {
            return nil
        }
        return AnswererPreview(
            userId: userId,
            nickname: nickname,
            rank: (data["latestAnswererRank"] as? String).flatMap(Rank.init(rawValue:))
        )
    }
}
