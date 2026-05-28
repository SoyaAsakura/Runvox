import SwiftUI

/// 質問のステータス表示
enum QuestionStatus: Equatable {
    case waiting                              // 回答待ち
    case answered                             // 回答済
    case rallyActive(used: Int, max: Int)     // ラリー中 (例: 1/1)

    var label: String {
        switch self {
        case .waiting:                       return "回答待ち"
        case .answered:                      return "回答済"
        case .rallyActive(let used, let max): return "ラリー中 \(used)/\(max)"
        }
    }
}

/// 質問のステータスを示すピル型ラベル
struct StatusPill: View {
    let status: QuestionStatus

    var body: some View {
        HStack(spacing: 4) {
            iconOrDot
            Text(status.label)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(backgroundColor)
        .clipShape(Capsule())
    }

    @ViewBuilder
    private var iconOrDot: some View {
        switch status {
        case .waiting:
            Circle()
                .fill(Color(hex: 0xB07A1A))
                .frame(width: 6, height: 6)
        case .answered:
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .black))
        case .rallyActive:
            Image(systemName: "waveform.path")
                .font(.system(size: 9, weight: .bold))
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .waiting:     return Color(hex: 0xB07A1A)
        case .answered:    return Color(hex: 0x00803F)
        case .rallyActive: return RunvoxColors.primaryDark
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .waiting:     return Color(hex: 0xFFF4DA)
        case .answered:    return Color(hex: 0xDFF5E5)
        case .rallyActive: return RunvoxColors.bgTint
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        Text("All variants").font(.caption).foregroundStyle(.secondary)
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(status: .waiting)
            StatusPill(status: .answered)
            StatusPill(status: .rallyActive(used: 1, max: 1))
            StatusPill(status: .rallyActive(used: 0, max: 1))
        }

        Divider()

        Text("In context (question card meta row)").font(.caption).foregroundStyle(.secondary)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryChip(label: "トレーニング", size: .small)
                Spacer()
                StatusPill(status: .waiting)
            }
            HStack {
                CategoryChip(label: "ケガ予防", size: .small)
                Spacer()
                StatusPill(status: .answered)
            }
            HStack {
                CategoryChip(label: "栄養", size: .small)
                Spacer()
                StatusPill(status: .rallyActive(used: 1, max: 1))
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(RunvoxColors.border)
        )
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
