@testable import Runvox
import XCTest

@MainActor
final class ProfileEditViewModelTests: XCTestCase {
    private func makeAuth(user: User) -> AuthService {
        AuthService.previewSignedIn(user, latency: .milliseconds(0))
    }

    private func questioner() -> User {
        User(
            id: "u1", email: "me@example.com", nickname: "太郎",
            bio: "走るのが好き", role: .questioner
        )
    }

    private func bRankAnswerer() -> User {
        User(
            id: "u2", email: "b@example.com", nickname: "yumi",
            bio: nil, role: .answerer, rank: .b, isAnonymous: true
        )
    }

    private func sRankAnswerer() -> User {
        User(
            id: "u3", email: "s@example.com", nickname: "田中",
            realName: "田中 健太", bio: "コーチ", role: .answerer, rank: .s
        )
    }

    // MARK: - Init prefill

    func test_init_prefillsFromCurrentUser() {
        let vm = ProfileEditViewModel(auth: makeAuth(user: questioner()))
        XCTAssertEqual(vm.nickname, "太郎")
        XCTAssertEqual(vm.bio, "走るのが好き")
        XCTAssertEqual(vm.email, "me@example.com")
        XCTAssertFalse(vm.canToggleAnonymous, "質問者は匿名トグルなし")
    }

    func test_init_bRankCanToggleAnonymous() {
        let vm = ProfileEditViewModel(auth: makeAuth(user: bRankAnswerer()))
        XCTAssertTrue(vm.canToggleAnonymous)
        XCTAssertTrue(vm.isAnonymous)
    }

    func test_init_sRankCannotToggleAnonymous() {
        let vm = ProfileEditViewModel(auth: makeAuth(user: sRankAnswerer()))
        XCTAssertFalse(vm.canToggleAnonymous, "S ランクは実名必須なので匿名トグルなし")
    }

    // MARK: - canSave

    func test_canSave_falseWhenNicknameEmpty() {
        let vm = ProfileEditViewModel(auth: makeAuth(user: questioner()))
        vm.nickname = "   "
        XCTAssertFalse(vm.canSave)
    }

    func test_canSave_falseWhenBioTooLong() {
        let vm = ProfileEditViewModel(auth: makeAuth(user: questioner()))
        vm.bio = String(repeating: "あ", count: ProfileEditViewModel.maxBioLength + 1)
        XCTAssertFalse(vm.canSave)
    }

    // MARK: - Save

    func test_save_updatesAuthCurrentUser() async {
        let auth = makeAuth(user: questioner())
        let vm = ProfileEditViewModel(auth: auth)
        vm.nickname = "新ニックネーム"
        vm.bio = "プロフィール更新しました"

        let ok = await vm.save()
        XCTAssertTrue(ok)
        XCTAssertEqual(auth.currentUser?.nickname, "新ニックネーム")
        XCTAssertEqual(auth.currentUser?.bio, "プロフィール更新しました")
    }

    func test_save_emptyBioBecomesNil() async {
        let auth = makeAuth(user: questioner())
        let vm = ProfileEditViewModel(auth: auth)
        vm.bio = ""

        let ok = await vm.save()
        XCTAssertTrue(ok)
        XCTAssertNil(auth.currentUser?.bio)
    }

    func test_save_invalidNicknameSetsError() async {
        let auth = makeAuth(user: questioner())
        let vm = ProfileEditViewModel(auth: auth)
        vm.nickname = "a"  // 2 文字未満

        let ok = await vm.save()
        XCTAssertFalse(ok)
        XCTAssertNotNil(vm.nicknameError)
    }

    func test_save_duplicateNicknameSetsError() async {
        let auth = makeAuth(user: questioner())
        let vm = ProfileEditViewModel(auth: auth)
        vm.nickname = "taken"  // Mock が nicknameAlreadyTaken を返す

        let ok = await vm.save()
        XCTAssertFalse(ok)
        XCTAssertNotNil(vm.nicknameError)
    }

    func test_save_bRankPersistsAnonymous() async {
        let auth = makeAuth(user: bRankAnswerer())
        let vm = ProfileEditViewModel(auth: auth)
        vm.isAnonymous = false

        let ok = await vm.save()
        XCTAssertTrue(ok)
        XCTAssertEqual(auth.currentUser?.isAnonymous, false)
    }

    func test_save_nonToggleableRoleForcesAnonymousFalse() async {
        // S ランクは canToggleAnonymous=false なので保存時 isAnonymous は false 固定
        let auth = makeAuth(user: sRankAnswerer())
        let vm = ProfileEditViewModel(auth: auth)
        vm.isAnonymous = true  // UI 上は出ないが念のため

        let ok = await vm.save()
        XCTAssertTrue(ok)
        XCTAssertEqual(auth.currentUser?.isAnonymous, false)
    }
}
