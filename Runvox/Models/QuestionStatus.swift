import Foundation

/// 質問のステータス
enum QuestionStatus: Equatable {
    case waiting                              // 回答待ち
    case answered                             // 回答済
    case rallyActive(used: Int, max: Int)     // ラリー中 (例: 1/1)

    var label: String {
        switch self {
        case .waiting:
            return "回答待ち"
        case .answered:
            return "回答済"
        case .rallyActive(let used, let max):
            return "ラリー中 \(used)/\(max)"
        }
    }
}
