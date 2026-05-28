import Foundation

/// ホーム画面（質問一覧）の状態管理
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var questions: [Question] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published var selectedCategory: QuestionCategory?

    private let repository: QuestionRepository
    private let pageLimit: Int

    init(
        repository: QuestionRepository = MockQuestionRepository(),
        pageLimit: Int = 20
    ) {
        self.repository = repository
        self.pageLimit = pageLimit
    }

    /// 初回ロード（既にデータがある場合はスキップ）
    func loadIfNeeded() async {
        guard questions.isEmpty, !isLoading else { return }
        await load()
    }

    /// プルtoリフレッシュ
    func refresh() async {
        await load()
    }

    /// カテゴリ選択変更（再フェッチ）
    func selectCategory(_ category: QuestionCategory?) async {
        guard selectedCategory != category else { return }
        selectedCategory = category
        await load()
    }

    // MARK: - Private

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let fetched = try await repository.fetchQuestions(
                category: selectedCategory,
                limit: pageLimit
            )
            questions = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
