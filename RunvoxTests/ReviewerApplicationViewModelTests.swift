@testable import Runvox
import XCTest

@MainActor
final class ReviewerApplicationViewModelTests: XCTestCase {
    private func makeVM(
        userId: String = "u-test",
        initial: [String: ReviewerApplication] = [:]
    ) -> ReviewerApplicationViewModel {
        ReviewerApplicationViewModel(
            userId: userId,
            repository: MockReviewerApplicationRepository(
                simulatedLatency: .milliseconds(0),
                initial: initial
            )
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM()
        XCTAssertNil(vm.application)
        XCTAssertEqual(vm.achievements, "")
        XCTAssertFalse(vm.canSubmit)
        XCTAssertTrue(vm.shouldShowForm)
        XCTAssertFalse(vm.hasExistingApplication)
    }

    // MARK: - canSubmit

    func test_canSubmit_falseWhenTooShort() {
        let vm = makeVM()
        vm.achievements = "短い"
        XCTAssertFalse(vm.canSubmit)
    }

    func test_canSubmit_trueAt10Chars() {
        let vm = makeVM()
        vm.achievements = "東京マラソン3:30で完走"   // 13 文字
        XCTAssertTrue(vm.canSubmit)
    }

    func test_canSubmit_falseWhenWhitespaceOnly() {
        let vm = makeVM()
        vm.achievements = "                "
        XCTAssertFalse(vm.canSubmit)
    }

    // MARK: - Submit

    func test_submit_successPopulatesApplication() async {
        let vm = makeVM()
        vm.achievements = "ハーフマラソン 1:35 / フル完走 8 回"

        let ok = await vm.submit()
        XCTAssertTrue(ok)
        XCTAssertNotNil(vm.application)
        XCTAssertEqual(vm.application?.status, .submitted)
        XCTAssertEqual(vm.achievements, "", "成功時は入力欄をクリア")
    }

    func test_submit_failureSetsErrorMessage() async {
        let vm = makeVM()
        vm.achievements = "fail-network test content long enough"

        let ok = await vm.submit()
        XCTAssertFalse(ok)
        XCTAssertNotNil(vm.errorMessage)
        XCTAssertNil(vm.application)
    }

    func test_submit_returnsFalseWhenNotSubmittable() async {
        let vm = makeVM()
        vm.achievements = "短"

        let ok = await vm.submit()
        XCTAssertFalse(ok)
    }

    // MARK: - Load existing

    func test_load_existingApplicationPopulates() async {
        let app = ReviewerApplication(
            id: "1", userId: "u-test", status: .submitted,
            achievements: "サブ3達成", certifications: "", referenceURL: nil,
            submittedAt: Date(),
            reviewedAt: nil, assignedRank: nil, rejectionReason: nil
        )
        let vm = makeVM(initial: ["u-test": app])
        await vm.loadIfNeeded()

        XCTAssertEqual(vm.application?.status, .submitted)
        XCTAssertTrue(vm.hasExistingApplication)
        XCTAssertFalse(vm.shouldShowForm, "申請中は再申請フォーム非表示")
    }

    func test_load_approvedApplicationHidesForm() async {
        let app = ReviewerApplication(
            id: "1", userId: "u-test", status: .approved,
            achievements: "サブ3達成", certifications: "", referenceURL: nil,
            submittedAt: Date(), reviewedAt: Date(), assignedRank: .a,
            rejectionReason: nil
        )
        let vm = makeVM(initial: ["u-test": app])
        await vm.loadIfNeeded()

        XCTAssertFalse(vm.shouldShowForm, "承認済みは再申請不可")
    }

    // MARK: - Application.canResubmit

    func test_canResubmit_falseForApproved() {
        let app = ReviewerApplication(
            id: "1", userId: "u", status: .approved,
            achievements: "", certifications: "", referenceURL: nil,
            submittedAt: Date(), reviewedAt: Date(), assignedRank: .b,
            rejectionReason: nil
        )
        XCTAssertFalse(app.canResubmit)
    }

    func test_canResubmit_falseForRecentlyRejected() {
        let app = ReviewerApplication(
            id: "1", userId: "u", status: .rejected,
            achievements: "", certifications: "", referenceURL: nil,
            submittedAt: Date(), reviewedAt: Date(), assignedRank: nil,
            rejectionReason: "実績不足"
        )
        XCTAssertFalse(app.canResubmit, "直近の不合格は 1 ヶ月待つ")
    }

    func test_canResubmit_trueAfterOneMonth() {
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        let app = ReviewerApplication(
            id: "1", userId: "u", status: .rejected,
            achievements: "", certifications: "", referenceURL: nil,
            submittedAt: oneMonthAgo, reviewedAt: oneMonthAgo,
            assignedRank: nil, rejectionReason: "実績不足"
        )
        XCTAssertTrue(app.canResubmit)
    }

    // MARK: - ApplicationStatus.stepperIndex

    func test_stepperIndex_mappings() {
        XCTAssertEqual(ApplicationStatus.notSubmitted.stepperIndex, 0)
        XCTAssertEqual(ApplicationStatus.submitted.stepperIndex, 0)
        XCTAssertEqual(ApplicationStatus.reviewing.stepperIndex, 1)
        XCTAssertEqual(ApplicationStatus.approved.stepperIndex, 3)
    }

    func test_stepperProgress_doneForApproved() {
        XCTAssertEqual(ApplicationStatus.approved.progress(at: 0), .done)
        XCTAssertEqual(ApplicationStatus.approved.progress(at: 3), .done)
    }

    func test_stepperProgress_activeAtCurrentIndex() {
        XCTAssertEqual(ApplicationStatus.submitted.progress(at: 0), .active)
        XCTAssertEqual(ApplicationStatus.submitted.progress(at: 1), .pending)
        XCTAssertEqual(ApplicationStatus.reviewing.progress(at: 1), .active)
        XCTAssertEqual(ApplicationStatus.reviewing.progress(at: 0), .done)
    }
}
