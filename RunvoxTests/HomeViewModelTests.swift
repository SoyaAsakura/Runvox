@testable import Runvox
import XCTest

@MainActor
final class HomeViewModelTests: XCTestCase {
    // MARK: - Helpers

    private func makeVM(
        samples: [Question] = MockQuestionRepository.defaultSamples
    ) -> HomeViewModel {
        HomeViewModel(
            repository: MockQuestionRepository(
                simulatedLatency: .milliseconds(0),
                sampleQuestions: samples
            ),
            pageLimit: 20
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM()
        XCTAssertTrue(vm.questions.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.selectedCategory)
    }

    // MARK: - Load

    func test_loadIfNeeded_populatesQuestions() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        XCTAssertEqual(vm.questions.count, MockQuestionRepository.defaultSamples.count)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadIfNeeded_skipsIfAlreadyLoaded() async {
        let vm = makeVM()
        await vm.loadIfNeeded()
        let firstCount = vm.questions.count

        // 2 回目は何もしない（順序保証）
        await vm.loadIfNeeded()
        XCTAssertEqual(vm.questions.count, firstCount)
    }

    // MARK: - Refresh

    func test_refresh_reloadsQuestions() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        await vm.refresh()
        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.questions.count, MockQuestionRepository.defaultSamples.count)
    }

    // MARK: - Category filter

    func test_selectCategory_filtersQuestions() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        await vm.selectCategory(.training)
        XCTAssertEqual(vm.selectedCategory, .training)
        XCTAssertTrue(vm.questions.allSatisfy { $0.category == .training })
    }

    func test_selectCategory_nilReturnsAll() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        await vm.selectCategory(.injuryPrevention)
        XCTAssertFalse(vm.questions.isEmpty)

        await vm.selectCategory(nil)
        XCTAssertNil(vm.selectedCategory)
        XCTAssertEqual(vm.questions.count, MockQuestionRepository.defaultSamples.count)
    }

    func test_selectCategory_sameCategoryNoOp() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        await vm.selectCategory(.training)
        let firstQuestions = vm.questions
        await vm.selectCategory(.training)
        XCTAssertEqual(vm.questions, firstQuestions)
    }

    // MARK: - Empty samples

    func test_loadIfNeeded_emptyRepository_setsEmptyList() async {
        let vm = makeVM(samples: [])
        await vm.loadIfNeeded()
        XCTAssertTrue(vm.questions.isEmpty)
        XCTAssertNil(vm.errorMessage)
    }
}
