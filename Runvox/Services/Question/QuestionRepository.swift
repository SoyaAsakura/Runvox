import Foundation

/// 新規質問投稿用のドラフト
struct NewQuestionDraft: Equatable {
    let askerId: String
    let askerNickname: String
    let category: QuestionCategory
    let title: String
    let body: String
}

/// 質問データへのアクセス抽象化
///
/// 後で `FirestoreQuestionRepository` に差し替える
protocol QuestionRepository: Sendable {
    /// 質問一覧を取得
    /// - Parameters:
    ///   - category: フィルタ対象のカテゴリ。nil で全件
    ///   - limit: 最大取得件数
    func fetchQuestions(
        category: QuestionCategory?,
        limit: Int
    ) async throws -> [Question]

    /// 質問を新規作成
    func createQuestion(_ draft: NewQuestionDraft) async throws -> Question

    /// キーワードで質問を検索（タイトル + 本文の部分一致）
    func searchQuestions(query: String, limit: Int) async throws -> [Question]
}
