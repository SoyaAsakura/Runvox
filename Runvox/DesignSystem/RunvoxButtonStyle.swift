import SwiftUI

/// プライマリ CTA ボタン（シアンダーク背景の塗りつぶし）
struct RunvoxPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                configuration.label
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(backgroundColor(pressed: configuration.isPressed))
        .foregroundStyle(.white)
        .font(.system(size: 15, weight: .bold))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isEnabled ? 1.0 : 0.6)
        .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }

    private func backgroundColor(pressed: Bool) -> Color {
        if !isEnabled { return RunvoxColors.border }
        return pressed ? RunvoxColors.primaryDeeper : RunvoxColors.primaryDark
    }
}

/// アウトラインボタン（ダーク背景前提）
struct RunvoxOutlineDarkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(configuration.isPressed ? Color.white.opacity(0.08) : .clear)
            .foregroundStyle(.white)
            .font(.system(size: 14, weight: .medium))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// アウトラインボタン（ライト背景前提）
struct RunvoxOutlineLightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(configuration.isPressed ? RunvoxColors.bgTint : Color.white)
            .foregroundStyle(RunvoxColors.ink)
            .font(.system(size: 14, weight: .medium))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("メールではじめる") {}
            .buttonStyle(RunvoxPrimaryButtonStyle())

        Button("ローディング中") {}
            .buttonStyle(RunvoxPrimaryButtonStyle(isLoading: true))

        Button("無効") {}
            .buttonStyle(RunvoxPrimaryButtonStyle(isEnabled: false))
            .disabled(true)

        Button("ライトアウトライン") {}
            .buttonStyle(RunvoxOutlineLightButtonStyle())
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
