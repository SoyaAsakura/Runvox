import Foundation

/// 回答評価から付与ポイントを算出
/// 仕様: 評価ポイント × ランク歩率
enum PointCalculator {
    /// 評価値ごとの基本ポイント
    static let basePoints: [Int: Int] = [
        1: 10,
        2: 50,
        3: 100,
        4: 150,
        5: 250,
    ]

    /// 評価 × ランク歩率で最終付与ポイントを算出
    /// - Parameters:
    ///   - stars: 1〜5 の評価値
    ///   - rank: 回答者のランク（投稿時点のスナップショット）
    /// - Returns: 付与ポイント（整数）。範囲外の入力は 0
    static func calculate(stars: Int, rank: Rank) -> Int {
        guard let base = basePoints[stars] else { return 0 }
        return Int(Double(base) * rank.multiplier)
    }
}
