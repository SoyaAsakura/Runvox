import SwiftUI

/// 回答投稿画面
struct PostAnswerView: View {
    @StateObject private var viewModel: PostAnswerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardAlert = false

    private let onPosted: (Answer) -> Void

    init(
        question: Question,
        answerer: User,
        onPosted: @escaping (Answer) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: PostAnswerViewModel(
            question: question,
            answerer: answerer
        ))
        self.onPosted = onPosted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                VStack(spacing: 0) {
                    questionContext
                    myRankBar
                    editor

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 0)
                    submitFooter
                }
            }
            .navigationTitle("回答する")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { closeButton }
            }
            .alert("下書きを破棄しますか？", isPresented: $showDiscardAlert) {
                Button("破棄する", role: .destructive) { dismiss() }
                Button("入力を続ける", role: .cancel) {}
            } message: {
                Text("入力した回答は失われます")
            }
        }
    }

    // MARK: - Question context

    private var questionContext: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("回答する質問")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(RunvoxColors.primaryDark)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text(viewModel.question.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
                .lineLimit(2)
            HStack(spacing: 6) {
                CategoryChip(label: viewModel.question.category.displayName, size: .small)
                Text("・\(viewModel.question.askerNickname)")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [RunvoxColors.bgTint, RunvoxColors.bgPage],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(alignment: .bottom) {
            Rectangle().fill(RunvoxColors.border).frame(height: 1)
        }
    }

    // MARK: - My rank bar

    private var myRankBar: some View {
        HStack(spacing: 10) {
            RankBadge(rank: viewModel.effectiveRank, size: 28)
            VStack(alignment: .leading, spacing: 1) {
                Text("あなた（\(viewModel.answerer.displayName)）として回答")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
                Text("\(viewModel.effectiveRank.rawValue) ランク × ポイント歩率 \(String(format: "%.1f", viewModel.effectiveRank.multiplier))")
                    .font(.system(size: 10))
                    .foregroundStyle(RunvoxColors.subtext)
            }
            Spacer()
            maxPointsPill
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
        .overlay(alignment: .bottom) {
            Rectangle().fill(RunvoxColors.borderSoft).frame(height: 1)
        }
    }

    private var maxPointsPill: some View {
        Text("最大 +\(viewModel.maxPossiblePoints)pt")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: 0x7A5B0E))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: 0xFFF8E6))
            .clipShape(Capsule())
    }

    // MARK: - Editor

    private var editor: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextEditor(text: $viewModel.body)
                .font(.system(size: 14))
                .lineSpacing(6)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(.white)
                .overlay(alignment: .topLeading) {
                    if viewModel.body.isEmpty {
                        Text(placeholderText)
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0xB8CDD0))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 220)

            HStack {
                Text(charCountMessage)
                    .font(.system(size: 10))
                    .foregroundStyle(charCountColor)
                Spacer()
                Text("\(viewModel.bodyCharCount) / \(PostAnswerViewModel.bodyLimit)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(
                        viewModel.bodyCharCount > PostAnswerViewModel.bodyLimit
                            ? RunvoxColors.danger
                            : RunvoxColors.subtext
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var placeholderText: String {
        """
        質問者の役に立つ具体的な回答を書きましょう。

        ・経験ベースの知見
        ・具体的な数値・頻度
        ・注意点も添えると喜ばれます
        """
    }

    private var charCountMessage: String {
        if viewModel.trimmedBodyLength < PostAnswerViewModel.minBodyLength {
            return "あと \(PostAnswerViewModel.minBodyLength - viewModel.trimmedBodyLength) 文字以上で投稿可能"
        }
        return "投稿準備 OK"
    }

    private var charCountColor: Color {
        viewModel.trimmedBodyLength < PostAnswerViewModel.minBodyLength
            ? RunvoxColors.subtext
            : RunvoxColors.success
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

    // MARK: - Submit footer

    private var submitFooter: some View {
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
        .padding(.top, 8)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [
                    RunvoxColors.bgPage.opacity(0),
                    RunvoxColors.bgPage,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Close

    private var closeButton: some View {
        Button {
            if !viewModel.body.isEmpty {
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

    // MARK: - Action

    private func submit() async {
        if let posted = await viewModel.submit() {
            onPosted(posted)
            dismiss()
        }
    }
}

#Preview {
    PostAnswerView(
        question: MockQuestionRepository.defaultSamples[0],
        answerer: User(
            id: "u-me",
            email: "me@example.com",
            nickname: "田中健太",
            realName: "田中 健太",
            bio: "元実業団 / JAAF公認指導員",
            role: .answerer,
            rank: .s
        )
    ) { _ in }
}
