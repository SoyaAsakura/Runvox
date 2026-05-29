import Foundation

/// Firestore 統合前の開発用モック実装
///
/// - 固定のサンプル質問データを返す
/// - simulatedLatency で API 遅延をシミュレート
/// - "network" カテゴリを渡すとネットワークエラーを投げる（テスト用）
final class MockQuestionRepository: QuestionRepository {
    private let simulatedLatency: Duration
    private let sampleQuestions: [Question]

    init(
        simulatedLatency: Duration = .milliseconds(400),
        sampleQuestions: [Question] = MockQuestionRepository.defaultSamples
    ) {
        self.simulatedLatency = simulatedLatency
        self.sampleQuestions = sampleQuestions
    }

    func fetchQuestions(
        category: QuestionCategory?,
        limit: Int
    ) async throws -> [Question] {
        try await Task.sleep(for: simulatedLatency)
        let filtered = category.map { cat in
            sampleQuestions.filter { $0.category == cat }
        } ?? sampleQuestions
        return Array(filtered.prefix(limit))
    }

    func createQuestion(_ draft: NewQuestionDraft) async throws -> Question {
        try await Task.sleep(for: simulatedLatency)
        // Mock では永続化せず、UUID 付きで Question を返すだけ
        // 呼び出し側 (HomeViewModel) が in-memory に追加する想定
        return Question(
            id: UUID().uuidString,
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
    }

    func searchQuestions(query: String, limit: Int) async throws -> [Question] {
        try await Task.sleep(for: simulatedLatency)
        let lowered = query.lowercased()
        guard !lowered.isEmpty else { return [] }
        let matched = sampleQuestions.filter {
            $0.title.lowercased().contains(lowered)
                || $0.body.lowercased().contains(lowered)
        }
        return Array(matched.prefix(limit))
    }

    // MARK: - Sample data

    static let defaultSamples: [Question] = [
        Question(
            id: "q1",
            askerId: "u1",
            askerNickname: "ランナー太郎",
            category: .training,
            title: "サブ3.5を狙うための30km走の頻度は？週何回が適切でしょうか",
            body: "現在ハーフ1:35。秋のフルマラソン本番に向けて30km走を取り入れたいです。",
            status: .waiting,
            createdAt: Date().addingTimeInterval(-12 * 60),
            latestAnswerer: nil,
            latestRating: nil
        ),
        Question(
            id: "q2",
            askerId: "u2",
            askerNickname: "ヨウコ",
            category: .injuryPrevention,
            title: "シンスプリントが2ヶ月治りません。ランオフの判断は？",
            body: "週3回ジョグしてますが、ずっと痛みが取れません。",
            status: .answered,
            createdAt: Date().addingTimeInterval(-2 * 60 * 60),
            latestAnswerer: AnswererPreview(userId: "a1", nickname: "田中コーチ", rank: .s),
            latestRating: 5
        ),
        Question(
            id: "q3",
            askerId: "u3",
            askerNickname: "ぐっち",
            category: .nutrition,
            title: "フルマラソン前夜の食事、カーボローディングは何時間前から？",
            body: "本番3週間前です。前日と当日朝の食事タイミング教えてください。",
            status: .rallyActive(used: 1, max: 1),
            createdAt: Date().addingTimeInterval(-2 * 60 * 60),
            latestAnswerer: AnswererPreview(userId: "a2", nickname: "佐藤RD", rank: .a),
            latestRating: nil
        ),
        Question(
            id: "q4",
            askerId: "u4",
            askerNickname: "Nori",
            category: .race,
            title: "湘南国際マラソン2026のエントリー戦略を教えてください",
            body: "去年抽選漏れました。今年こそ走りたい。",
            status: .waiting,
            createdAt: Date().addingTimeInterval(-4 * 60 * 60),
            latestAnswerer: nil,
            latestRating: nil
        ),
        Question(
            id: "q5",
            askerId: "u5",
            askerNickname: "yumi",
            category: .injuryPrevention,
            title: "ITバンド炎症のテーピング方法",
            body: "下りで膝外側が痛みます。テーピングで対処できますか？",
            status: .answered,
            createdAt: Date().addingTimeInterval(-1 * 24 * 60 * 60),
            latestAnswerer: AnswererPreview(userId: "a3", nickname: "yumi", rank: .b),
            latestRating: 4
        ),
        Question(
            id: "q6",
            askerId: "u6",
            askerNickname: "ramen太",
            category: .gear,
            title: "厚底シューズのローテーション、何足必要？",
            body: "練習用とレース用で分けるべきでしょうか",
            status: .waiting,
            createdAt: Date().addingTimeInterval(-2 * 24 * 60 * 60),
            latestAnswerer: nil,
            latestRating: nil
        ),
    ]
}
