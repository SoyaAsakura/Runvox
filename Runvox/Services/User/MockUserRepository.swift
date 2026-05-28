import Foundation

/// Firestore 統合前の開発用モック実装
///
/// MockAnswerRepository が返す 3 名の回答者（a1, a2, a3）に対応した
/// プロフィールを返す。それ以外の id は nil。
final class MockUserRepository: UserRepository {
    private let simulatedLatency: Duration
    private let profiles: [String: AnswererProfile]

    init(
        simulatedLatency: Duration = .milliseconds(400),
        profiles: [String: AnswererProfile] = MockUserRepository.defaultProfiles
    ) {
        self.simulatedLatency = simulatedLatency
        self.profiles = profiles
    }

    func fetchAnswererProfile(userId: String) async throws -> AnswererProfile? {
        try await Task.sleep(for: simulatedLatency)
        return profiles[userId]
    }

    // MARK: - Sample profiles

    static let defaultProfiles: [String: AnswererProfile] = [
        "a1": AnswererProfile(
            user: User(
                id: "a1",
                email: "tanaka@runvox.app",
                nickname: "田中健太コーチ",
                realName: "田中 健太",
                bio: "元実業団選手 / JAAF公認指導員。市民ランナーのサブ3達成を100名超サポート。",
                role: .answerer,
                rank: .s,
                isAnonymous: false
            ),
            achievements: [
                "東京マラソン 2:18:42（自己ベスト）",
                "全日本実業団 5000m 入賞",
                "JAAF ジュニア指導 5年",
                "市民ランナー サブ3 達成サポート 100名超",
            ],
            coachingYears: 12,
            specialtyTags: ["#サブ3", "#インターバル", "#LSD", "#ペース戦略", "#故障予防"],
            stats: AnswererStats(averageRating: 4.9, answerCount: 127),
            recentAnswers: [
                MockUserRepository.summary("a-q2-1", "シンスプリントが治らない時の対処法", 5, daysAgo: 1),
                MockUserRepository.summary("a-old-1", "30km走の頻度は週何回が適切？", 5, daysAgo: 4),
                MockUserRepository.summary("a-old-2", "シューズローテーションの考え方", 4, daysAgo: 7),
            ]
        ),
        "a2": AnswererProfile(
            user: User(
                id: "a2",
                email: "sato@runvox.app",
                nickname: "佐藤RD",
                realName: "佐藤 美穂",
                bio: "管理栄養士 / マラソンサブ3。スポーツ栄養学を実践レベルで解説。",
                role: .answerer,
                rank: .a,
                isAnonymous: false
            ),
            achievements: [
                "管理栄養士",
                "湘南国際マラソン 2:58:30",
                "アスリート向け栄養指導 60名",
            ],
            coachingYears: 5,
            specialtyTags: ["#栄養", "#カーボローディング", "#リカバリー食"],
            stats: AnswererStats(averageRating: 4.6, answerCount: 48),
            recentAnswers: [
                MockUserRepository.summary("a-q3-1", "カーボローディングは何時間前から？", nil, hoursAgo: 2),
                MockUserRepository.summary("a-old-3", "練習後の食事タイミング", 5, daysAgo: 10),
            ]
        ),
        "a3": AnswererProfile(
            user: User(
                id: "a3",
                email: "yumi@example.com",
                nickname: "yumi",
                realName: nil,
                bio: "市民ランナー / フル PB 3:45。仲間のサポートが好き。",
                role: .answerer,
                rank: .b,
                isAnonymous: true
            ),
            achievements: [
                "フルマラソン PB 3:45:12",
                "ハーフ PB 1:42:30",
            ],
            coachingYears: nil,
            specialtyTags: ["#テーピング", "#ITバンド"],
            stats: AnswererStats(averageRating: 4.2, answerCount: 12),
            recentAnswers: [
                MockUserRepository.summary("a-q5-1", "ITバンド炎症のテーピング方法", 4, hoursAgo: 22),
            ]
        ),
    ]

    // MARK: - Builder helpers

    private static func summary(
        _ id: String,
        _ title: String,
        _ rating: Int?,
        daysAgo: Int = 0,
        hoursAgo: Int = 0
    ) -> AnswerSummary {
        let interval = TimeInterval(-(daysAgo * 24 * 3600 + hoursAgo * 3600))
        return AnswerSummary(
            id: id,
            questionTitle: title,
            rating: rating,
            createdAt: Date().addingTimeInterval(interval)
        )
    }
}
