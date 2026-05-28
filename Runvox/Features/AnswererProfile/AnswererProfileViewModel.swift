import Foundation

/// 回答者プロフィール画面の状態管理
@MainActor
final class AnswererProfileViewModel: ObservableObject {
    @Published private(set) var profile: AnswererProfile?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private let userId: String
    private let repository: UserRepository

    init(userId: String, repository: UserRepository = MockUserRepository()) {
        self.userId = userId
        self.repository = repository
    }

    func loadIfNeeded() async {
        guard profile == nil, !isLoading else { return }
        await load()
    }

    func retry() async {
        await load()
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            profile = try await repository.fetchAnswererProfile(userId: userId)
            if profile == nil {
                errorMessage = "プロフィールが見つかりませんでした"
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
