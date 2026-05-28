import SwiftUI

/// 質問投稿画面
struct PostQuestionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PostQuestionViewModel
    private let onPosted: (Question) -> Void
    @State private var showDiscardAlert = false

    init(asker: User, onPosted: @escaping (Question) -> Void) {
        _viewModel = StateObject(wrappedValue: PostQuestionViewModel(asker: asker))
        self.onPosted = onPosted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        categoryGroup
                        titleGroup
                        bodyGroup

                        if let error = viewModel.generalError {
                            errorBanner(error)
                        }

                        Color.clear.frame(height: 120)
                    }
                }

                submitFooter
            }
            .navigationTitle("質問する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { closeButton }
            }
            .alert("下書きを破棄しますか？", isPresented: $showDiscardAlert) {
                Button("破棄する", role: .destructive) { dismiss() }
                Button("入力を続ける", role: .cancel) {}
            } message: {
                Text("入力した内容は失われます")
            }
        }
    }

    // MARK: - Sections

    private var categoryGroup: some View {
        formGroup(
            title: "カテゴリ",
            required: true,
            error: viewModel.categoryError
        ) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ],
                spacing: 8
            ) {
                ForEach(QuestionCategory.allCases) { category in
                    CategoryTile(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private var titleGroup: some View {
        formGroup(
            title: "タイトル",
            required: true,
            error: viewModel.titleError
        ) {
            TextField("サブ3.5を狙うための30km走の頻度は？", text: $viewModel.title)
                .font(.system(size: 14))
                .padding(12)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(titleBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Spacer()
                Text("\(viewModel.titleCharCount) / \(PostQuestionViewModel.titleLimit)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(
                        viewModel.titleCharCount > PostQuestionViewModel.titleLimit
                            ? RunvoxColors.danger
                            : RunvoxColors.subtext
                    )
            }
        }
    }

    private var bodyGroup: some View {
        formGroup(
            title: "本文",
            required: false,
            error: viewModel.bodyError
        ) {
            TextEditor(text: $viewModel.body)
                .font(.system(size: 14))
                .lineSpacing(4)
                .frame(minHeight: 160)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(bodyBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack {
                Text("陸上競技に関する内容のみ投稿できます")
                    .font(.system(size: 10))
                    .foregroundStyle(RunvoxColors.primaryDark)
                Spacer()
                Text("\(viewModel.bodyCharCount) / \(PostQuestionViewModel.bodyLimit)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(
                        viewModel.bodyCharCount > PostQuestionViewModel.bodyLimit
                            ? RunvoxColors.danger
                            : RunvoxColors.subtext
                    )
            }
        }
    }

    private var titleBorderColor: Color {
        viewModel.titleError != nil ? RunvoxColors.danger : RunvoxColors.border
    }

    private var bodyBorderColor: Color {
        viewModel.bodyError != nil ? RunvoxColors.danger : RunvoxColors.border
    }

    // MARK: - Building blocks

    private func formGroup<Content: View>(
        title: String,
        required: Bool,
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
                if required {
                    Text("必須")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(RunvoxColors.danger)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xFDE8EA))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            content()

            if let error {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.danger)
            }
        }
        .padding(16)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(RunvoxColors.borderSoft)
                .frame(height: 1)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(RunvoxColors.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color(hex: 0xFDE8EA))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 16)
            .padding(.top, 12)
    }

    // MARK: - Footer

    private var submitFooter: some View {
        VStack {
            Spacer()
            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 15))
                    Text("投稿する")
                }
            }
            .buttonStyle(RunvoxPrimaryButtonStyle(
                isLoading: viewModel.isSubmitting,
                isEnabled: viewModel.canSubmit
            ))
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    colors: [
                        RunvoxColors.bgPage.opacity(0),
                        RunvoxColors.bgPage,
                        RunvoxColors.bgPage,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
        }
    }

    private var closeButton: some View {
        Button {
            if hasUnsavedChanges {
                showDiscardAlert = true
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
        }
    }

    private var hasUnsavedChanges: Bool {
        !viewModel.title.isEmpty
            || !viewModel.body.isEmpty
            || viewModel.selectedCategory != nil
    }

    // MARK: - Actions

    private func submit() async {
        if let posted = await viewModel.submit() {
            onPosted(posted)
            dismiss()
        }
    }
}

#Preview {
    PostQuestionView(asker: .preview) { _ in }
}
