import FirebaseFirestore
import Foundation

/// Firestore による本番 AnswerRepository 実装
///
/// - コレクション: `answers`（トップレベル。`questionId` フィールドで質問に紐づく）
/// - `postAnswer` は Transaction で「同一 question への先着 1 名のみ成功」を原子的に保証する。
///   質問ドキュメントを読み、`status` が `waiting` でなければ `AnswerError.alreadyAnswered` を投げる。
///   成功時は answer ドキュメント作成 + 質問ドキュメントの `status` / `latestAnswerer` 更新を
///   同一 Transaction でまとめて行う。
/// - `fetchLatestAnswer` は `questionId` 一致 + `createdAt` 降順の複合インデックスが必要
///   （`firestore.indexes.json` 参照）。
final class FirestoreAnswerRepository: AnswerRepository {
    private var db: Firestore { Firestore.firestore() }
    private var answersCollection: CollectionReference { db.collection("answers") }
    private var questionsCollection: CollectionReference { db.collection("questions") }

    // MARK: - Fetch

    func fetchLatestAnswer(questionId: String) async throws -> Answer? {
        let snapshot = try await answersCollection
            .whereField("questionId", isEqualTo: questionId)
            .order(by: "createdAt", descending: true)
            .limit(to: 1)
            .getDocuments()

        guard let doc = snapshot.documents.first else { return nil }
        return Self.decode(doc.data(), id: doc.documentID)
    }

    // MARK: - Post（先着 1 名のみ成功する Transaction）

    func postAnswer(
        questionId: String,
        answerer: User,
        body: String
    ) async throws -> Answer {
        let questionRef = questionsCollection.document(questionId)
        let answerRef = answersCollection.document()
        let answer = Answer(
            id: answerRef.documentID,
            questionId: questionId,
            answererId: answerer.id,
            answererNickname: answerer.displayName,
            answererBio: answerer.bio,
            answererRank: answerer.rank ?? .b,
            answererStats: nil,
            body: body,
            createdAt: Date(),
            rating: nil
        )

        _ = try await db.runTransaction { transaction, errorPointer in
            let questionSnap: DocumentSnapshot
            do {
                questionSnap = try transaction.getDocument(questionRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard questionSnap.exists else {
                errorPointer?.pointee = AnswerError.questionNotFound as NSError
                return nil
            }

            // 先着判定: waiting 以外なら既に回答が付いている
            let status = questionSnap.data()?["status"] as? String ?? "waiting"
            guard status == "waiting" else {
                errorPointer?.pointee = AnswerError.alreadyAnswered as NSError
                return nil
            }

            transaction.setData(Self.encode(answer), forDocument: answerRef)
            transaction.updateData(
                [
                    "status": "answered",
                    "latestAnswererId": answer.answererId,
                    "latestAnswererNickname": answer.answererNickname,
                    "latestAnswererRank": answer.answererRank.rawValue,
                ],
                forDocument: questionRef
            )
            return nil
        }

        return answer
    }

    // MARK: - Firestore mapping

    private static func encode(_ answer: Answer) -> [String: Any] {
        [
            "questionId": answer.questionId,
            "answererId": answer.answererId,
            "answererNickname": answer.answererNickname,
            "answererBio": answer.answererBio ?? NSNull(),
            "answererRank": answer.answererRank.rawValue,
            "body": answer.body,
            "createdAt": Timestamp(date: answer.createdAt),
            "rating": answer.rating ?? NSNull(),
        ]
    }

    /// Firestore データ → Answer。必須項目が欠ける壊れたドキュメントは nil（読み飛ばす）。
    /// 回答者統計（answererStats）は集計の別関心事のため、ここでは nil とする。
    private static func decode(_ data: [String: Any], id: String) -> Answer? {
        guard
            let questionId = data["questionId"] as? String,
            let answererId = data["answererId"] as? String,
            let answererNickname = data["answererNickname"] as? String,
            let body = data["body"] as? String
        else {
            return nil
        }

        let rank = (data["answererRank"] as? String).flatMap(Rank.init(rawValue:)) ?? .b
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        return Answer(
            id: id,
            questionId: questionId,
            answererId: answererId,
            answererNickname: answererNickname,
            answererBio: data["answererBio"] as? String,
            answererRank: rank,
            answererStats: nil,
            body: body,
            createdAt: createdAt,
            rating: data["rating"] as? Int
        )
    }
}
