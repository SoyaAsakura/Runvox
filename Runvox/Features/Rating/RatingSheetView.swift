import SwiftUI

/// 評価入力モーダル（質問詳細画面から提示）
struct RatingSheetView: View {
    @StateObject private var viewModel: RatingViewModel
    @Environment(\.dismiss) private var dismiss

    /// 評価成功時に呼ばれるコールバック
    private let onRated: (RatingResult) -> Void

    init(answer: Answer, onRated: @escaping (RatingResult) -> Void) {
        _viewModel = StateObject(wrappedValue: RatingViewModel(answer: answer))
        self.onRated = onRated
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetGrip

            ScrollView {
                VStack(spacing: 18) {
                    targetCard
                    titleBlock
                    StarPicker(rating: $viewModel.selectedStars)
                        .padding(.vertical, 8)
                    ratingValueRow
                    rewardCalcCard
                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }

            actionButtons
                .padding(.horizontal, 20)

            Text("確定後は変更できません")
                .font(.system(size: 10))
                .foregroundStyle(RunvoxColors.subtext)
                .padding(.top, 8)
                .padding(.bottom, 24)
        }
        .background(.white)
    }

    // MARK: - Sheet grip

    private var sheetGrip: some View {
        Capsule()
            .fill(RunvoxColors.border)
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 16)
    }

    // MARK: - Target card

    private var targetCard: some View {
        HStack(spacing: 12) {
            Avatar(
                initial: String(viewModel.answer.answererNickname.prefix(1)),
                size: 36,
                rank: viewModel.answer.answererRank
            )
            VStack(alignment: .leading, spacing: 2) {
                Text("この回答を評価")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
                Text(viewModel.answer.answererNickname)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
            }
            Spacer()
        }
        .padding(12)
        .background(RunvoxColors.bgPage)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Title block

    private var titleBlock: some View {
        VStack(spacing: 4) {
            Text("回答はいかがでしたか？")
                .font(.system(size: 17, weight: .black))
                .foregroundStyle(RunvoxColors.ink)
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                Text("評価は1回のみ。あとから変更できません")
                    .font(.system(size: 11))
            }
            .foregroundStyle(RunvoxColors.warning)
        }
    }

    // MARK: - Selected value row

    @ViewBuilder
    private var ratingValueRow: some View {
        HStack(spacing: 10) {
            Group {
                Text("\(viewModel.selectedStars)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(RunvoxColors.ink)
                + Text(" / 5")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(RunvoxColors.subtext)
            }
            if let label = viewModel.qualitativeLabel {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(RunvoxColors.primaryDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(RunvoxColors.bgTint)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Reward calc card

    private var rewardCalcCard: some View {
        VStack(spacing: 10) {
            Label("回答者への付与ポイント", systemImage: "gift.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(hex: 0x7A5B0E))

            HStack(spacing: 4) {
                calcPart(value: "\(viewModel.previewBasePoints)", label: "★\(viewModel.selectedStars) 評価")
                calcOp("×")
                calcPart(
                    value: String(format: "%.1f", viewModel.previewMultiplier),
                    label: "\(viewModel.answer.answererRank.rawValue) ランク"
                )
                calcOp("=")
                calcPart(
                    value: "\(viewModel.previewPoints)",
                    label: "pt",
                    highlight: true
                )
            }

            Divider().background(Color(hex: 0xD6B66E))

            VStack(spacing: 2) {
                Text("回答者に付与されるポイント")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: 0x7A5B0E))
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(viewModel.previewPoints)")
                        .font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: 0x4A3810))
                    Text("pt")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(hex: 0x4A3810))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xFFF8E6), Color(hex: 0xFFEFC4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xF2D89B), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(viewModel.selectedStars == 0 ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedStars)
    }

    private func calcPart(value: String, label: String, highlight: Bool = false) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(highlight ? Color(hex: 0xB07A1A) : Color(hex: 0x4A3810))
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: 0x7A5B0E))
        }
        .frame(maxWidth: .infinity)
    }

    private func calcOp(_ symbol: String) -> some View {
        Text(symbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(Color(hex: 0xB07A1A))
    }

    // MARK: - Buttons

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("キャンセル") { dismiss() }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(.white)
                .foregroundStyle(RunvoxColors.inkSoft)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RunvoxColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .font(.system(size: 14, weight: .bold))

            Button {
                Task { await confirm() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text("評価を確定する")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(viewModel.canSubmit ? RunvoxColors.primaryDark : RunvoxColors.border)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .disabled(!viewModel.canSubmit)
            // 確定ボタンを少し広めに
            .layoutPriority(1)
        }
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

    // MARK: - Actions

    private func confirm() async {
        if let result = await viewModel.submit() {
            onRated(result)
            dismiss()
        }
    }
}

#Preview {
    if let answer = MockAnswerRepository.defaultAnswers["q3"] {
        return AnyView(
            Color.gray
                .sheet(isPresented: .constant(true)) {
                    RatingSheetView(answer: answer) { _ in }
                        .presentationDetents([.medium, .large])
                }
        )
    }
    return AnyView(Text("No sample answer"))
}
