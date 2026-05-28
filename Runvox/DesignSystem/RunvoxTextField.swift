import SwiftUI

/// 認証フォーム用のテキストフィールド
struct RunvoxTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var contentType: UITextContentType?
    var isSecure: Bool = false
    var errorMessage: String?

    @FocusState private var isFocused: Bool
    @State private var isRevealed: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(RunvoxColors.inkSoft)

            HStack(spacing: 8) {
                inputField
                if isSecure {
                    Button {
                        isRevealed.toggle()
                    } label: {
                        Image(systemName: isRevealed ? "eye.slash" : "eye")
                            .foregroundStyle(RunvoxColors.subtext)
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.danger)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: errorMessage)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    @ViewBuilder
    private var inputField: some View {
        Group {
            if isSecure, !isRevealed {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .font(.system(size: 15))
        .foregroundStyle(RunvoxColors.ink)
        .keyboardType(keyboardType)
        .textContentType(contentType)
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
        .focused($isFocused)
    }

    private var borderColor: Color {
        if errorMessage != nil { return RunvoxColors.danger }
        if isFocused { return RunvoxColors.primary }
        return RunvoxColors.border
    }

    private var borderWidth: CGFloat {
        (isFocused || errorMessage != nil) ? 1.5 : 1
    }
}

private struct RunvoxTextFieldPreviewHost: View {
    @State private var email = ""
    @State private var password = "weak"

    var body: some View {
        VStack(spacing: 20) {
            RunvoxTextField(
                title: "メールアドレス",
                placeholder: "you@example.com",
                text: $email,
                keyboardType: .emailAddress,
                contentType: .emailAddress
            )

            RunvoxTextField(
                title: "パスワード",
                placeholder: "8文字以上",
                text: $password,
                contentType: .password,
                isSecure: true,
                errorMessage: "英字と数字を両方含めてください"
            )
        }
        .padding()
        .background(RunvoxColors.bgPage)
    }
}

#Preview {
    RunvoxTextFieldPreviewHost()
}
