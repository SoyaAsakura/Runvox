@testable import Runvox
import XCTest

@MainActor
final class SearchViewModelTests: XCTestCase {
    private func makeVM() -> SearchViewModel {
        SearchViewModel(
            repository: MockQuestionRepository(simulatedLatency: .milliseconds(0)),
            limit: 50
        )
    }

    // MARK: - Initial state

    func test_initialState() {
        let vm = makeVM()
        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertFalse(vm.hasSearched)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Search

    func test_search_emptyQuery_noResultsNoSearch() async {
        let vm = makeVM()
        vm.query = "   "
        await vm.search()
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.hasSearched)
    }

    func test_search_matchesTitle() async {
        let vm = makeVM()
        vm.query = "サブ3.5"
        await vm.search()
        XCTAssertTrue(vm.hasSearched)
        XCTAssertFalse(vm.results.isEmpty)
        XCTAssertTrue(vm.results.allSatisfy {
            $0.title.contains("サブ3.5") || $0.body.contains("サブ3.5")
        })
    }

    func test_search_matchesBody() async {
        let vm = makeVM()
        // body にだけ含まれる語（サンプル q1 の body: "現在ハーフ1:35..."）
        vm.query = "ハーフ"
        await vm.search()
        XCTAssertTrue(vm.hasSearched)
        XCTAssertFalse(vm.results.isEmpty)
    }

    func test_search_caseInsensitive() async {
        let vm = makeVM()
        vm.query = "it"   // "ITバンド" を小文字で
        await vm.search()
        XCTAssertTrue(vm.hasSearched)
        XCTAssertFalse(vm.results.isEmpty)
    }

    func test_search_noMatch_returnsEmptyButHasSearched() async {
        let vm = makeVM()
        vm.query = "存在しないキーワードxyz123"
        await vm.search()
        XCTAssertTrue(vm.hasSearched)
        XCTAssertTrue(vm.results.isEmpty)
    }

    func test_search_trimsWhitespace() async {
        let vm = makeVM()
        // サンプル q5 のタイトル「ITバンド炎症のテーピング方法」に含まれる語
        vm.query = "  テーピング  "
        await vm.search()
        XCTAssertTrue(vm.hasSearched)
        XCTAssertFalse(vm.results.isEmpty)
    }

    // MARK: - Clear

    func test_clear_resetsState() async {
        let vm = makeVM()
        vm.query = "サブ3.5"
        await vm.search()
        XCTAssertFalse(vm.results.isEmpty)

        vm.clear()
        XCTAssertEqual(vm.query, "")
        XCTAssertTrue(vm.results.isEmpty)
        XCTAssertFalse(vm.hasSearched)
        XCTAssertNil(vm.errorMessage)
    }
}
