import SwiftUI

/// マイページ / 設定画面
///
/// プロフィール表示 + 設定項目 + ログアウト
struct MyPageView: View {
    @EnvironmentObject private var auth: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutConfirm = false
    @State private var showWithdrawConfirm = false
    @State private var isSigningOut = false
    @State private var pendingActionAlert: String?

    private static let appVersion: String = {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileCard
                        pointsGroup
                        accountGroup
                        supportGroup
                        appInfoGroup
                        signOutGroup
                        withdrawButton
                        Color.clear.frame(height: 12)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("マイページ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: MyPageRoute.self) { route in
                switch route {
                case .pointsDashboard(let userId):
                    PointsDashboardView(userId: userId)
                case .reviewerApplication(let userId):
                    ReviewerApplicationView(userId: userId)
                case .profileEdit:
                    ProfileEditView(auth: auth)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(RunvoxColors.ink)
                }
            }
            .confirmationDialog(
                "ログアウトしますか？",
                isPresented: $showSignOutConfirm,
                titleVisibility: .visible
            ) {
                Button("ログアウト", role: .destructive) {
                    Task { await signOut() }
                }
                Button("キャンセル", role: .cancel) {}
            }
            .alert("退会の手続き", isPresented: $showWithdrawConfirm) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("退会フローは後続 PR で実装予定です。\n質問・回答データの扱いも含めて慎重に設計します。")
            }
            .alert(
                "未実装",
                isPresented: Binding(
                    get: { pendingActionAlert != nil },
                    set: { if !$0 { pendingActionAlert = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pendingActionAlert ?? "")
            }
        }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        VStack(spacing: 14) {
            Avatar(
                initial: String((auth.currentUser?.displayName ?? "?").prefix(1)),
                size: 84,
                rank: auth.currentUser?.rank
            )
            VStack(spacing: 4) {
                Text(auth.currentUser?.displayName ?? "未ログイン")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(RunvoxColors.ink)
                if let email = auth.currentUser?.email {
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundStyle(RunvoxColors.subtext)
                }
            }
            roleTags
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var roleTags: some View {
        HStack(spacing: 6) {
            roleChip(text: auth.currentUser?.role.displayLabel ?? "ゲスト")
            if let rank = auth.currentUser?.rank {
                rankChip(rank: rank)
            }
        }
    }

    private func roleChip(text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(RunvoxColors.primaryDark)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(RunvoxColors.bgTint)
            .clipShape(Capsule())
    }

    private func rankChip(rank: Rank) -> some View {
        HStack(spacing: 4) {
            Text(rank.rawValue)
            Text("ランク")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(rank.gradient)
        .clipShape(Capsule())
    }

    // MARK: - Groups

    @ViewBuilder
    private var pointsGroup: some View {
        if let userId = auth.currentUser?.id {
            SettingsGroup("マイポイント") {
                NavigationLink(value: MyPageRoute.pointsDashboard(userId: userId)) {
                    SettingsRowLabel(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "ポイント残高 / 履歴",
                        subtitle: pointsSubtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pointsSubtitle: String {
        if auth.currentUser?.role == .answerer {
            return "回答に評価が付くと加算されます"
        }
        return "回答者になると獲得できます"
    }

    private var accountGroup: some View {
        SettingsGroup("アカウント") {
            NavigationLink(value: MyPageRoute.profileEdit) {
                SettingsRowLabel(
                    icon: "person.fill",
                    title: "プロフィール編集"
                )
            }
            .buttonStyle(.plain)
            Divider().padding(.leading, 60)
            SettingsRow(
                icon: "bell.fill",
                title: "通知設定"
            ) { pendingActionAlert = "通知設定画面は後続 PR で実装予定です" }
            if auth.currentUser?.role == .questioner,
               let userId = auth.currentUser?.id {
                Divider().padding(.leading, 60)
                NavigationLink(value: MyPageRoute.reviewerApplication(userId: userId)) {
                    SettingsRowLabel(
                        icon: "checkmark.seal.fill",
                        title: "回答者として申請",
                        subtitle: "ランナーコーチ・経験者の方へ"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var supportGroup: some View {
        SettingsGroup("サポート") {
            externalLinkRow(
                icon: "doc.text.fill",
                title: "利用規約",
                url: "https://runvox.app/terms"
            )
            Divider().padding(.leading, 60)
            externalLinkRow(
                icon: "lock.fill",
                title: "プライバシーポリシー",
                url: "https://runvox.app/privacy"
            )
            Divider().padding(.leading, 60)
            SettingsRow(
                icon: "envelope.fill",
                title: "お問い合わせ"
            ) { pendingActionAlert = "お問い合わせフォームは後続 PR で実装予定です" }
        }
    }

    private var appInfoGroup: some View {
        SettingsGroup("アプリ情報") {
            SettingsRow(
                icon: "info.circle.fill",
                title: "バージョン",
                trailingText: Self.appVersion,
                showsChevron: false
            ) {}
        }
    }

    private var signOutGroup: some View {
        SettingsGroup {
            SettingsRow(
                icon: "rectangle.portrait.and.arrow.right",
                title: isSigningOut ? "ログアウト中..." : "ログアウト",
                destructive: true
            ) { showSignOutConfirm = true }
        }
        .disabled(isSigningOut)
    }

    private var withdrawButton: some View {
        Button {
            showWithdrawConfirm = true
        } label: {
            Text("退会する")
                .font(.system(size: 11))
                .foregroundStyle(RunvoxColors.subtext)
                .underline()
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func externalLinkRow(icon: String, title: String, url: String) -> some View {
        if let link = URL(string: url) {
            Link(destination: link) {
                SettingsRowLabel(icon: icon, title: title)
            }
            .buttonStyle(.plain)
        } else {
            SettingsRowLabel(icon: icon, title: title)
        }
    }

    // MARK: - Actions

    private func signOut() async {
        isSigningOut = true
        defer { isSigningOut = false }
        do {
            try await auth.signOut()
            dismiss()
        } catch {
            pendingActionAlert = error.localizedDescription
        }
    }
}

/// マイページ内の遷移先
enum MyPageRoute: Hashable {
    case pointsDashboard(userId: String)
    case reviewerApplication(userId: String)
    case profileEdit
}

#Preview("Signed In B-rank") {
    MyPageView()
        .environmentObject(AuthService.previewSignedIn())
}

#Preview("Signed In S-rank") {
    var user = User.preview
    user.role = .answerer
    user.rank = .s
    user.realName = "田中 健太"
    user.bio = "元実業団 / JAAF公認指導員"
    return MyPageView()
        .environmentObject(AuthService.previewSignedIn(user))
}
