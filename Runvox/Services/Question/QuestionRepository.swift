import Foundation

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
}
