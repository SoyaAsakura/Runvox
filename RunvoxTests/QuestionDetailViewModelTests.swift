@testable import Runvox
import XCTest

@MainActor
final class QuestionDetailViewModelTests: XCTestCase {
    // MARK: - Helpers

    private let waitingQuestion = MockQuestionRepository.defaultSamples[0]   // q1 (waiting)
    private let ratedQuestion = MockQuestionRepository.defaultSamples[1]     // q2 (answered, rated)
    private let unratedQuestion = MockQuestionRepository.defaultSamples[2]   // q3 (rally, unrated)

    private func makeVM(
        question: Question,
        answers: [String: Answer] = MockAnswerRepository.defaultAnswers
    ) -> QuestionDetailViewModel {
        QuestionDetailViewModel(
            question: question,
            repository: MockAnswerRepository(
                simulatedLatency: .milliseconds(0),
                answers: answers
            )
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM(question: ratedQuestion)
        XCTAssertNil(vm.answer)
        XCTAssertFalse(vm.isLoadingAnswer)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Should-have-answer derivation

    func test_shouldHaveAnswer_falseForWaiting() {
        let vm = makeVM(question: waitingQuestion)
        XCTAssertFalse(vm.shouldHaveAnswer)
    }

    func test_shouldHaveAnswer_trueForAnswered() {
        let vm = makeVM(question: ratedQuestion)
        XCTAssertTrue(vm.shouldHaveAnswer)
    }

    func test_shouldHaveAnswer_trueForRallyActive() {
        let vm = makeVM(question: unratedQuestion)
        XCTAssertTrue(vm.shouldHaveAnswer)
    }

    // MARK: - CTA derivation

    func test_canShowAnswerCTA_trueOnlyForWaiting() {
        XCTAssertTrue(makeVM(question: waitingQuestion).canShowAnswerCTA)
        XCTAssertFalse(makeVM(question: ratedQuestion).canShowAnswerCTA)
        XCTAssertFalse(makeVM(question: unratedQuestion).canShowAnswerCTA)
    }

    func test_canShowRateCTA_trueOnlyWhenUnratedAnswerLoaded() async {
        let vm = makeVM(question: unratedQuestion)
        XCTAssertFalse(vm.canShowRateCTA, "Before load it should be false")

        await vm.loadAnswerIfNeeded()
        XCTAssertTrue(vm.canShowRateCTA, "After loading an unrated answer it should be true")
    }

    func test_canShowRateCTA_falseWhenAlreadyRated() async {
        let vm = makeVM(question: ratedQuestion)
        await vm.loadAnswerIfNeeded()
        XCTAssertFalse(vm.canShowRateCTA)
    }

    // MARK: - Load

    func test_loadAnswerIfNeeded_skipsForWaitingQuestion() async {
        let vm = makeVM(question: waitingQuestion)
        await vm.loadAnswerIfNeeded()
        XCTAssertNil(vm.answer)
        XCTAssertFalse(vm.isLoadingAnswer)
    }

    func test_loadAnswerIfNeeded_populatesAnswerForAnswered() async {
        let vm = makeVM(question: ratedQuestion)
        await vm.loadAnswerIfNeeded()
        XCTAssertNotNil(vm.answer)
        XCTAssertEqual(vm.answer?.questionId, ratedQuestion.id)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadAnswerIfNeeded_skipsIfAlreadyLoaded() async {
        let vm = makeVM(question: ratedQuestion)
        await vm.loadAnswerIfNeeded()
        let first = vm.answer

        // 2 度目は no-op
        await vm.loadAnswerIfNeeded()
        XCTAssertEqual(vm.answer, first)
    }

    func test_loadAnswerIfNeeded_handlesMissingAnswerGracefully() async {
        // status は answered だが Mock 側に対応エントリなしのケース
        let vm = makeVM(question: ratedQuestion, answers: [:])
        await vm.loadAnswerIfNeeded()
        XCTAssertNil(vm.answer)
        XCTAssertNil(vm.errorMessage)
    }
}
