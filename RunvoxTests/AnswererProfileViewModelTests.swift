@testable import Runvox
import XCTest

@MainActor
final class AnswererProfileViewModelTests: XCTestCase {
    private func makeVM(
        userId: String,
        profiles: [String: AnswererProfile] = MockUserRepository.defaultProfiles
    ) -> AnswererProfileViewModel {
        AnswererProfileViewModel(
            userId: userId,
            repository: MockUserRepository(
                simulatedLatency: .milliseconds(0),
                profiles: profiles
            )
        )
    }

    // MARK: - Initial state

    func test_initialState_isEmpty() {
        let vm = makeVM(userId: "a1")
        XCTAssertNil(vm.profile)
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Load

    func test_loadIfNeeded_populatesProfile() async {
        let vm = makeVM(userId: "a1")
        await vm.loadIfNeeded()

        XCTAssertNotNil(vm.profile)
        XCTAssertEqual(vm.profile?.user.id, "a1")
        XCTAssertEqual(vm.profile?.user.rank, .s)
        XCTAssertNil(vm.errorMessage)
    }

    func test_loadIfNeeded_unknownIdSetsErrorMessage() async {
        let vm = makeVM(userId: "unknown")
        await vm.loadIfNeeded()

        XCTAssertNil(vm.profile)
        XCTAssertNotNil(vm.errorMessage)
    }

    func test_loadIfNeeded_skipsIfAlreadyLoaded() async {
        let vm = makeVM(userId: "a1")
        await vm.loadIfNeeded()
        let first = vm.profile

        await vm.loadIfNeeded()
        XCTAssertEqual(vm.profile, first)
    }

    func test_retry_reloads() async {
        let vm = makeVM(userId: "a1")
        await vm.retry()
        XCTAssertNotNil(vm.profile)
    }

    // MARK: - Sample data shape

    func test_defaultProfiles_haveAllRanks() {
        let profiles = MockUserRepository.defaultProfiles
        let ranks = Set(profiles.values.compactMap { $0.user.rank })
        XCTAssertEqual(ranks, Set<Rank>([.s, .a, .b]))
    }

    func test_aRank_profile_hasRequiredFields() {
        let profile = MockUserRepository.defaultProfiles["a1"]!
        XCTAssertEqual(profile.user.displayName, profile.user.realName ?? profile.user.nickname)
        XCTAssertFalse(profile.achievements.isEmpty)
        XCTAssertNotNil(profile.coachingYears)
        XCTAssertFalse(profile.specialtyTags.isEmpty)
        XCTAssertNotNil(profile.stats)
        XCTAssertFalse(profile.recentAnswers.isEmpty)
    }

    // MARK: - AnswerSummary date formatter

    func test_answerSummary_shortDate_formatsYearMonthDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 5
        components.day = 28
        let date = Calendar.current.date(from: components)!

        let summary = AnswerSummary(id: "x", questionTitle: "テスト", rating: 5, createdAt: date)
        XCTAssertEqual(summary.shortDate, "2026/05/28")
    }
}
