import Foundation

/// 評価モーダルの状態管理
@MainActor
final class RatingViewModel: ObservableObject {
    let answer: Answer

    @Published var selectedStars: Int = 0
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var errorMessage: String?

    private let repository: RatingRepository

    init(answer: Answer, repository: RatingRepository = RepositoryFactory.makeRatingRepository()) {
        self.answer = answer
        self.repository = repository
    }

    // MARK: - Derived state

    var canSubmit: Bool {
        (1...5).contains(selectedStars) && !isSubmitting
    }

    /// 現在の選択でのプレビュー付与ポイント
    var previewPoints: Int {
        guard (1...5).contains(selectedStars) else { return 0 }
        return PointCalculator.calculate(stars: selectedStars, rank: answer.answererRank)
    }

    var previewBasePoints: Int {
        PointCalculator.basePoints[selectedStars] ?? 0
    }

    var previewMultiplier: Double {
        answer.answererRank.multiplier
    }

    /// 選択値ごとの定性ラベル
    var qualitativeLabel: String? {
        switch selectedStars {
        case 5: return "最高でした"
        case 4: return "とても良かった"
        case 3: return "普通でした"
        case 2: return "もう少し"
        case 1: return "イマイチでした"
        default: return nil
        }
    }

    // MARK: - Submit

    /// 評価送信。成功した RatingResult を返す（失敗時は nil）
    func submit() async -> RatingResult? {
        guard canSubmit else { return nil }
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            return try await repository.submitRating(
                answerId: answer.id,
                stars: selectedStars,
                answererRank: answer.answererRank
            )
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
