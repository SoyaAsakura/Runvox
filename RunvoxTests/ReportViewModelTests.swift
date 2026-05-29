@testable import Runvox
import XCTest

@MainActor
final class ReportViewModelTests: XCTestCase {
    private func makeVM(
        targetType: ReportTargetType = .question,
        targetId: String = "q1"
    ) -> ReportViewModel {
        ReportViewModel(
            targetType: targetType,
            targetId: targetId,
            reporterId: "u-reporter",
            repository: MockReportRepository(simulatedLatency: .milliseconds(0))
        )
    }

    // MARK: - Initial state

    func test_initialState() {
        let vm = makeVM()
        XCTAssertNil(vm.selectedReason)
        XCTAssertEqual(vm.comment, "")
        XCTAssertFalse(vm.isSubmitting)
        XCTAssertFalse(vm.canSubmit, "理由未選択では送信不可")
        XCTAssertEqual(vm.targetType, .question)
    }

    // MARK: - canSubmit

    func test_canSubmit_trueAfterReasonSelected() {
        let vm = makeVM()
        vm.selectedReason = .spam
        XCTAssertTrue(vm.canSubmit)
    }

    func test_canSubmit_falseWhenCommentTooLong() {
        let vm = makeVM()
        vm.selectedReason = .spam
        vm.comment = String(repeating: "あ", count: ReportViewModel.maxCommentLength + 1)
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: - Submit

    func test_submit_successWithReasonOnly() async {
        let vm = makeVM()
        vm.selectedReason = .offTopic
        let ok = await vm.submit()
        XCTAssertTrue(ok)
        XCTAssertNil(vm.errorMessage)
    }

    func test_submit_successWithComment() async {
        let vm = makeVM(targetType: .answer, targetId: "a1")
        vm.selectedReason = .harassment
        vm.comment = "特定ユーザーへの誹謗中傷が含まれます"
        let ok = await vm.submit()
        XCTAssertTrue(ok)
    }

    func test_submit_failsWhenNoReason() async {
        let vm = makeVM()
        let ok = await vm.submit()
        XCTAssertFalse(ok)
    }

    func test_submit_networkErrorSetsMessage() async {
        let vm = makeVM()
        vm.selectedReason = .other
        vm.comment = "fail-network"
        let ok = await vm.submit()
        XCTAssertFalse(ok)
        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - Model

    func test_reportReason_allCasesHaveLabels() {
        for reason in ReportReason.allCases {
            XCTAssertFalse(reason.label.isEmpty)
        }
    }

    func test_reportTargetType_displayName() {
        XCTAssertEqual(ReportTargetType.question.displayName, "質問")
        XCTAssertEqual(ReportTargetType.answer.displayName, "回答")
    }
}
