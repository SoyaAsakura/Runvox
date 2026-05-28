import SwiftUI

// swiftlint:disable type_body_length
// 既存申請の表示と新規フォームの 2 モードを 1 View に内包するため少し長い

/// 回答者審査申請画面
struct ReviewerApplicationView: View {
    @StateObject private var viewModel: ReviewerApplicationViewModel
    @State private var showSuccessToast = false

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: ReviewerApplicationViewModel(userId: userId))
    }

    var body: some View {
        ZStack(alignment: .top) {
            RunvoxColors.bgPage.ignoresSafeArea()
            content
            if showSuccessToast { successToast }
        }
        .navigationTitle("回答者申請")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.application == nil {
            ProgressView().padding(40)
        } else {
            ScrollView {
                VStack(spacing: 16) {
                    statusCard
                    if let app = viewModel.application {
                        existingApplicationCard(app)
                    }
                    if viewModel.shouldShowForm {
                        formSection
                    }
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Status card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("審査ステータス")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)
                Spacer()
                statusBadge
            }
            ApplicationStepper(status: currentStatus)
        }
        .padding(.horizontal, 16)
    }

    private var currentStatus: ApplicationStatus {
        viewModel.application?.status ?? .notSubmitted
    }

    private var statusBadge: some View {
        Text(currentStatus.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(statusBadgeForeground)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusBadgeBackground)
            .clipShape(Capsule())
    }

    private var statusBadgeForeground: Color {
        switch currentStatus {
        case .notSubmitted:        return RunvoxColors.subtext
        case .submitted, .reviewing: return RunvoxColors.primaryDark
        case .approved:            return RunvoxColors.success
        case .rejected:            return RunvoxColors.danger
        }
    }

    private var statusBadgeBackground: Color {
        switch currentStatus {
        case .notSubmitted:        return RunvoxColors.bgPage
        case .submitted, .reviewing: return RunvoxColors.bgTint
        case .approved:            return Color(hex: 0xDFF5E5)
        case .rejected:            return Color(hex: 0xFDE8EA)
        }
    }

    // MARK: - Existing application card

    private func existingApplicationCard(_ app: ReviewerApplication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 11))
                Text("申請内容")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(RunvoxColors.ink)

            VStack(alignment: .leading, spacing: 12) {
                applicationField(label: "実績", text: app.achievements)
                if !app.certifications.isEmpty {
                    Divider()
                    applicationField(label: "資格・指導経歴", text: app.certifications)
                }
                if let url = app.referenceURL {
                    Divider()
                    applicationField(label: "確認用 URL", text: url, link: true)
                }
                Divider()
                HStack {
                    Text("申請日")
                        .font(.system(size: 11))
                        .foregroundStyle(RunvoxColors.subtext)
                    Spacer()
                    Text(formatDate(app.submittedAt))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(RunvoxColors.ink)
                }
            }
            .padding(14)
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if app.status == .submitted || app.status == .reviewing {
                infoNote(
                    text: "目標 3 営業日以内に審査結果をご登録のメールへお送りします。",
                    color: .warning
                )
            } else if app.status == .rejected, let reason = app.rejectionReason {
                infoNote(text: "不合格理由: \(reason)", color: .danger)
                if let next = app.nextApplicationAvailableAt {
                    infoNote(
                        text: "次回申請は \(formatDate(next)) 以降に可能です",
                        color: .neutral
                    )
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private func applicationField(label: String, text: String, link: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(RunvoxColors.subtext)
                .textCase(.uppercase)
            if link, let url = URL(string: text) {
                Link(text, destination: url)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.primaryDark)
            } else {
                Text(text)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Form section

    private var formSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 11))
                Text(viewModel.hasExistingApplication ? "再申請する" : "新規申請")
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(RunvoxColors.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

            formGroup
                .padding(.horizontal, 16)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.danger)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xFDE8EA))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 16)
            }

            submitButton.padding(.horizontal, 16)

            infoNote(
                text: "送信後、運営宛に通知メールが届き、3 営業日以内に審査結果をご連絡します。",
                color: .neutral
            )
            .padding(.horizontal, 16)
        }
    }

    private var formGroup: some View {
        VStack(spacing: 0) {
            formField(
                title: "実績 (大会成績など)",
                required: true,
                trailingMeta: countMeta,
                content: AnyView(
                    TextEditor(text: $viewModel.achievements)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RunvoxColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(minHeight: 100)
                )
            )
            Divider()
            formField(
                title: "資格・指導経歴 (任意)",
                required: false,
                trailingMeta: nil,
                content: AnyView(
                    TextEditor(text: $viewModel.certifications)
                        .font(.system(size: 13))
                        .lineSpacing(4)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RunvoxColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .frame(minHeight: 70)
                )
            )
            Divider()
            formField(
                title: "実績の確認先 URL (任意)",
                required: false,
                trailingMeta: nil,
                content: AnyView(
                    TextField("https://...", text: $viewModel.referenceURL)
                        .font(.system(size: 13))
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(10)
                        .background(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(RunvoxColors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                )
            )
        }
        .background(RunvoxColors.bgPage)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var countMeta: String {
        let count = viewModel.achievementsCount
        return "\(count) / \(ReviewerApplicationViewModel.maxAchievementsLength)"
    }

    private func formField(
        title: String,
        required: Bool,
        trailingMeta: String?,
        content: AnyView
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
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
                Spacer()
                if let meta = trailingMeta {
                    Text(meta)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(RunvoxColors.subtext)
                }
            }
            content
        }
        .padding(12)
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "paperplane.fill").font(.system(size: 15))
                Text("審査を申請する")
            }
        }
        .buttonStyle(RunvoxPrimaryButtonStyle(
            isLoading: viewModel.isSubmitting,
            isEnabled: viewModel.canSubmit
        ))
        .disabled(!viewModel.canSubmit)
    }

    // MARK: - Info note

    private enum InfoNoteColor { case neutral, warning, danger }

    private struct InfoNoteStyle {
        let background: Color
        let foreground: Color
        let border: Color
    }

    private func infoNoteStyle(for color: InfoNoteColor) -> InfoNoteStyle {
        switch color {
        case .neutral:
            return InfoNoteStyle(
                background: RunvoxColors.bgPage,
                foreground: RunvoxColors.inkSoft,
                border: RunvoxColors.border
            )
        case .warning:
            return InfoNoteStyle(
                background: Color(hex: 0xFFF8E6),
                foreground: Color(hex: 0x6B5018),
                border: Color(hex: 0xE8C56E)
            )
        case .danger:
            return InfoNoteStyle(
                background: Color(hex: 0xFDE8EA),
                foreground: Color(hex: 0x6B0F18),
                border: Color(hex: 0xE63946).opacity(0.4)
            )
        }
    }

    private func infoNote(text: String, color: InfoNoteColor) -> some View {
        let style = infoNoteStyle(for: color)
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 11))
                .foregroundStyle(style.foreground)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 11))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(style.background)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(style.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Success toast

    private var successToast: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 18))
                .foregroundStyle(RunvoxColors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text("申請を受け付けました")
                    .font(.system(size: 13, weight: .bold))
                Text("3 営業日以内に結果をメールでお送りします")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
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
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Actions

    private func submit() async {
        let ok = await viewModel.submit()
        if ok {
            withAnimation(.spring(response: 0.5)) {
                showSuccessToast = true
            }
            Task {
                try? await Task.sleep(for: .seconds(3))
                withAnimation(.easeOut) { showSuccessToast = false }
            }
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy/MM/dd HH:mm"
        return f.string(from: date)
    }
}

// swiftlint:enable type_body_length

#Preview("New application") {
    NavigationStack {
        ReviewerApplicationView(userId: "u-new")
    }
}

#Preview("Submitted") {
    let app = ReviewerApplication(
        id: "1", userId: "u-1", status: .submitted,
        achievements: "東京マラソン 3:25 / フルマラソン完走 12 回",
        certifications: "JAAF 公認指導員 3 種",
        referenceURL: "https://example.com/profile",
        submittedAt: Date().addingTimeInterval(-3600),
        reviewedAt: nil, assignedRank: nil, rejectionReason: nil
    )
    let repo = MockReviewerApplicationRepository(
        simulatedLatency: .milliseconds(0),
        initial: ["u-1": app]
    )
    let view = ReviewerApplicationView(userId: "u-1")
    _ = repo
    return NavigationStack { view }
}
