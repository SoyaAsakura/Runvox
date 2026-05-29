import SwiftUI

/// 通知一覧の 1 行
struct NotificationRow: View {
    let notification: AppNotification

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
                Text(notification.body)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.inkSoft)
                    .lineLimit(2)
                Text(notification.relativeCreatedAt)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(RunvoxColors.subtext)
                    .padding(.top, 1)
            }
            Spacer(minLength: 4)
            if !notification.isRead {
                Circle()
                    .fill(RunvoxColors.primary)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(notification.isRead ? Color.white : RunvoxColors.bgTint.opacity(0.4))
        .contentShape(Rectangle())
    }

    private var iconBadge: some View {
        Image(systemName: notification.type.systemIcon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(iconColor)
            .frame(width: 36, height: 36)
            .background(iconColor.opacity(0.12))
            .clipShape(Circle())
    }

    private var iconColor: Color {
        switch notification.type {
        case .answerReceived: return RunvoxColors.primaryDark
        case .rallyReceived:  return RunvoxColors.primaryDark
        case .ratingReceived: return RunvoxColors.accentLimeD
        case .pointConfirmed: return RunvoxColors.success
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(MockNotificationRepository.defaultNotifications) { n in
            NotificationRow(notification: n)
            Divider().padding(.leading, 64)
        }
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(RunvoxColors.border))
    .padding()
    .background(RunvoxColors.bgPage)
}
