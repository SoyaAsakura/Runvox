import SwiftUI

/// カテゴリタグ表示用のチップ
///
/// 用途:
/// - ホーム画面のカテゴリフィルタ
/// - 質問カード上のカテゴリ表示（`#トレーニング` など）
/// - 質問詳細画面のタグ群
struct CategoryChip: View {
    let label: String
    var style: Style = .filled
    var size: Size = .medium
    var showHashtag: Bool = true

    enum Style {
        case filled       // 塗りつぶし（質問カード用）
        case outline      // アウトライン（フィルタ未選択時）
        case selected     // 選択中（ダーク塗り）
    }

    enum Size {
        case small        // カードのメタ情報
        case medium       // フィルタチップ・標準
    }

    var body: some View {
        Text(showHashtag ? "#\(label)" : label)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(backgroundColor)
            .overlay(
                Capsule()
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(Capsule())
    }

    // MARK: - Style derivation

    private var fontSize: CGFloat {
        switch size {
        case .small:  return 11
        case .medium: return 12
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small:  return 10
        case .medium: return 14
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small:  return 4
        case .medium: return 7
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .filled:   return RunvoxColors.primaryDark
        case .outline:  return RunvoxColors.inkSoft
        case .selected: return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled:   return RunvoxColors.bgTint
        case .outline:  return .white
        case .selected: return RunvoxColors.ink
        }
    }

    private var borderColor: Color {
        switch style {
        case .filled:   return .clear
        case .outline:  return RunvoxColors.border
        case .selected: return RunvoxColors.ink
        }
    }

    private var borderWidth: CGFloat {
        style == .outline ? 1 : 0
    }
}

#Preview("Variants") {
    VStack(alignment: .leading, spacing: 16) {
        Group {
            Text("Sizes").font(.caption).foregroundStyle(.secondary)
            HStack {
                CategoryChip(label: "トレーニング", size: .small)
                CategoryChip(label: "トレーニング", size: .medium)
            }
        }
        Group {
            Text("Styles").font(.caption).foregroundStyle(.secondary)
            HStack {
                CategoryChip(label: "トレーニング", style: .filled)
                CategoryChip(label: "トレーニング", style: .outline)
                CategoryChip(label: "トレーニング", style: .selected)
            }
        }
        Group {
            Text("Filter Row Example").font(.caption).foregroundStyle(.secondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(label: "すべて", style: .selected, showHashtag: false)
                    CategoryChip(label: "レース", style: .outline, showHashtag: false)
                    CategoryChip(label: "トレーニング", style: .outline, showHashtag: false)
                    CategoryChip(label: "栄養", style: .outline, showHashtag: false)
                    CategoryChip(label: "ウェア", style: .outline, showHashtag: false)
                    CategoryChip(label: "ケガ予防", style: .outline, showHashtag: false)
                }
            }
        }
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
