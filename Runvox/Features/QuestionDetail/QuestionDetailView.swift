import SwiftUI

/// 質問詳細画面
struct QuestionDetailView: View {
    @StateObject private var viewModel: QuestionDetailViewModel
    @State private var pendingActionAlert: String?

    init(question: Question) {
        _viewModel = StateObject(wrappedValue: QuestionDetailViewModel(question: question))
    }

    var body: some View {
        ZStack {
            RunvoxColors.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    questionSection
                    sectionDivider
                    answerSection
                    Color.clear.frame(height: 100)
                }
                .padding(.top, 8)
            }

            actionFooter
        }
        .navigationTitle("質問詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) { menuButton }
        }
        .task { await viewModel.loadAnswerIfNeeded() }
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

    // MARK: - Question section

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryChip(label: viewModel.question.category.displayName)
                StatusPill(status: viewModel.question.status)
            }

            Text(viewModel.question.title)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(RunvoxColors.ink)
                .lineSpacing(4)

            Text(viewModel.question.body)
                .font(.system(size: 13))
                .foregroundStyle(RunvoxColors.inkSoft)
                .lineSpacing(6)
                .padding(.top, 4)

            HStack(spacing: 10) {
                Avatar(initial: String(viewModel.question.askerNickname.prefix(1)), size: 28)
                Text(viewModel.question.askerNickname)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RunvoxColors.ink)
                Text("・\(viewModel.question.relativeCreatedAt)")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
                Spacer()
            }
            .padding(.top, 8)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(RunvoxColors.borderSoft)
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 20)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(RunvoxColors.borderSoft)
            .frame(height: 6)
    }

    // MARK: - Answer section

    private var answerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "回答",
                count: viewModel.answer == nil ? 0 : 1,
                systemIcon: "bubble.left"
            )

            answerContent
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var answerContent: some View {
        if viewModel.isLoadingAnswer {
            loadingPlaceholder
        } else if let error = viewModel.errorMessage {
            errorState(message: error)
        } else if let answer = viewModel.answer {
            AnswerCard(answer: answer)
        } else if viewModel.shouldHaveAnswer {
            // status は answered だが取得できなかったケース
            Text("回答を読み込めませんでした")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
                .frame(maxWidth: .infinity)
                .padding(40)
        } else {
            emptyAnswerState
        }
    }

    private var loadingPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(RunvoxColors.border)
            )
            .frame(height: 180)
            .opacity(0.6)
    }

    private var emptyAnswerState: some View {
        VStack(spacing: 10) {
            Text("💬")
                .font(.system(size: 36))
            Text("まだ回答がありません")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Text("早い者勝ち！\n最初に回答した1名のみがポイントを獲得できます")
                .font(.system(size: 11))
                .foregroundStyle(RunvoxColors.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    RunvoxColors.border,
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26))
                .foregroundStyle(RunvoxColors.danger)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.ink)
            Button("再試行") {
                Task { await viewModel.retry() }
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(RunvoxColors.primaryDark)
            .foregroundStyle(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }

    // MARK: - Action footer (sticky bottom)

    @ViewBuilder
    private var actionFooter: some View {
        if let cta = primaryCTA {
            VStack {
                Spacer()
                Button {
                    pendingActionAlert = cta.placeholderMessage
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: cta.icon)
                            .font(.system(size: 16, weight: .bold))
                        Text(cta.title)
                    }
                }
                .buttonStyle(RunvoxPrimaryButtonStyle())
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
    }

    private var primaryCTA: ActionCTA? {
        if viewModel.canShowAnswerCTA {
            return .answer
        } else if viewModel.canShowRateCTA {
            return .rate
        }
        return nil
    }

    // MARK: - Top-right menu

    private var menuButton: some View {
        Menu {
            Button(role: .destructive) {
                pendingActionAlert = "通報フローは後続 PR で実装予定です"
            } label: {
                Label("通報する", systemImage: "flag")
            }
            Button {
                UIPasteboard.general.string = viewModel.question.title
            } label: {
                Label("タイトルをコピー", systemImage: "doc.on.doc")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
        }
    }
}

// MARK: - Action CTA enum

private enum ActionCTA {
    case answer
    case rate

    var title: String {
        switch self {
        case .answer: return "この質問に回答する"
        case .rate:   return "回答を評価する"
        }
    }

    var icon: String {
        switch self {
        case .answer: return "arrow.right.circle.fill"
        case .rate:   return "star.fill"
        }
    }

    var placeholderMessage: String {
        switch self {
        case .answer: return "回答投稿フローは後続 PR で実装予定です"
        case .rate:   return "評価モーダルは後続 PR で実装予定です"
        }
    }
}

#Preview("Waiting") {
    NavigationStack {
        QuestionDetailView(question: MockQuestionRepository.defaultSamples[0])
    }
}

#Preview("Answered (rated)") {
    NavigationStack {
        QuestionDetailView(question: MockQuestionRepository.defaultSamples[1])
    }
}

#Preview("Answered (unrated)") {
    NavigationStack {
        QuestionDetailView(question: MockQuestionRepository.defaultSamples[2])
    }
}
