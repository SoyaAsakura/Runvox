import Foundation

/// Firestore 統合前の開発用モック実装
final class MockPointRepository: PointRepository {
    private let simulatedLatency: Duration
    private let summary: UserPoints
    private let transactions: [PointTransaction]

    init(
        simulatedLatency: Duration = .milliseconds(400),
        summary: UserPoints = MockPointRepository.defaultSummary,
        transactions: [PointTransaction] = MockPointRepository.defaultTransactions
    ) {
        self.simulatedLatency = simulatedLatency
        self.summary = summary
        self.transactions = transactions
    }

    func fetchSummary(userId: String) async throws -> UserPoints {
        try await Task.sleep(for: simulatedLatency)
        return summary
    }

    func fetchTransactions(userId: String, limit: Int) async throws -> [PointTransaction] {
        try await Task.sleep(for: simulatedLatency)
        return Array(transactions.prefix(limit))
    }

    // MARK: - Sample data

    static let defaultSummary = UserPoints(
        balance: 12_450,
        lifetimeEarned: 39_200,
        thisMonthEarned: 2_850,
        lastMonthDeltaPercent: 18
    )

    static let defaultTransactions: [PointTransaction] = [
        MockPointRepository.tx("t1", date: -24 * 60 * 60, stars: 5, rank: .s, q: "ITバンド炎症のテーピング"),
        MockPointRepository.tx("t2", date: -3 * 24 * 60 * 60, stars: 4, rank: .s, q: "サブ3.5の30km走頻度"),
        MockPointRepository.tx("t3", date: -5 * 24 * 60 * 60, stars: 3, rank: .s, q: "シンスプリント治療"),
        MockPointRepository.tx("t4", date: -7 * 24 * 60 * 60, stars: 5, rank: .s, q: "東京マラソン直前調整"),
        MockPointRepository.tx("t5", date: -10 * 24 * 60 * 60, stars: 4, rank: .a, q: "カーボローディング"),
        MockPointRepository.tx("t6", date: -14 * 24 * 60 * 60, stars: 5, rank: .s, q: "ペース走の効果的な距離"),
        MockPointRepository.tx("t7", date: -21 * 24 * 60 * 60, stars: 3, rank: .a, q: "ラントレ後の食事"),
        MockPointRepository.tx("t8", date: -28 * 24 * 60 * 60, stars: 2, rank: .b, q: "シューズローテーション"),
    ]

    private static func tx(
        _ id: String,
        date offset: TimeInterval,
        stars: Int,
        rank: Rank,
        q: String
    ) -> PointTransaction {
        let base = PointCalculator.basePoints[stars] ?? 0
        let awarded = PointCalculator.calculate(stars: stars, rank: rank)
        return PointTransaction(
            id: id,
            userId: "u-me",
            answerId: "ans-\(id)",
            questionTitle: q,
            stars: stars,
            rank: rank,
            basePoints: base,
            multiplier: rank.multiplier,
            pointsAwarded: awarded,
            createdAt: Date().addingTimeInterval(offset)
        )
    }
}
