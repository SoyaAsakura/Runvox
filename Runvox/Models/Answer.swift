import Foundation

/// 質問への回答
struct Answer: Identifiable, Equatable, Hashable {
    let id: String
    let questionId: String
    let answererId: String
    let answererNickname: String
    let answererBio: String?
    let answererRank: Rank
    let answererStats: AnswererStats?
    let body: String
    let createdAt: Date
    /// 1〜5、未評価なら nil
    let rating: Int?

    /// 何分前 / 何時間前 / 何日前
    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

/// 一覧表示用の回答者統計
struct AnswererStats: Equatable, Hashable {
    let averageRating: Double
    let answerCount: Int
}

// MARK: - Mutations

extension Answer {
    /// 評価値だけ差し替えた新しい Answer を返す（immutable update）
    func with(rating: Int) -> Answer {
        Answer(
            id: id,
            questionId: questionId,
            answererId: answererId,
            answererNickname: answererNickname,
            answererBio: answererBio,
            answererRank: answererRank,
            answererStats: answererStats,
            body: body,
            createdAt: createdAt,
            rating: rating
        )
    }
}
