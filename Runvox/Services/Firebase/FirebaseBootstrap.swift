import FirebaseCore
import Foundation

/// Firebase の起動制御
///
/// `GoogleService-Info.plist` が存在する時だけ `FirebaseApp.configure()` を実行する。
/// plist が無い環境（CI / plist 未配置の開発者）ではクラッシュさせず Mock で動かす。
enum FirebaseBootstrap {
    /// plist が存在し Firebase を使える状態か
    static let isAvailable: Bool = {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }()

    /// plist があれば Firebase を初期化する。アプリ起動の最初に 1 回だけ呼ぶ。
    static func configureIfAvailable() {
        guard isAvailable else {
            #if DEBUG
            print("[Firebase] GoogleService-Info.plist が無いため Mock モードで起動します")
            #endif
            return
        }
        FirebaseApp.configure()
    }
}
