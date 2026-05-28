@testable import Runvox
import XCTest

@MainActor
final class PostQuestionViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(
        asker: User = .preview
    ) -> PostQuestionViewModel {
        PostQuestionViewModel(
            asker: asker,
            repository: MockQuestionRepository(simulatedLatency: .milliseconds(0))
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM()
        XCTAssertNil(vm.selectedCategory)
        XCTAssertEqual(vm.title, "")
        XCTAssertEqual(vm.body, "")
        XCTAssertFalse(vm.isSubmitting)
        XCTAssertFalse(vm.canSubmit, "Initial state should not be submittable")
    }

    // MARK: - canSubmit

    func test_canSubmit_requiresAllFields() {
        let vm = makeVM()

        vm.selectedCategory = .training
        XCTAssertFalse(vm.canSubmit, "still missing title")

        vm.title = "サブ3.5を狙うための練習法"
        XCTAssertTrue(vm.canSubmit, "title + category is enough; body is optional")
    }

    func test_canSubmit_falseWhenTitleTooLong() {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = String(repeating: "あ", count: PostQuestionViewModel.titleLimit + 1)
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_falseWhenBodyTooLong() {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = "テスト"
        vm.body = String(repeating: "a", count: PostQuestionViewModel.bodyLimit + 1)
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_falseWhenTitleOnlyWhitespace() {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = "   "
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: - Submit

    func test_submit_successReturnsQuestion() async {
        let vm = makeVM()
        vm.selectedCategory = .training
        vm.title = "テスト質問"
        vm.body = "テスト本文"

        let result = await vm.submit()
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.category, .training)
        XCTAssertEqual(result?.title, "テスト質問")
        XCTAssertEqual(result?.body, "テスト本文")
        XCTAssertEqual(result?.status, .waiting)
        XCTAssertNil(vm.generalError)
    }

    func test_submit_trimsWhitespace() async {
        let vm = makeVM()
        vm.selectedCategory = .nutrition
        vm.title = "  前後にスペース  "
        vm.body = "  本文も  "

        let result = await vm.submit()
        XCTAssertEqual(result?.title, "前後にスペース")
        XCTAssertEqual(result?.body, "本文も")
    }

    func test_submit_failsWhenCategoryNotSelected() async {
        let vm = makeVM()
        vm.title = "タイトル"

        let result = await vm.submit()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.categoryError)
    }

    func test_submit_failsWhenTitleEmpty() async {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = ""

        let result = await vm.submit()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.titleError)
    }

    func test_submit_failsWhenTitleOverLimit() async {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = String(repeating: "あ", count: PostQuestionViewModel.titleLimit + 1)

        let result = await vm.submit()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.titleError)
    }

    func test_submit_failsWhenBodyOverLimit() async {
        let vm = makeVM()
        vm.selectedCategory = .race
        vm.title = "ok"
        vm.body = String(repeating: "a", count: PostQuestionViewModel.bodyLimit + 1)

        let result = await vm.submit()
        XCTAssertNil(result)
        XCTAssertNotNil(vm.bodyError)
    }

    func test_submit_clearsPreviousErrorsOnSuccess() async {
        let vm = makeVM()
        // 1 回目: バリデーション失敗
        _ = await vm.submit()
        XCTAssertNotNil(vm.titleError)
        XCTAssertNotNil(vm.categoryError)

        // 2 回目: 正しく入力して成功
        vm.selectedCategory = .training
        vm.title = "正しい質問"
        _ = await vm.submit()
        XCTAssertNil(vm.titleError)
        XCTAssertNil(vm.categoryError)
    }

    // MARK: - HomeViewModel.prepend

    func test_homeViewModelPrepend_addsToTop() async {
        let home = HomeViewModel(
            repository: MockQuestionRepository(simulatedLatency: .milliseconds(0))
        )
        await home.loadIfNeeded()
        let originalCount = home.questions.count

        let newQuestion = Question(
            id: "new",
            askerId: "u",
            askerNickname: "新規",
            category: .training,
            title: "新しい質問",
            body: "",
            status: .waiting,
            createdAt: Date(),
            latestAnswerer: nil,
            latestRating: nil
        )
        home.prepend(newQuestion)

        XCTAssertEqual(home.questions.count, originalCount + 1)
        XCTAssertEqual(home.questions.first?.id, "new")
    }

    func test_homeViewModelPrepend_skipsIfCategoryMismatch() async {
        let home = HomeViewModel(
            repository: MockQuestionRepository(simulatedLatency: .milliseconds(0))
        )
        await home.loadIfNeeded()
        await home.selectCategory(.race)
        let originalCount = home.questions.count

        // race フィルタ中に training の質問は追加されない
        let newQuestion = Question(
            id: "skip",
            askerId: "u",
            askerNickname: "新規",
            category: .training,
            title: "ミスマッチ",
            body: "",
            status: .waiting,
            createdAt: Date(),
            latestAnswerer: nil,
            latestRating: nil
        )
        home.prepend(newQuestion)

        XCTAssertEqual(home.questions.count, originalCount)
    }
}
