import SwiftUI

/// 認証フローのエントリ画面
struct WelcomeView: View {
    @EnvironmentObject private var auth: AuthService
    @State private var showEmailLogin = false
    @State private var showEmailSignup = false
    @State private var isAppleLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                Spacer()
                logo
                Spacer()
                illustration
                Spacer()
                actions
                terms
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 32)
            .padding(.top, 36)
        }
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginView()
                .environmentObject(auth)
        }
        .sheet(isPresented: $showEmailSignup) {
            EmailSignupView()
                .environmentObject(auth)
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Subviews

    private var background: some View {
        LinearGradient(
            colors: [
                RunvoxColors.ink,
                Color(hex: 0x14373C),
                RunvoxColors.primaryDark,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            ZStack {
                Circle()
                    .fill(RunvoxColors.accentLime.opacity(0.18))
                    .frame(width: 280, height: 280)
                    .blur(radius: 80)
                    .offset(x: 140, y: -260)

                Circle()
                    .fill(RunvoxColors.primary.opacity(0.22))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -140, y: 280)
            }
        )
        .ignoresSafeArea()
    }

    private var logo: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                Text("Run")
                    .foregroundStyle(.white)
                Text(".")
                    .foregroundStyle(RunvoxColors.primary)
                Text("vox")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 56, weight: .black))

            Text("走る人の知恵が、走る人を強くする。")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
        }
    }

    private var illustration: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        Color.white.opacity(0.3 - Double(index) * 0.06),
                        lineWidth: 2
                    )
                    .frame(
                        width: 220 - CGFloat(index) * 32,
                        height: 220 - CGFloat(index) * 32
                    )
            }
            Text("🏃‍♂️")
                .font(.system(size: 72))
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                showEmailSignup = true
            } label: {
                Label("メールではじめる", systemImage: "envelope.fill")
            }
            .buttonStyle(RunvoxPrimaryButtonStyle())
            .background(
                // プライマリボタンは Cyan で目立たせる（ダーク背景なので)
                RoundedRectangle(cornerRadius: 12)
                    .fill(RunvoxColors.primary)
                    .opacity(0)
            )

            Button {
                showEmailLogin = true
            } label: {
                Text("ログイン")
            }
            .buttonStyle(RunvoxOutlineDarkButtonStyle())

            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
                Text("または")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.5))
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: 1)
            }
            .padding(.vertical, 4)

            Button {
                Task { await signInWithApple() }
            } label: {
                HStack(spacing: 8) {
                    if isAppleLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "applelogo")
                            .font(.system(size: 16))
                        Text("Apple ではじめる")
                    }
                }
            }
            .buttonStyle(RunvoxOutlineDarkButtonStyle())
            .disabled(isAppleLoading)
        }
    }

    private var terms: some View {
        VStack(spacing: 2) {
            Text("続行することで、")
                .foregroundStyle(Color.white.opacity(0.5))
            HStack(spacing: 4) {
                Link("利用規約", destination: URL(string: "https://runvox.app/terms")!)
                Text("と")
                    .foregroundStyle(Color.white.opacity(0.5))
                Link("プライバシーポリシー", destination: URL(string: "https://runvox.app/privacy")!)
                Text("に同意したものとみなされます")
                    .foregroundStyle(Color.white.opacity(0.5))
            }
        }
        .font(.system(size: 10))
        .multilineTextAlignment(.center)
        .tint(RunvoxColors.primary)
        .padding(.top, 12)
    }

    // MARK: - Actions

    private func signInWithApple() async {
        isAppleLoading = true
        defer { isAppleLoading = false }
        do {
            try await auth.signInWithApple()
        } catch {
            errorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthService.previewSignedOut())
}
