import Foundation

/// 質問のカテゴリ
enum QuestionCategory: String, Codable, CaseIterable, Identifiable {
    case race
    case training
    case nutrition
    case gear
    case injuryPrevention
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .race:              return "レース"
        case .training:          return "トレーニング"
        case .nutrition:         return "栄養"
        case .gear:              return "ウェア"
        case .injuryPrevention:  return "ケガ予防"
        case .other:             return "その他"
        }
    }

    /// SF Symbols 名
    var systemIcon: String {
        switch self {
        case .race:              return "flag.fill"
        case .training:          return "figure.run"
        case .nutrition:         return "fork.knife"
        case .gear:              return "tshirt"
        case .injuryPrevention:  return "cross.case.fill"
        case .other:             return "ellipsis.circle"
        }
    }
}
