import SwiftUI

/// アプリのルート。認証状態に応じて画面を切り替える
struct ContentView: View {
    var body: some View {
        AuthRootView { user in
            SignedInPlaceholderView(user: user)
        }
    }
}

/// ログイン後に表示する仮の画面（後続 PR でホーム画面に置き換え）
struct SignedInPlaceholderView: View {
    @EnvironmentObject private var auth: AuthService
    let user: User

    @State private var isSigningOut = false

    var body: some View {
        ZStack {
            RunvoxColors.bgPage.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(RunvoxColors.success)

                Text("ようこそ、\(user.nickname) さん 👋")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(RunvoxColors.ink)

                Text(user.email)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.subtext)

                Spacer()

                Text("ここにホーム画面が入ります")
                    .font(.system(size: 13))
                    .foregroundStyle(RunvoxColors.subtext)

                Button {
                    Task { await signOut() }
                } label: {
                    if isSigningOut {
                        ProgressView().tint(.white)
                    } else {
                        Text("ログアウト")
                    }
                }
                .buttonStyle(RunvoxPrimaryButtonStyle(isLoading: isSigningOut))
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        try? await auth.signOut()
    }
}

#Preview("Signed In") {
    ContentView()
        .environmentObject(AuthService.previewSignedIn())
}

#Preview("Signed Out") {
    ContentView()
        .environmentObject(AuthService.previewSignedOut())
}
