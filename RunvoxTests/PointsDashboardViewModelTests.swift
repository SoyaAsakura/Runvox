@testable import Runvox
import XCTest

@MainActor
final class PointsDashboardViewModelTests: XCTestCase {
    private func makeVM(
        summary: UserPoints = MockPointRepository.defaultSummary,
        transactions: [PointTransaction] = MockPointRepository.defaultTransactions
    ) -> PointsDashboardViewModel {
        PointsDashboardViewModel(
            userId: "u-me",
            repository: MockPointRepository(
                simulatedLatency: .milliseconds(0),
                summary: summary,
                transactions: transactions
            ),
            limit: 20
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM()
        XCTAssertNil(vm.summary)
        XCTAssertTrue(vm.transactions.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Load

    func test_loadIfNeeded_populatesSummaryAndTransactions() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        XCTAssertEqual(vm.summary, MockPointRepository.defaultSummary)
        XCTAssertEqual(vm.transactions.count, MockPointRepository.defaultTransactions.count)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadIfNeeded_skipsIfAlreadyLoaded() async {
        let vm = makeVM()
        await vm.loadIfNeeded()
        let first = vm.transactions.count

        await vm.loadIfNeeded()
        XCTAssertEqual(vm.transactions.count, first)
    }

    func test_refresh_reloads() async {
        let vm = makeVM()
        await vm.loadIfNeeded()

        await vm.refresh()
        XCTAssertNotNil(vm.summary)
    }

    func test_load_emptyData_resultsInEmptyView() async {
        let vm = makeVM(
            summary: UserPoints(balance: 0, lifetimeEarned: 0, thisMonthEarned: 0, lastMonthDeltaPercent: 0),
            transactions: []
        )
        await vm.loadIfNeeded()

        XCTAssertEqual(vm.summary?.balance, 0)
        XCTAssertTrue(vm.transactions.isEmpty)
    }

    // MARK: - UserPoints derived values

    func test_userPoints_cashoutProgress() {
        let halfway = UserPoints(balance: 10_000, lifetimeEarned: 10_000, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        XCTAssertEqual(halfway.cashoutProgress, 0.5, accuracy: 0.001)

        let full = UserPoints(balance: 25_000, lifetimeEarned: 25_000, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        XCTAssertEqual(full.cashoutProgress, 1.0, "Should cap at 1.0")

        let zero = UserPoints(balance: 0, lifetimeEarned: 0, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        XCTAssertEqual(zero.cashoutProgress, 0.0)
    }

    func test_userPoints_pointsUntilCashout() {
        let belowThreshold = UserPoints(balance: 12_450, lifetimeEarned: 0, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        XCTAssertEqual(belowThreshold.pointsUntilCashout, 7_550)

        let aboveThreshold = UserPoints(balance: 25_000, lifetimeEarned: 0, thisMonthEarned: 0, lastMonthDeltaPercent: 0)
        XCTAssertEqual(aboveThreshold.pointsUntilCashout, 0)
    }

    // MARK: - PointTransaction display

    func test_pointTransaction_shortDate_formatsAsMonthSlashDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 28
        let date = Calendar.current.date(from: components)!

        let tx = PointTransaction(
            id: "t1",
            userId: "u",
            answerId: "a",
            questionTitle: "テスト",
            stars: 5,
            rank: .s,
            basePoints: 250,
            multiplier: 2.0,
            pointsAwarded: 500,
            createdAt: date
        )
        XCTAssertEqual(tx.shortDate, "5/28")
    }
}
