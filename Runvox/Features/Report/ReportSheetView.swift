import SwiftUI

/// 通報モーダル（質問詳細の ⋯ メニューから提示）
struct ReportSheetView: View {
    @StateObject private var viewModel: ReportViewModel
    @Environment(\.dismiss) private var dismiss
    private let onSubmitted: () -> Void

    init(
        targetType: ReportTargetType,
        targetId: String,
        reporterId: String,
        onSubmitted: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: ReportViewModel(
            targetType: targetType,
            targetId: targetId,
            reporterId: reporterId
        ))
        self.onSubmitted = onSubmitted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        reasonList
                        commentField
                        if let error = viewModel.errorMessage {
                            errorBanner(error)
                        }
                        submitButton
                        Color.clear.frame(height: 12)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("\(viewModel.targetType.displayName)を通報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(RunvoxColors.ink)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "flag.fill")
                .font(.system(size: 13))
                .foregroundStyle(RunvoxColors.danger)
                .padding(.top, 1)
            Text("理由を選択してください。通報は運営に送られ、48 時間以内に確認します。内容は\(viewModel.targetType.displayName)の投稿者には通知されません。")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xFDE8EA).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var reasonList: some View {
        VStack(spacing: 0) {
            ForEach(Array(ReportReason.allCases.enumerated()), id: \.element.id) { index, reason in
                Button {
                    viewModel.selectedReason = reason
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: viewModel.selectedReason == reason
                              ? "largecircle.fill.circle"
                              : "circle")
                            .font(.system(size: 18))
                            .foregroundStyle(viewModel.selectedReason == reason
                                             ? RunvoxColors.primaryDark
                                             : RunvoxColors.border)
                        Text(reason.label)
                            .font(.system(size: 14))
                            .foregroundStyle(RunvoxColors.ink)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if index < ReportReason.allCases.count - 1 {
                    Divider().padding(.leading, 46)
                }
            }
        }
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var commentField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("補足（任意）")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
                Spacer()
                Text("\(viewModel.comment.count) / \(ReportViewModel.maxCommentLength)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(
                        viewModel.comment.count > ReportViewModel.maxCommentLength
                            ? RunvoxColors.danger
                            : RunvoxColors.subtext
                    )
            }
            TextEditor(text: $viewModel.comment)
                .font(.system(size: 13))
                .frame(minHeight: 80)
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

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill").font(.system(size: 14))
                Text("通報する")
            }
        }
        .buttonStyle(RunvoxPrimaryButtonStyle(
            isLoading: viewModel.isSubmitting,
            isEnabled: viewModel.canSubmit
        ))
        .disabled(!viewModel.canSubmit)
        .padding(.top, 4)
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

    private func submit() async {
        if await viewModel.submit() {
            onSubmitted()
            dismiss()
        }
    }
}

#Preview {
    Color.gray
        .sheet(isPresented: .constant(true)) {
            ReportSheetView(
                targetType: .question,
                targetId: "q1",
                reporterId: "u1",
                onSubmitted: {}
            )
            .presentationDetents([.large])
        }
}
