import Foundation

/// 通報理由
enum ReportReason: String, CaseIterable, Identifiable, Equatable {
    case offTopic       // 陸上競技と無関係
    case spam           // スパム・宣伝
    case harassment     // 嫌がらせ・誹謗中傷
    case inappropriate  // 不適切な内容
    case other          // その他

    var id: String { rawValue }

    var label: String {
        switch self {
        case .offTopic:      return "陸上競技と無関係な内容"
        case .spam:          return "スパム・宣伝"
        case .harassment:    return "嫌がらせ・誹謗中傷"
        case .inappropriate: return "不適切な内容"
        case .other:         return "その他"
        }
    }
}

/// 通報対象の種別
enum ReportTargetType: String, Equatable {
    case question
    case answer

    var displayName: String {
        switch self {
        case .question: return "質問"
        case .answer:   return "回答"
        }
    }
}

/// 通報送信用のドラフト
struct ReportDraft: Equatable {
    let reporterId: String
    let targetType: ReportTargetType
    let targetId: String
    let reason: ReportReason
    let comment: String?
}

/// 通報レコード
struct Report: Identifiable, Equatable {
    let id: String
    let reporterId: String
    let targetType: ReportTargetType
    let targetId: String
    let reason: ReportReason
    let comment: String?
    let createdAt: Date
}
