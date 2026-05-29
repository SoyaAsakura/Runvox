import Foundation

/// 回答者審査の進捗ステータス
enum ApplicationStatus: String, CaseIterable, Equatable, Hashable {
    case notSubmitted      // 未申請
    case submitted         // 申請済み（運営連絡待ち）
    case reviewing         // 運営確認中
    case approved          // 承認
    case rejected          // 不合格

    /// 4 ステップのステッパー位置（0〜3）
    var stepperIndex: Int {
        switch self {
        case .notSubmitted, .submitted: return 0   // 書類提出
        case .reviewing:                return 1   // 運営審査
        case .approved:                 return 3   // 権限付与
        case .rejected:                 return 1   // 審査で止まった想定
        }
    }

    /// この行が「アクティブ（進行中）」か「完了済み」か
    func progress(at index: Int) -> StepperProgress {
        let current = stepperIndex
        if self == .approved { return .done }
        if index < current { return .done }
        if index == current { return .active }
        return .pending
    }

    var label: String {
        switch self {
        case .notSubmitted: return "未申請"
        case .submitted:    return "申請受付済"
        case .reviewing:    return "運営審査中"
        case .approved:     return "承認済"
        case .rejected:     return "不合格"
        }
    }
}

enum StepperProgress {
    case done
    case active
    case pending
}

/// 回答者審査申請の本体
struct ReviewerApplication: Identifiable, Equatable {
    let id: String
    let userId: String
    var status: ApplicationStatus
    let achievements: String         // 大会成績・実績
    let certifications: String       // 資格・指導経歴
    let referenceURL: String?        // 公開URL (任意)
    let submittedAt: Date
    var reviewedAt: Date?
    var assignedRank: Rank?
    var rejectionReason: String?

    /// 不合格通知から再申請可能になる日 (1ヶ月後)
    var nextApplicationAvailableAt: Date? {
        guard status == .rejected, let reviewedAt else { return nil }
        return Calendar.current.date(byAdding: .month, value: 1, to: reviewedAt)
    }

    /// 再申請可能か
    /// - approved: 不可 (既に通過済み)
    /// - submitted/reviewing: 不可 (既に進行中)
    /// - rejected: 通知日から 1 ヶ月経過していれば可
    /// - notSubmitted: 可
    var canResubmit: Bool {
        switch status {
        case .approved, .submitted, .reviewing:
            return false
        case .rejected:
            guard let next = nextApplicationAvailableAt else { return false }
            return Date() >= next
        case .notSubmitted:
            return true
        }
    }
}

/// 申請投稿用のドラフト
struct ReviewerApplicationDraft: Equatable {
    let userId: String
    let achievements: String
    let certifications: String
    let referenceURL: String?
}
