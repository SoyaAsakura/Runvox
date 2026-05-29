import Foundation

/// アプリ内通知の種別
///
/// 仕様の通知マトリクスに対応:
/// - answerReceived  : 回答が届いた（質問者向け）
/// - rallyReceived   : 追加質問が届いた（回答者向け）
/// - ratingReceived  : 評価が付いた（回答者向け）
/// - pointConfirmed  : ポイント確定（回答者向け・アプリ内のみ）
enum NotificationType: String, Codable, CaseIterable, Equatable, Hashable {
    case answerReceived
    case rallyReceived
    case ratingReceived
    case pointConfirmed

    /// SF Symbols 名
    var systemIcon: String {
        switch self {
        case .answerReceived: return "bubble.left.fill"
        case .rallyReceived:  return "bubble.left.and.bubble.right.fill"
        case .ratingReceived: return "star.fill"
        case .pointConfirmed: return "yensign.circle.fill"
        }
    }
}

/// アプリ内通知
///
/// `Foundation.Notification` との名前衝突を避けるため `AppNotification`。
struct AppNotification: Identifiable, Equatable, Hashable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    /// ディープリンク先（質問詳細など）。MVP では未使用
    let targetPath: String?
    var isRead: Bool
    let createdAt: Date

    /// 何分前 / 何時間前 / 何日前
    var relativeCreatedAt: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
