import SwiftUI

@main
struct RunvoxApp: App {
    @StateObject private var authService: AuthService

    init() {
        // Firebase 初期化は backend 生成より「先」に行う
        FirebaseBootstrap.configureIfAvailable()
        _authService = StateObject(
            wrappedValue: AuthService(backend: BackendFactory.makeAuthBackend())
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}
