@testable import Runvox
import XCTest

final class PointCalculatorTests: XCTestCase {
    // MARK: - 仕様確認: 評価ポイント × ランク歩率

    func test_5star_S_returns500() {
        XCTAssertEqual(PointCalculator.calculate(stars: 5, rank: .s), 500)
    }

    func test_5star_A_returns375() {
        XCTAssertEqual(PointCalculator.calculate(stars: 5, rank: .a), 375)
    }

    func test_5star_B_returns250() {
        XCTAssertEqual(PointCalculator.calculate(stars: 5, rank: .b), 250)
    }

    func test_4star_S_returns300() {
        XCTAssertEqual(PointCalculator.calculate(stars: 4, rank: .s), 300)
    }

    func test_3star_A_returns150() {
        XCTAssertEqual(PointCalculator.calculate(stars: 3, rank: .a), 150)
    }

    func test_2star_B_returns50() {
        XCTAssertEqual(PointCalculator.calculate(stars: 2, rank: .b), 50)
    }

    func test_1star_S_returns20() {
        XCTAssertEqual(PointCalculator.calculate(stars: 1, rank: .s), 20)
    }

    // MARK: - 範囲外入力

    func test_0star_returns0() {
        XCTAssertEqual(PointCalculator.calculate(stars: 0, rank: .s), 0)
    }

    func test_6star_returns0() {
        XCTAssertEqual(PointCalculator.calculate(stars: 6, rank: .s), 0)
    }

    func test_negativeStar_returns0() {
        XCTAssertEqual(PointCalculator.calculate(stars: -1, rank: .s), 0)
    }
}
