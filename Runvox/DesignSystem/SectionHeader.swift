import SwiftUI

/// セクションの見出し
///
/// 用途:
/// - "回答 (1)" のような件数付き見出し
/// - "実績" "得意分野" などのプロフィール内セクション
/// - "今月の獲得" + "すべて見る ›" のような action 付き見出し
struct SectionHeader: View {
    let title: String
    var count: Int?
    var systemIcon: String?
    var actionLabel: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(spacing: 6) {
            leadingContent
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)

            if let count {
                Text("(\(count))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(RunvoxColors.primaryDark)
            }

            Spacer()

            if let actionLabel, let action {
                Button(action: action) {
                    HStack(spacing: 2) {
                        Text(actionLabel)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(RunvoxColors.primaryDark)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var leadingContent: some View {
        if let systemIcon {
            Image(systemName: systemIcon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RunvoxColors.primaryDark)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("Variants").font(.caption).foregroundStyle(.secondary)

        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "回答", count: 1)
            SectionHeader(title: "実績", systemIcon: "rosette")
            SectionHeader(title: "得意分野", systemIcon: "tag")
            SectionHeader(
                title: "最近の回答",
                systemIcon: "bubble.left",
                actionLabel: "すべて見る",
                action: {}
            )
            SectionHeader(
                title: "ポイント履歴",
                actionLabel: "すべて見る",
                action: {}
            )
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RunvoxColors.border))
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
