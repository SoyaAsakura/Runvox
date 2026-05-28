import SwiftUI

/// メール + パスワード + ニックネームで新規登録する画面
struct EmailSignupView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var nickname: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var nicknameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var generalError: String?
    @State private var isLoading: Bool = false

    private var canSubmit: Bool {
        !nickname.isEmpty && !email.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header

                        RunvoxTextField(
                            title: "ニックネーム",
                            placeholder: "ランナー太郎",
                            text: $nickname,
                            contentType: .nickname,
                            errorMessage: nicknameError
                        )

                        RunvoxTextField(
                            title: "メールアドレス",
                            placeholder: "you@example.com",
                            text: $email,
                            keyboardType: .emailAddress,
                            contentType: .emailAddress,
                            errorMessage: emailError
                        )

                        RunvoxTextField(
                            title: "パスワード",
                            placeholder: "8文字以上 + 英字 + 数字",
                            text: $password,
                            contentType: .newPassword,
                            isSecure: true,
                            errorMessage: passwordError
                        )

                        passwordHints

                        if let generalError {
                            Text(generalError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RunvoxColors.danger)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: 0xFDE8EA))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button {
                            Task { await submit() }
                        } label: {
                            Text("アカウント作成")
                        }
                        .buttonStyle(RunvoxPrimaryButtonStyle(
                            isLoading: isLoading,
                            isEnabled: canSubmit
                        ))
                        .disabled(!canSubmit)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
            .navigationTitle("新規登録")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("はじめまして 👋")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(RunvoxColors.ink)
            Text("ニックネームとメールアドレスでアカウントを作成します")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .padding(.bottom, 4)
    }

    private var passwordHints: some View {
        VStack(alignment: .leading, spacing: 4) {
            hint("8 文字以上", met: password.count >= AuthValidator.minPasswordLength)
            hint(
                "英字を含む",
                met: password.rangeOfCharacter(from: .letters) != nil
            )
            hint(
                "数字を含む",
                met: password.rangeOfCharacter(from: .decimalDigits) != nil
            )
        }
        .padding(.leading, 4)
    }

    @ViewBuilder
    private func hint(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundStyle(met ? RunvoxColors.success : RunvoxColors.subtext)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(met ? RunvoxColors.success : RunvoxColors.subtext)
        }
    }

    // MARK: - Actions

    private func submit() async {
        nicknameError = nil
        emailError = nil
        passwordError = nil
        generalError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.signUpWithEmail(
                email: email,
                password: password,
                nickname: nickname
            )
            dismiss()
        } catch let error as AuthError {
            handleError(error)
        } catch {
            generalError = error.localizedDescription
        }
    }

    private func handleError(_ error: AuthError) {
        switch error {
        case .invalidEmail, .emailAlreadyInUse:
            emailError = error.errorDescription
        case .weakPassword:
            passwordError = error.errorDescription
        case .invalidNickname, .nicknameAlreadyTaken:
            nicknameError = error.errorDescription
        default:
            generalError = error.errorDescription
        }
    }
}

#Preview {
    EmailSignupView()
        .environmentObject(AuthService.previewSignedOut())
}
