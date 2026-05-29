import SwiftUI

/// プロフィール編集画面（マイページから push）
struct ProfileEditView: View {
    @StateObject private var viewModel: ProfileEditViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showSavedToast = false

    init(auth: AuthService) {
        _viewModel = StateObject(wrappedValue: ProfileEditViewModel(auth: auth))
    }

    var body: some View {
        ZStack(alignment: .top) {
            RunvoxColors.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    nicknameGroup
                    bioGroup
                    if viewModel.canToggleAnonymous {
                        anonymousGroup
                    }
                    emailGroup
                    if let error = viewModel.generalError {
                        errorBanner(error)
                    }
                    saveButton
                    Color.clear.frame(height: 12)
                }
                .padding(16)
            }

            if showSavedToast {
                savedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("プロフィール編集")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Fields

    private var nicknameGroup: some View {
        fieldCard {
            RunvoxTextField(
                title: "ニックネーム",
                placeholder: "ランナー太郎",
                text: $viewModel.nickname,
                contentType: .nickname,
                errorMessage: viewModel.nicknameError
            )
        }
    }

    private var bioGroup: some View {
        fieldCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("自己紹介")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(RunvoxColors.inkSoft)
                    Spacer()
                    Text("\(viewModel.bioCharCount) / \(ProfileEditViewModel.maxBioLength)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(
                            viewModel.bioCharCount > ProfileEditViewModel.maxBioLength
                                ? RunvoxColors.danger
                                : RunvoxColors.subtext
                        )
                }
                TextEditor(text: $viewModel.bio)
                    .font(.system(size: 14))
                    .frame(minHeight: 90)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(RunvoxColors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var anonymousGroup: some View {
        fieldCard {
            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $viewModel.isAnonymous) {
                    Text("匿名で活動する")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(RunvoxColors.ink)
                }
                .tint(RunvoxColors.primaryDark)
                Text("B ランクは匿名で活動できます。ON にするとニックネームのみ表示されます。")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
    }

    private var emailGroup: some View {
        fieldCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("メールアドレス")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RunvoxColors.inkSoft)
                HStack {
                    Text(viewModel.email)
                        .font(.system(size: 13))
                        .foregroundStyle(RunvoxColors.subtext)
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(RunvoxColors.subtext)
                }
                Text("メールアドレスは変更できません")
                    .font(.system(size: 10))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
    }

    private var saveButton: some View {
        Button {
            Task { await save() }
        } label: {
            Text("保存する")
        }
        .buttonStyle(RunvoxPrimaryButtonStyle(
            isLoading: viewModel.isSaving,
            isEnabled: viewModel.canSave
        ))
        .disabled(!viewModel.canSave)
        .padding(.top, 4)
    }

    // MARK: - Building blocks

    private func fieldCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12))
            .foregroundStyle(RunvoxColors.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(hex: 0xFDE8EA))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var savedToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(RunvoxColors.success)
            Text("プロフィールを保存しました")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.success.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func save() async {
        if await viewModel.save() {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSavedToast = true
            }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                dismiss()
            }
        }
    }
}

#Preview("Questioner") {
    NavigationStack {
        ProfileEditView(auth: AuthService.previewSignedIn())
    }
}

#Preview("B-rank answerer") {
    var user = User.preview
    user.role = .answerer
    user.rank = .b
    user.isAnonymous = true
    return NavigationStack {
        ProfileEditView(auth: AuthService.previewSignedIn(user))
    }
}
