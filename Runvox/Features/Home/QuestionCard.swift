import SwiftUI

/// 質問一覧で使う 1 件分のカード
struct QuestionCard: View {
    let question: Question
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                metaRow
                titleText
                footerRow
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(categoryAccent)
                    .frame(width: 3)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12
                        )
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var metaRow: some View {
        HStack(alignment: .center) {
            CategoryChip(label: question.category.displayName, size: .small)
            Spacer()
            StatusPill(status: question.status)
        }
        .padding(.bottom, 8)
    }

    private var titleText: some View {
        Text(question.title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(RunvoxColors.ink)
            .multilineTextAlignment(.leading)
            .lineLimit(2)
            .padding(.bottom, 10)
    }

    private var footerRow: some View {
        HStack {
            askerOrAnswerer
            Spacer()
            trailingMeta
        }
        .padding(.top, 10)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RunvoxColors.border)
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var askerOrAnswerer: some View {
        if let answerer = question.latestAnswerer {
            HStack(spacing: 6) {
                if let rank = answerer.rank {
                    RankBadge(rank: rank, size: 20)
                }
                Text("\(answerer.nickname) が回答")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        } else {
            HStack(spacing: 6) {
                Avatar(initial: String(question.askerNickname.prefix(1)), size: 22)
                Text(question.askerNickname)
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
    }

    @ViewBuilder
    private var trailingMeta: some View {
        if let rating = question.latestRating {
            StarRating(rating: rating, size: 12)
        } else {
            Text(question.relativeCreatedAt)
                .font(.system(size: 11))
                .foregroundStyle(RunvoxColors.subtext)
        }
    }

    // MARK: - Category accent color

    private var categoryAccent: Color {
        switch question.category {
        case .race:             return RunvoxColors.primary
        case .training:         return RunvoxColors.primary
        case .nutrition:        return RunvoxColors.accentLime
        case .gear:             return RunvoxColors.primaryDark
        case .injuryPrevention: return RunvoxColors.rankS
        case .other:            return RunvoxColors.subtext
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(MockQuestionRepository.defaultSamples) { question in
                QuestionCard(question: question)
            }
        }
        .padding(20)
    }
    .background(RunvoxColors.bgPage)
}
