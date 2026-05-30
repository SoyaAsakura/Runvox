import Foundation

/// 回答投稿画面の状態管理
@MainActor
final class PostAnswerViewModel: ObservableObject {
    let question: Question
    let answerer: User

    @Published var body: String = ""
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: AnswerRepository

    // MARK: - Configuration

    static let minBodyLength = 10
    static let bodyLimit = 2000

    init(
        question: Question,
        answerer: User,
        repository: AnswerRepository = RepositoryFactory.makeAnswerRepository()
    ) {
        self.question = question
        self.answerer = answerer
        self.repository = repository
    }

    // MARK: - Derived state

    var trimmedBodyLength: Int {
        body.trimmingCharacters(in: .whitespacesAndNewlines).count
    }

    var bodyCharCount: Int { body.count }

    var canSubmit: Bool {
        trimmedBodyLength >= Self.minBodyLength
            && body.count <= Self.bodyLimit
            && !isSubmitting
    }

    /// MVP: rank が未設定なら B として扱う
    var effectiveRank: Rank {
        answerer.rank ?? .b
    }

    var maxPossiblePoints: Int {
        PointCalculator.calculate(stars: 5, rank: effectiveRank)
    }

    // MARK: - Submit

    func submit() async -> Answer? {
        guard canSubmit else { return nil }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            return try await repository.postAnswer(
                questionId: question.id,
                answerer: answerer,
                body: trimmed
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
