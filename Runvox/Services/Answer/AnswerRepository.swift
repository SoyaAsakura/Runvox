import Foundation

/// 回答データへのアクセス抽象化
protocol AnswerRepository: Sendable {
    /// 指定された質問に紐づく最新の回答を取得
    /// - Returns: 回答があれば返す、なければ nil
    func fetchLatestAnswer(questionId: String) async throws -> Answer?
}
