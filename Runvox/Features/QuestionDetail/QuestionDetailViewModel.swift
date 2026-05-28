import Foundation

/// 質問詳細画面の状態管理
@MainActor
final class QuestionDetailViewModel: ObservableObject {
    let question: Question
    @Published private(set) var answer: Answer?
    @Published private(set) var isLoadingAnswer: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: AnswerRepository

    init(question: Question, repository: AnswerRepository = MockAnswerRepository()) {
        self.question = question
        self.repository = repository
    }

    /// 質問ステータスから回答が存在する想定なら取得
    func loadAnswerIfNeeded() async {
        guard answer == nil,
              !isLoadingAnswer,
              shouldHaveAnswer else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    // MARK: - Derived state

    /// status が waiting 以外なら回答があるはず
    var shouldHaveAnswer: Bool {
        question.status != .waiting
    }

    /// 質問者は誰でも回答可能（MVP では回答者ロールゲート省略）
    /// 後で AuthService の currentUser と照合
    var canShowAnswerCTA: Bool {
        question.status == .waiting
    }

    /// 回答済みかつ未評価なら「評価する」CTA
    var canShowRateCTA: Bool {
        guard let answer else { return false }
        return answer.rating == nil
    }

    // MARK: - Rating

    /// 評価モーダルから受け取った結果で answer.rating を即時反映
    func applyRating(_ stars: Int) {
        guard let current = answer else { return }
        answer = current.with(rating: stars)
    }

    // MARK: - Private

    private func load() async {
        isLoadingAnswer = true
        errorMessage = nil
        defer { isLoadingAnswer = false }

        do {
            answer = try await repository.fetchLatestAnswer(questionId: question.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
