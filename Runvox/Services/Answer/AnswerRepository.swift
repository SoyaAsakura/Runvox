import Foundation

/// 回答データへのアクセス抽象化
protocol AnswerRepository: Sendable {
    /// 指定された質問に紐づく最新の回答を取得
    /// - Returns: 回答があれば返す、なければ nil
    func fetchLatestAnswer(questionId: String) async throws -> Answer?

    /// 質問への回答を投稿する
    ///
    /// 本番（Firestore）では Transaction で「同一 question_id への先着 1 名のみ成功」を
    /// 原子的に保証する。Mock では常に成功する。
    func postAnswer(
        questionId: String,
        answerer: User,
        body: String
    ) async throws -> Answer
}
