import Foundation

/// プロフィール編集画面の状態管理
@MainActor
final class ProfileEditViewModel: ObservableObject {
    @Published var nickname: String
    @Published var bio: String
    @Published var isAnonymous: Bool

    @Published private(set) var nicknameError: String?
    @Published private(set) var generalError: String?
    @Published private(set) var isSaving: Bool = false

    /// 編集不可で表示するだけ
    let email: String
    /// 匿名トグルを出すか（B ランク回答者のみ。S/A は実名公開必須）
    let canToggleAnonymous: Bool

    static let maxBioLength = 200

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
        let user = auth.currentUser
        self.nickname = user?.nickname ?? ""
        self.bio = user?.bio ?? ""
        self.isAnonymous = user?.isAnonymous ?? false
        self.email = user?.email ?? ""
        self.canToggleAnonymous = (user?.role == .answerer && user?.rank == .b)
    }

    var bioCharCount: Int { bio.count }

    var canSave: Bool {
        !nickname.trimmingCharacters(in: .whitespaces).isEmpty
            && bio.count <= Self.maxBioLength
            && !isSaving
    }

    /// 保存。成功で true。
    func save() async -> Bool {
        nicknameError = nil
        generalError = nil

        switch AuthValidator.validateNickname(nickname) {
        case .failure(let error):
            nicknameError = error.errorDescription
            return false
        case .success:
            break
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await auth.updateProfile(
                nickname: nickname,
                bio: bio.isEmpty ? nil : bio,
                isAnonymous: canToggleAnonymous ? isAnonymous : false
            )
            return true
        } catch let error as AuthError {
            switch error {
            case .invalidNickname, .nicknameAlreadyTaken:
                nicknameError = error.errorDescription
            default:
                generalError = error.errorDescription
            }
            return false
        } catch {
            generalError = error.localizedDescription
            return false
        }
    }
}
