import SwiftUI

/// 回答者審査の 4 ステップ進捗を表示する横長ステッパー
struct ApplicationStepper: View {
    let status: ApplicationStatus

    private static let steps: [(title: String, subtitle: String)] = [
        ("書類提出", "Application"),
        ("運営審査中", "Reviewing"),
        ("ランク判定", "Ranking"),
        ("権限付与", "Approved"),
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                stepCell(
                    index: index,
                    title: step.title,
                    progress: status.progress(at: index),
                    showTrailingLine: index < Self.steps.count - 1
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [.white, RunvoxColors.bgTint.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func stepCell(
        index: Int,
        title: String,
        progress: StepperProgress,
        showTrailingLine: Bool
    ) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(index == 0 ? .clear : lineColor(for: progress, isLeading: true))
                    .frame(height: 2)
                dot(index: index, progress: progress)
                Rectangle()
                    .fill(showTrailingLine ? lineColor(for: progress, isLeading: false) : .clear)
                    .frame(height: 2)
            }
            Text(title)
                .font(.system(size: 10, weight: progress == .pending ? .regular : .bold))
                .foregroundStyle(textColor(for: progress))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private func dot(index: Int, progress: StepperProgress) -> some View {
        ZStack {
            Circle()
                .fill(dotFill(for: progress))
                .frame(width: 22, height: 22)
            if progress == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white)
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(dotTextColor(for: progress))
            }
        }
        .overlay(
            Circle()
                .stroke(
                    progress == .active ? RunvoxColors.primary.opacity(0.3) : .clear,
                    lineWidth: 5
                )
                .frame(width: 22, height: 22)
        )
    }

    // MARK: - Colors

    private func dotFill(for progress: StepperProgress) -> Color {
        switch progress {
        case .done:    return RunvoxColors.primaryDark
        case .active:  return RunvoxColors.primary
        case .pending: return .white
        }
    }

    private func dotTextColor(for progress: StepperProgress) -> Color {
        switch progress {
        case .done:    return .white
        case .active:  return .white
        case .pending: return RunvoxColors.subtext
        }
    }

    private func textColor(for progress: StepperProgress) -> Color {
        switch progress {
        case .done, .active: return RunvoxColors.ink
        case .pending:       return RunvoxColors.subtext
        }
    }

    private func lineColor(for progress: StepperProgress, isLeading: Bool) -> Color {
        switch progress {
        case .done:    return RunvoxColors.primaryDark
        case .active:  return isLeading ? RunvoxColors.primaryDark : RunvoxColors.border
        case .pending: return RunvoxColors.border
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Group {
            Text("notSubmitted").font(.caption).foregroundStyle(.secondary)
            ApplicationStepper(status: .notSubmitted)
            Text("submitted").font(.caption).foregroundStyle(.secondary)
            ApplicationStepper(status: .submitted)
            Text("reviewing").font(.caption).foregroundStyle(.secondary)
            ApplicationStepper(status: .reviewing)
            Text("approved").font(.caption).foregroundStyle(.secondary)
            ApplicationStepper(status: .approved)
            Text("rejected").font(.caption).foregroundStyle(.secondary)
            ApplicationStepper(status: .rejected)
        }
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
