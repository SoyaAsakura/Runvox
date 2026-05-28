@testable import Runvox
import XCTest

@MainActor
final class PostAnswerViewModelTests: XCTestCase {
    // MARK: - Helpers

    private let sampleQuestion = MockQuestionRepository.defaultSamples[0]   // q1 waiting

    private func makeAnswerer(rank: Rank? = .s) -> User {
        User(
            id: "u-me",
            email: "me@example.com",
            nickname: "テスト回答者",
            realName: "回答 太郎",
            bio: "テストです",
            role: .answerer,
            rank: rank
        )
    }

    private func makeVM(rank: Rank? = .s) -> PostAnswerViewModel {
        PostAnswerViewModel(
            question: sampleQuestion,
            answerer: makeAnswerer(rank: rank),
            repository: MockAnswerRepository(simulatedLatency: .milliseconds(0))
        )
    }

    // MARK: - Initial state

    func test_initialState() {
        let vm = makeVM()
        XCTAssertEqual(vm.body, "")
        XCTAssertFalse(vm.isSubmitting)
        XCTAssertFalse(vm.canSubmit)
        XCTAssertEqual(vm.effectiveRank, .s)
    }

    // MARK: - effectiveRank fallback

    func test_effectiveRank_fallsBackToBWhenNil() {
        let vm = makeVM(rank: nil)
        XCTAssertEqual(vm.effectiveRank, .b)
    }

    // MARK: - maxPossiblePoints

    func test_maxPossiblePoints_isStar5TimesRankMultiplier() {
        XCTAssertEqual(makeVM(rank: .s).maxPossiblePoints, 500)
        XCTAssertEqual(makeVM(rank: .a).maxPossiblePoints, 375)
        XCTAssertEqual(makeVM(rank: .b).maxPossiblePoints, 250)
    }

    // MARK: - canSubmit

    func test_canSubmit_falseWhenTooShort() {
        let vm = makeVM()
        vm.body = "短い"
        XCTAssertLessThan(vm.body.count, PostAnswerViewModel.minBodyLength)
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_trueWhenLongEnough() {
        let vm = makeVM()
        vm.body = "これは十分な長さの回答本文です"
        XCTAssertGreaterThanOrEqual(vm.body.count, PostAnswerViewModel.minBodyLength)
        XCTAssertTrue(vm.canSubmit)
    }

    func test_canSubmit_falseWhenWhitespaceOnly() {
        let vm = makeVM()
        vm.body = "           "
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_falseWhenOverLimit() {
        let vm = makeVM()
        vm.body = String(repeating: "あ", count: PostAnswerViewModel.bodyLimit + 1)
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: - Submit

    func test_submit_returnsAnswerOnSuccess() async throws {
        let vm = makeVM(rank: .a)
        vm.body = "これは十分に長い、ちゃんとした回答本文です。"

        let optional = await vm.submit()
        let answer = try XCTUnwrap(optional)
        XCTAssertEqual(answer.questionId, sampleQuestion.id)
        XCTAssertEqual(answer.answererId, "u-me")
        XCTAssertEqual(answer.answererRank, .a)
        XCTAssertNil(answer.rating)
        XCTAssertNil(vm.errorMessage)
    }

    func test_submit_trimsWhitespace() async throws {
        let vm = makeVM()
        vm.body = "   これは十分な長さの回答本文です。  \n"

        let optional = await vm.submit()
        let answer = try XCTUnwrap(optional)
        XCTAssertEqual(answer.body, "これは十分な長さの回答本文です。")
    }

    func test_submit_returnsNilWhenNotSubmittable() async {
        let vm = makeVM()
        vm.body = "短"

        let result = await vm.submit()
        XCTAssertNil(result)
    }

    // MARK: - QuestionDetailViewModel.applyNewAnswer

    func test_applyNewAnswer_setsAnswerAndUpdatesStatus() async {
        let detailVM = QuestionDetailViewModel(
            question: sampleQuestion,
            repository: MockAnswerRepository(simulatedLatency: .milliseconds(0))
        )
        XCTAssertEqual(detailVM.question.status, .waiting)
        XCTAssertTrue(detailVM.canShowAnswerCTA)

        let newAnswer = Answer(
            id: "new-1",
            questionId: sampleQuestion.id,
            answererId: "u-me",
            answererNickname: "テスト",
            answererBio: nil,
            answererRank: .s,
            answererStats: nil,
            body: "新規回答",
            createdAt: Date(),
            rating: nil
        )
        detailVM.applyNewAnswer(newAnswer)

        XCTAssertEqual(detailVM.answer?.id, "new-1")
        XCTAssertEqual(detailVM.question.status, .answered)
        XCTAssertFalse(detailVM.canShowAnswerCTA, "回答CTA は消えるはず")
        XCTAssertTrue(detailVM.canShowRateCTA, "新規回答は未評価なので評価CTA が出るはず")
    }

    // MARK: - Question.with(status:)

    func test_questionWithStatus_replacesStatusOnly() {
        let original = sampleQuestion
        let updated = original.with(status: .answered)
        XCTAssertEqual(updated.status, .answered)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.title, original.title)
        XCTAssertEqual(updated.category, original.category)
    }
}
