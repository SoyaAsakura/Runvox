@testable import Runvox
import XCTest

@MainActor
final class RatingViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeAnswer(rank: Rank = .s) -> Answer {
        Answer(
            id: "ans-1",
            questionId: "q-1",
            answererId: "u-1",
            answererNickname: "テスト回答者",
            answererBio: nil,
            answererRank: rank,
            answererStats: nil,
            body: "テスト回答",
            createdAt: Date(),
            rating: nil
        )
    }

    private func makeVM(rank: Rank = .s) -> RatingViewModel {
        RatingViewModel(
            answer: makeAnswer(rank: rank),
            repository: MockRatingRepository(simulatedLatency: .milliseconds(0))
        )
    }

    // MARK: - Initial state

    func test_initialState_isUnrated() {
        let vm = makeVM()
        XCTAssertEqual(vm.selectedStars, 0)
        XCTAssertFalse(vm.canSubmit)
        XCTAssertEqual(vm.previewPoints, 0)
        XCTAssertNil(vm.qualitativeLabel)
    }

    // MARK: - canSubmit

    func test_canSubmit_falseFor0Stars() {
        let vm = makeVM()
        vm.selectedStars = 0
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_trueFor1To5Stars() {
        let vm = makeVM()
        for star in 1...5 {
            vm.selectedStars = star
            XCTAssertTrue(vm.canSubmit, "★\(star) should be submittable")
        }
    }

    func test_canSubmit_falseFor6Stars() {
        let vm = makeVM()
        vm.selectedStars = 6
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: - Preview points (live calculation)

    func test_previewPoints_5starS_returns500() {
        let vm = makeVM(rank: .s)
        vm.selectedStars = 5
        XCTAssertEqual(vm.previewPoints, 500)
    }

    func test_previewPoints_4starS_returns300() {
        let vm = makeVM(rank: .s)
        vm.selectedStars = 4
        XCTAssertEqual(vm.previewPoints, 300)
    }

    func test_previewPoints_3starA_returns150() {
        let vm = makeVM(rank: .a)
        vm.selectedStars = 3
        XCTAssertEqual(vm.previewPoints, 150)
    }

    func test_previewPoints_1starB_returns10() {
        let vm = makeVM(rank: .b)
        vm.selectedStars = 1
        XCTAssertEqual(vm.previewPoints, 10)
    }

    func test_previewBaseAndMultiplier_reflectSelection() {
        let vm = makeVM(rank: .a)
        vm.selectedStars = 4
        XCTAssertEqual(vm.previewBasePoints, 150)
        XCTAssertEqual(vm.previewMultiplier, 1.5, accuracy: 0.001)
    }

    // MARK: - Qualitative label

    func test_qualitativeLabel_isLocalizedJapanese() {
        let vm = makeVM()

        vm.selectedStars = 5
        XCTAssertEqual(vm.qualitativeLabel, "最高でした")
        vm.selectedStars = 4
        XCTAssertEqual(vm.qualitativeLabel, "とても良かった")
        vm.selectedStars = 3
        XCTAssertEqual(vm.qualitativeLabel, "普通でした")
        vm.selectedStars = 2
        XCTAssertEqual(vm.qualitativeLabel, "もう少し")
        vm.selectedStars = 1
        XCTAssertEqual(vm.qualitativeLabel, "イマイチでした")
    }

    // MARK: - Submit

    func test_submit_returnsResultOnSuccess() async throws {
        let vm = makeVM(rank: .s)
        vm.selectedStars = 4

        let optional = await vm.submit()
        let result = try XCTUnwrap(optional)
        XCTAssertEqual(result.stars, 4)
        XCTAssertEqual(result.basePoints, 150)
        XCTAssertEqual(result.rankMultiplier, 2.0, accuracy: 0.001)
        XCTAssertEqual(result.pointsAwarded, 300)
        XCTAssertNil(vm.errorMessage)
    }

    func test_submit_returnsNilWhenNotSubmittable() async {
        let vm = makeVM()
        vm.selectedStars = 0   // can't submit

        let result = await vm.submit()
        XCTAssertNil(result)
    }

    // MARK: - Answer.with(rating:)

    func test_answerWithRating_replacesRatingOnly() {
        let original = Answer(
            id: "a",
            questionId: "q",
            answererId: "u",
            answererNickname: "テスト",
            answererBio: "bio",
            answererRank: .a,
            answererStats: AnswererStats(averageRating: 4.0, answerCount: 10),
            body: "本文",
            createdAt: Date(),
            rating: nil
        )

        let updated = original.with(rating: 5)
        XCTAssertEqual(updated.rating, 5)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertEqual(updated.body, original.body)
        XCTAssertEqual(updated.answererRank, original.answererRank)
        XCTAssertEqual(updated.answererStats, original.answererStats)
    }

    // MARK: - QuestionDetailViewModel.applyRating

    func test_questionDetailVM_applyRating_updatesAnswer() async {
        let detailVM = QuestionDetailViewModel(
            question: MockQuestionRepository.defaultSamples[2],  // q3 unrated
            repository: MockAnswerRepository(simulatedLatency: .milliseconds(0))
        )
        await detailVM.loadAnswerIfNeeded()
        XCTAssertNotNil(detailVM.answer)
        XCTAssertNil(detailVM.answer?.rating)

        detailVM.applyRating(4)
        XCTAssertEqual(detailVM.answer?.rating, 4)
        XCTAssertFalse(detailVM.canShowRateCTA, "After rating, rate CTA should hide")
    }
}
