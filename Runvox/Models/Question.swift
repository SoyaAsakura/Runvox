import Foundation

/// 質問本体
struct Question: Identifiable, Equatable, Hashable {
    let id: String
    let askerId: String
    let askerNickname: String
    let category: QuestionCategory
    let title: String
    let body: String
    let status: QuestionStatus
    let createdAt: Date
    /// 一覧表示用に持つ「最新の回答者」プレビュー（なければ nil）
    let latestAnswerer: AnswererPreview?
    /// 最新回答の評価（1〜5、未評価なら nil）
    let latestRating: Int?
}

/// 一覧で表示する回答者の最小情報
struct AnswererPreview: Equatable, Hashable {
    let userId: String
    let nickname: String
    let rank: Rank?
}

// MARK: - Convenience

extension Question {
    /// 何分前 / 何時間前 / 何日前 の人間可読表現
    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// ステータスだけ差し替えた新しい Question を返す（immutable update）
    func with(status: QuestionStatus) -> Question {
        Question(
            id: id,
            askerId: askerId,
            askerNickname: askerNickname,
            category: category,
            title: title,
            body: body,
            status: status,
            createdAt: createdAt,
            latestAnswerer: latestAnswerer,
            latestRating: latestRating
        )
    }
}
