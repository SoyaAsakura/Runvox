import Foundation

/// Firestore 統合前の開発用モック実装
///
/// - 評価値が範囲外なら invalidStars エラー
/// - "fail-network" を answerId に渡すとネットワークエラーを投げる
final class MockRatingRepository: RatingRepository {
    enum MockError: LocalizedError {
        case invalidStars
        case network

        var errorDescription: String? {
            switch self {
            case .invalidStars: return "評価値は 1〜5 を指定してください"
            case .network:      return "通信エラーが発生しました"
            }
        }
    }

    private let simulatedLatency: Duration

    init(simulatedLatency: Duration = .milliseconds(500)) {
        self.simulatedLatency = simulatedLatency
    }

    func submitRating(
        answerId: String,
        stars: Int,
        answererRank: Rank
    ) async throws -> RatingResult {
        try await Task.sleep(for: simulatedLatency)

        guard (1...5).contains(stars) else {
            throw MockError.invalidStars
        }
        if answerId == "fail-network" {
            throw MockError.network
        }

        let basePoints = PointCalculator.basePoints[stars] ?? 0
        let multiplier = answererRank.multiplier
        let awarded = PointCalculator.calculate(stars: stars, rank: answererRank)

        return RatingResult(
            answerId: answerId,
            stars: stars,
            basePoints: basePoints,
            rankMultiplier: multiplier,
            pointsAwarded: awarded
        )
    }
}
