import SwiftUI

// swiftlint:disable type_body_length
// AnswererProfileView は表示要素が多くて 300 行を少し超えるが、
// セクションごとに private var で分離済みで可読性は確保されている

/// 回答者プロフィール画面
struct AnswererProfileView: View {
    @StateObject private var viewModel: AnswererProfileViewModel

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: AnswererProfileViewModel(userId: userId))
    }

    var body: some View {
        ZStack {
            RunvoxColors.bgPage.ignoresSafeArea()

            if let profile = viewModel.profile {
                content(profile: profile)
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.errorMessage {
                errorState(message: error)
            } else {
                Color.clear
            }
        }
        .navigationTitle("プロフィール")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
    }

    // MARK: - Main content

    private func content(profile: AnswererProfile) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                cover
                profileHeader(profile: profile)
                statsRow(stats: profile.stats, coachingYears: profile.coachingYears)
                achievementsSection(profile.achievements)
                tagsSection(profile.specialtyTags)
                recentAnswersSection(profile.recentAnswers)
                Color.clear.frame(height: 20)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Cover

    private var cover: some View {
        ZStack {
            LinearGradient(
                colors: [
                    RunvoxColors.ink,
                    Color(hex: 0x1B3539),
                    RunvoxColors.primaryDark,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack {
                Spacer()
                tracksPattern
                    .frame(height: 36)
                    .opacity(0.5)
            }
        }
        .frame(height: 140)
    }

    private var tracksPattern: some View {
        GeometryReader { proxy in
            Path { path in
                let step: CGFloat = 12
                var x: CGFloat = 0
                while x < proxy.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: proxy.size.height))
                    x += step
                }
            }
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Profile header

    private func profileHeader(profile: AnswererProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 12) {
                Avatar(
                    initial: String(profile.user.displayName.prefix(1)),
                    size: 84,
                    rank: profile.user.rank
                )
                VStack(alignment: .leading, spacing: 6) {
                    if let rank = profile.user.rank {
                        rankTag(rank: rank)
                    }
                    Text(profile.user.displayName)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(RunvoxColors.ink)
                }
                .padding(.bottom, 8)
                Spacer()
            }

            if let bio = profile.user.bio {
                Text(bio)
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.subtext)
                    .padding(.top, 6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, -42)  // overlap cover
    }

    private func rankTag(rank: Rank) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 9))
            Text("\(rank.rawValue) RANK RUNNER")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(rank.gradient)
        .clipShape(Capsule())
        .shadow(color: Color(hex: 0xD9A923).opacity(0.3), radius: 4, y: 2)
    }

    // MARK: - Stats row (3 columns)

    @ViewBuilder
    private func statsRow(stats: AnswererStats?, coachingYears: Int?) -> some View {
        HStack(spacing: 0) {
            statCell(
                value: stats.map { String(format: "%.1f", $0.averageRating) } ?? "—",
                label: "評価平均",
                icon: "star.fill",
                iconColor: RunvoxColors.accentLimeD,
                showBorder: true
            )
            statCell(
                value: stats.map { "\($0.answerCount)" } ?? "—",
                label: "回答数",
                showBorder: true
            )
            statCell(
                value: coachingYears.map { "\($0)" } ?? "—",
                label: "指導歴 (年)",
                showBorder: false
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity)
    }

    private func statCell(
        value: String,
        label: String,
        icon: String? = nil,
        iconColor: Color = RunvoxColors.ink,
        showBorder: Bool
    ) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                HStack(spacing: 3) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 13))
                            .foregroundStyle(iconColor)
                    }
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(RunvoxColors.ink)
                }
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(RunvoxColors.subtext)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            if showBorder {
                Rectangle()
                    .fill(RunvoxColors.borderSoft)
                    .frame(width: 1)
            }
        }
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(.clear)
        )
    }

    // MARK: - Achievements

    @ViewBuilder
    private func achievementsSection(_ achievements: [String]) -> some View {
        if !achievements.isEmpty {
            sectionContainer(title: "実績", systemIcon: "rosette") {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(achievements.enumerated()), id: \.offset) { index, text in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(RunvoxColors.accentLime)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            Text(text)
                                .font(.system(size: 12))
                                .foregroundStyle(RunvoxColors.inkSoft)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 10)
                        if index < achievements.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - Tags

    @ViewBuilder
    private func tagsSection(_ tags: [String]) -> some View {
        if !tags.isEmpty {
            sectionContainer(title: "得意分野", systemIcon: "tag") {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(RunvoxColors.primaryDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(RunvoxColors.bgTint)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Recent answers

    @ViewBuilder
    private func recentAnswersSection(_ answers: [AnswerSummary]) -> some View {
        if !answers.isEmpty {
            VStack(spacing: 8) {
                SectionHeader(title: "最近の回答", count: answers.count, systemIcon: "bubble.left")
                    .padding(.horizontal, 20)

                VStack(spacing: 0) {
                    ForEach(Array(answers.enumerated()), id: \.element.id) { index, summary in
                        recentAnswerRow(summary)
                        if index < answers.count - 1 {
                            Divider().padding(.leading, 14)
                        }
                    }
                }
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RunvoxColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
            }
            .padding(.top, 20)
        }
    }

    private func recentAnswerRow(_ summary: AnswerSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(summary.questionTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(RunvoxColors.ink)
                .lineLimit(1)
            HStack {
                if let rating = summary.rating {
                    StarRating(rating: rating, size: 11)
                } else {
                    Text("評価待ち")
                        .font(.system(size: 10))
                        .foregroundStyle(RunvoxColors.subtext)
                }
                Spacer()
                Text(summary.shortDate)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Section container

    private func sectionContainer<Content: View>(
        title: String,
        systemIcon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 8) {
            SectionHeader(title: title, systemIcon: systemIcon)
                .padding(.horizontal, 20)
            content()
                .frame(maxWidth: .infinity)
                .background(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RunvoxColors.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    // MARK: - Error

    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 36))
                .foregroundStyle(RunvoxColors.subtext)
            Text(message)
                .font(.system(size: 13))
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
        .padding(40)
    }
}

// swiftlint:enable type_body_length

// MARK: - Simple flow layout (iOS 16+)

/// 折り返しで自動配置する簡易レイアウト。SwiftUI 標準 Layout protocol (iOS 16+) を使用
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let arrangement = arrange(subviews: subviews, in: maxWidth)
        return arrangement.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, in: bounds.width)
        for (index, frame) in arrangement.frames.enumerated() {
            let placed = CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY)
            subviews[index].place(at: placed, proposal: ProposedViewSize(frame.size))
        }
    }

    private func arrange(subviews: Subviews, in width: CGFloat) -> (frames: [CGRect], size: CGSize) {
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width, currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxX = max(maxX, currentX)
        }
        return (frames, CGSize(width: max(maxX - spacing, 0), height: currentY + rowHeight))
    }
}

#Preview("S rank") {
    NavigationStack {
        AnswererProfileView(userId: "a1")
    }
}

#Preview("A rank") {
    NavigationStack {
        AnswererProfileView(userId: "a2")
    }
}

#Preview("B rank") {
    NavigationStack {
        AnswererProfileView(userId: "a3")
    }
}

#Preview("Not found") {
    NavigationStack {
        AnswererProfileView(userId: "unknown")
    }
}
