import Foundation

/// 質問投稿画面の状態管理
@MainActor
final class PostQuestionViewModel: ObservableObject {
    // MARK: - Inputs

    @Published var selectedCategory: QuestionCategory?
    @Published var title: String = ""
    @Published var body: String = ""

    // MARK: - Validation state

    @Published private(set) var titleError: String?
    @Published private(set) var bodyError: String?
    @Published private(set) var categoryError: String?
    @Published private(set) var generalError: String?

    // MARK: - Submission state

    @Published private(set) var isSubmitting: Bool = false

    // MARK: - Configuration

    static let titleLimit = 60
    static let bodyLimit = 1000

    private let asker: User
    private let repository: QuestionRepository

    init(asker: User, repository: QuestionRepository = RepositoryFactory.makeQuestionRepository()) {
        self.asker = asker
        self.repository = repository
    }

    // MARK: - Derived state

    var titleCharCount: Int { title.count }
    var bodyCharCount: Int { body.count }

    var canSubmit: Bool {
        selectedCategory != nil
            && !title.trimmingCharacters(in: .whitespaces).isEmpty
            && title.count <= Self.titleLimit
            && body.count <= Self.bodyLimit
            && !isSubmitting
    }

    // MARK: - Actions

    /// 投稿実行。成功した Question を返す。失敗時は nil で errorMessage がセットされる
    func submit() async -> Question? {
        clearErrors()

        guard validate() else { return nil }
        guard let category = selectedCategory else { return nil }

        isSubmitting = true
        defer { isSubmitting = false }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedBody = body.trimmingCharacters(in: .whitespaces)

        let draft = NewQuestionDraft(
            askerId: asker.id,
            askerNickname: asker.nickname,
            category: category,
            title: trimmedTitle,
            body: trimmedBody
        )

        do {
            return try await repository.createQuestion(draft)
        } catch {
            generalError = error.localizedDescription
            return nil
        }
    }

    // MARK: - Private

    private func clearErrors() {
        titleError = nil
        bodyError = nil
        categoryError = nil
        generalError = nil
    }

    private func validate() -> Bool {
        var ok = true

        if selectedCategory == nil {
            categoryError = "カテゴリを選択してください"
            ok = false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        if trimmedTitle.isEmpty {
            titleError = "タイトルを入力してください"
            ok = false
        } else if trimmedTitle.count > Self.titleLimit {
            titleError = "タイトルは \(Self.titleLimit) 文字以内にしてください"
            ok = false
        }

        if body.count > Self.bodyLimit {
            bodyError = "本文は \(Self.bodyLimit) 文字以内にしてください"
            ok = false
        }

        return ok
    }
}
