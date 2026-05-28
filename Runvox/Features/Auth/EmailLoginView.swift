import SwiftUI

/// メール + パスワードでのログイン画面
struct EmailLoginView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var generalError: String?
    @State private var isLoading: Bool = false
    @State private var showResetSheet: Bool = false

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

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
                            placeholder: "8文字以上",
                            text: $password,
                            contentType: .password,
                            isSecure: true,
                            errorMessage: passwordError
                        )

                        if let generalError {
                            Text(generalError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(RunvoxColors.danger)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(hex: 0xFDE8EA))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        Button("パスワードを忘れた方はこちら") {
                            showResetSheet = true
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(RunvoxColors.primaryDark)

                        Button {
                            Task { await submit() }
                        } label: {
                            Text("ログインする")
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
            .navigationTitle("ログイン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showResetSheet) {
                PasswordResetView()
                    .environmentObject(auth)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("おかえりなさい 👋")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(RunvoxColors.ink)
            Text("登録時のメールアドレスでログインしてください")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Actions

    private func submit() async {
        emailError = nil
        passwordError = nil
        generalError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.signInWithEmail(email: email, password: password)
            dismiss()
        } catch let error as AuthError {
            handleError(error)
        } catch {
            generalError = error.localizedDescription
        }
    }

    private func handleError(_ error: AuthError) {
        switch error {
        case .invalidEmail:
            emailError = error.errorDescription
        case .wrongPassword, .weakPassword:
            passwordError = error.errorDescription
        case .userNotFound:
            emailError = error.errorDescription
        default:
            generalError = error.errorDescription
        }
    }
}

// MARK: - Password Reset

struct PasswordResetView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email: String = ""
    @State private var emailError: String?
    @State private var generalError: String?
    @State private var isLoading: Bool = false
    @State private var isSent: Bool = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if isSent {
                    sentView
                } else {
                    formView
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .background(RunvoxColors.bgPage)
            .navigationTitle("パスワード再設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var formView: some View {
        Text("登録したメールアドレスに再設定用のリンクをお送りします")
            .font(.system(size: 12))
            .foregroundStyle(RunvoxColors.subtext)

        RunvoxTextField(
            title: "メールアドレス",
            placeholder: "you@example.com",
            text: $email,
            keyboardType: .emailAddress,
            contentType: .emailAddress,
            errorMessage: emailError
        )

        if let generalError {
            Text(generalError)
                .font(.system(size: 11))
                .foregroundStyle(RunvoxColors.danger)
        }

        Button {
            Task { await send() }
        } label: {
            Text("再設定メールを送信")
        }
        .buttonStyle(RunvoxPrimaryButtonStyle(
            isLoading: isLoading,
            isEnabled: !email.isEmpty && !isLoading
        ))
        .disabled(email.isEmpty || isLoading)
        .padding(.top, 8)
    }

    private var sentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(RunvoxColors.success)
            Text("メールを送信しました")
                .font(.system(size: 18, weight: .bold))
            Text("\(email) 宛にパスワード再設定リンクをお送りしました。受信箱をご確認ください。")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func send() async {
        emailError = nil
        generalError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await auth.sendPasswordReset(email: email)
            isSent = true
        } catch let error as AuthError {
            if case .invalidEmail = error {
                emailError = error.errorDescription
            } else {
                generalError = error.errorDescription
            }
        } catch {
            generalError = error.localizedDescription
        }
    }
}

#Preview("Login") {
    EmailLoginView()
        .environmentObject(AuthService.previewSignedOut())
}

#Preview("Password Reset") {
    PasswordResetView()
        .environmentObject(AuthService.previewSignedOut())
}
