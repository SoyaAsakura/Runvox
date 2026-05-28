import SwiftUI

/// 設定系画面の行コンポーネント
struct SettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String?
    var trailingText: String?
    var showsChevron: Bool = true
    var destructive: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBox
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(destructive ? RunvoxColors.danger : RunvoxColors.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(RunvoxColors.subtext)
                    }
                }
                Spacer(minLength: 8)
                if let trailingText {
                    Text(trailingText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(RunvoxColors.subtext)
                }
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RunvoxColors.subtext)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconBox: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(destructive ? RunvoxColors.danger : RunvoxColors.primaryDark)
            .frame(width: 32, height: 32)
            .background(destructive ? Color(hex: 0xFDE8EA) : RunvoxColors.bgTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// 設定行を束ねるグループ
struct SettingsGroup<Content: View>: View {
    let title: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(RunvoxColors.subtext)
                    .padding(.horizontal, 16)
            }
            VStack(spacing: 0) {
                content
            }
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SettingsGroup("アカウント") {
                SettingsRow(icon: "person.fill", title: "プロフィール編集") {}
                Divider().padding(.leading, 60)
                SettingsRow(icon: "bell.fill", title: "通知設定", subtitle: "プッシュ通知 OFF") {}
            }
            SettingsGroup("アプリ情報") {
                SettingsRow(icon: "info.circle.fill", title: "バージョン", trailingText: "0.1.0", showsChevron: false) {}
            }
            SettingsGroup {
                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "ログアウト", destructive: true, action: {})
            }
        }
        .padding(20)
    }
    .background(RunvoxColors.bgPage)
}
