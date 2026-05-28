import SwiftUI

/// アプリのルート。認証状態に応じて画面を切り替える
struct ContentView: View {
    var body: some View {
        AuthRootView { _ in
            HomeView()
        }
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
