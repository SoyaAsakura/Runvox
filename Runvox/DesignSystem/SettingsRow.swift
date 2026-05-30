import SwiftUI

/// 設定系画面の行の「見た目」だけを担うラベル。
///
/// `NavigationLink` / `Link` の中身として使うと、リンク自身がタップ領域を持つので
/// 行全体が正しくタップ可能になる（`contentShape(Rectangle())` 込み）。
/// タップで処理を実行したいだけなら代わりに `SettingsRow` を使う。
struct SettingsRowLabel: View {
    let icon: String
    let title: String
    var subtitle: String?
    var trailingText: String?
    var showsChevron: Bool = true
    var destructive: Bool = false

    var body: some View {
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

    private var iconBox: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(destructive ? RunvoxColors.danger : RunvoxColors.primaryDark)
            .frame(width: 32, height: 32)
            .background(destructive ? Color(hex: 0xFDE8EA) : RunvoxColors.bgTint)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// タップでアクションを実行する設定行（Button）。
///
/// 画面遷移（`NavigationLink` / `Link`）に使う場合は、この `SettingsRow` ではなく
/// 中身の `SettingsRowLabel` を直接リンクの中に置くこと。`SettingsRow` は Button な
/// ので、`NavigationLink` の中に入れて `allowsHitTesting(false)` で殺すとリンクごと
/// タップ不能になる（過去そのバグがあった）。
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
            SettingsRowLabel(
                icon: icon,
                title: title,
                subtitle: subtitle,
                trailingText: trailingText,
                showsChevron: showsChevron,
                destructive: destructive
            )
        }
        .buttonStyle(.plain)
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
