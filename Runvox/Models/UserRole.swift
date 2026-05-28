import Foundation

/// ユーザーの役割
enum UserRole: String, Codable, CaseIterable {
    case questioner   // 質問者（デフォルト）
    case answerer     // 回答者（審査通過後）
    case admin        // 運営

    var displayLabel: String {
        switch self {
        case .questioner: return "質問者"
        case .answerer:   return "回答者"
        case .admin:      return "運営"
        }
    }
}
