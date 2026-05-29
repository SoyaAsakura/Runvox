import Foundation

/// 検索画面の状態管理
///
/// デバウンスは View 側（onChange + Task.sleep）で行い、
/// この ViewModel の `search()` は決定的（テストしやすい）にする。
@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published private(set) var results: [Question] = []
    @Published private(set) var isSearching: Bool = false
    @Published private(set) var errorMessage: String?
    /// 一度でも検索を実行したか（初期状態 vs 0 件 の区別用）
    @Published private(set) var hasSearched: Bool = false

    private let repository: QuestionRepository
    private let limit: Int

    init(repository: QuestionRepository = MockQuestionRepository(), limit: Int = 50) {
        self.repository = repository
        self.limit = limit
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    /// 現在の query で検索を実行
    func search() async {
        let q = trimmedQuery
        guard !q.isEmpty else {
            results = []
            hasSearched = false
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            results = try await repository.searchQuestions(query: q, limit: limit)
            hasSearched = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() {
        query = ""
        results = []
        hasSearched = false
        errorMessage = nil
    }
}
