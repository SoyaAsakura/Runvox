import SwiftUI

/// 認証状態に応じてサインイン画面 / アプリ本体を切り替えるルートビュー
struct AuthRootView<SignedInContent: View>: View {
    @EnvironmentObject private var auth: AuthService

    @ViewBuilder var signedInContent: (User) -> SignedInContent

    var body: some View {
        ZStack {
            switch auth.state {
            case .loading:
                loadingView
                    .transition(.opacity)
            case .signedOut:
                WelcomeView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            case .signedIn(let user):
                signedInContent(user)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: auth.state)
    }

    private var loadingView: some View {
        ZStack {
            LinearGradient(
                colors: [RunvoxColors.ink, RunvoxColors.primaryDark],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Text("Run").foregroundStyle(.white)
                    Text(".").foregroundStyle(RunvoxColors.primary)
                    Text("vox").foregroundStyle(.white)
                }
                .font(.system(size: 40, weight: .black))

                ProgressView()
                    .tint(.white)
            }
        }
    }
}

#Preview("Loading") {
    AuthRootView { user in
        Text("Signed in as \(user.nickname)")
    }
    .environmentObject({
        let s = AuthService.previewSignedOut()
        s.objectWillChange.send()
        return s
    }())
}

#Preview("Signed Out") {
    AuthRootView { user in
        Text("Signed in as \(user.nickname)")
    }
    .environmentObject(AuthService.previewSignedOut())
}

#Preview("Signed In") {
    AuthRootView { user in
        VStack {
            Text("Welcome, \(user.nickname)!")
        }
    }
    .environmentObject(AuthService.previewSignedIn())
}
