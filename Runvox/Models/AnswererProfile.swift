import Foundation

/// 回答者プロフィール（一般公開ビュー）
struct AnswererProfile: Identifiable, Equatable {
    let user: User
    let achievements: [String]
    let coachingYears: Int?
    let specialtyTags: [String]
    let stats: AnswererStats?
    let recentAnswers: [AnswerSummary]

    var id: String { user.id }
}

/// プロフィールの「最近の回答」用のサマリ
struct AnswerSummary: Identifiable, Equatable, Hashable {
    let id: String                  // answer id
    let questionTitle: String
    let rating: Int?
    let createdAt: Date

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: createdAt)
    }
}
