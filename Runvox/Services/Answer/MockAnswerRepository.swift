import Foundation

/// Firestore 統合前の開発用モック実装
final class MockAnswerRepository: AnswerRepository {
    private let simulatedLatency: Duration
    private let answers: [String: Answer]

    init(
        simulatedLatency: Duration = .milliseconds(300),
        answers: [String: Answer] = MockAnswerRepository.defaultAnswers
    ) {
        self.simulatedLatency = simulatedLatency
        self.answers = answers
    }

    func fetchLatestAnswer(questionId: String) async throws -> Answer? {
        try await Task.sleep(for: simulatedLatency)
        return answers[questionId]
    }

    func postAnswer(
        questionId: String,
        answerer: User,
        body: String
    ) async throws -> Answer {
        try await Task.sleep(for: simulatedLatency)
        // Mock では永続化せず、UUID 付き Answer を返すだけ
        // 呼び出し側 (QuestionDetailViewModel) が in-memory に反映する想定
        return Answer(
            id: UUID().uuidString,
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
    }

    // MARK: - Sample data

    static let defaultAnswers: [String: Answer] = [
        "q2": Answer(
            id: "a-q2-1",
            questionId: "q2",
            answererId: "a1",
            answererNickname: "田中健太コーチ",
            answererBio: "元実業団 / JAAF公認指導員",
            answererRank: .s,
            answererStats: AnswererStats(averageRating: 4.9, answerCount: 127),
            body: """
            シンスプリントが2ヶ月続いているのは、休養不足の可能性が高いです。
            一旦すべてのジョグを中止して 7〜10 日間完全休養を取りましょう。

            その間にできること:
            • アイシング (1 日 3 回 × 10 分)
            • ふくらはぎ・前脛骨筋のストレッチ
            • 体幹トレーニング (走らずに鍛えられる)

            痛みが消えたら 5 分のウォーキングから再開し、
            2 週間かけて 30 分ジョグまで戻します。
            """,
            createdAt: Date().addingTimeInterval(-30 * 60),
            rating: 5
        ),
        "q3": Answer(
            id: "a-q3-1",
            questionId: "q3",
            answererId: "a2",
            answererNickname: "佐藤RD",
            answererBio: "管理栄養士 / マラソンサブ3",
            answererRank: .a,
            answererStats: AnswererStats(averageRating: 4.6, answerCount: 48),
            body: """
            カーボローディングは本番 3 日前から始めるのが基本です。

            タイミング:
            • 3 日前〜前日: 普段の食事 + 炭水化物 60%
            • 前日夜: 軽めの和食 + 白米多め (脂質控えめ)
            • 当日朝 (3 時間前): おにぎり 2〜3 個 + バナナ

            前夜の食物繊維と脂質は最小限に。
            お腹のトラブルを避けるためです。
            """,
            createdAt: Date().addingTimeInterval(-90 * 60),
            rating: nil
        ),
        "q5": Answer(
            id: "a-q5-1",
            questionId: "q5",
            answererId: "a3",
            answererNickname: "yumi",
            answererBio: "市民ランナー / フル PB 3:45",
            answererRank: .b,
            answererStats: AnswererStats(averageRating: 4.2, answerCount: 12),
            body: """
            ITバンド炎症のテーピングは、膝外側の引っ張りを抑えるのがコツです。

            キネシオテープを使う場合:
            1. 膝のお皿の少し上から外側に向けて 1 本
            2. お皿の外側下から斜め上へ 1 本
            3. テンションは 30% 程度

            根本対策として、お尻 (中殿筋) の強化も並行してください。
            横向きで脚を上げ下げするクラムシェルが効きます。
            """,
            createdAt: Date().addingTimeInterval(-22 * 60 * 60),
            rating: 4
        ),
    ]
}
