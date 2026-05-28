import SwiftUI

/// 回答カード (質問詳細画面で使用)
///
/// タップ動作は親側の `NavigationLink` などに任せる（自身は素の View）
struct AnswerCard: View {
    let answer: Answer

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            answererHeader
            bodyText
            ratingBar
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RunvoxColors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }

    // MARK: - Header

    private var answererHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Avatar(
                initial: String(answer.answererNickname.prefix(1)),
                size: 40,
                rank: answer.answererRank
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(answer.answererNickname)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RunvoxColors.ink)

                if let bio = answer.answererBio {
                    Text(bio)
                        .font(.system(size: 11))
                        .foregroundStyle(RunvoxColors.subtext)
                }

                if let stats = answer.answererStats {
                    HStack(spacing: 6) {
                        StarRating(rating: Int(stats.averageRating.rounded()), size: 11)
                        Text(String(format: "%.1f", stats.averageRating))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(RunvoxColors.ink)
                        Circle()
                            .fill(RunvoxColors.border)
                            .frame(width: 3, height: 3)
                        Text("回答 \(stats.answerCount) 件")
                            .font(.system(size: 11))
                            .foregroundStyle(RunvoxColors.subtext)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            LinearGradient(
                colors: [RunvoxColors.bgTint, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Body

    private var bodyText: some View {
        Text(answer.body)
            .font(.system(size: 13))
            .foregroundStyle(RunvoxColors.inkSoft)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(RunvoxColors.borderSoft)
                    .frame(height: 0.5)
            }
    }

    // MARK: - Rating row

    @ViewBuilder
    private var ratingBar: some View {
        HStack(spacing: 8) {
            if let rating = answer.rating {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(RunvoxColors.success)
                Text("質問者から評価")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
                Spacer()
                StarRating(rating: rating, size: 14)
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 12))
                    .foregroundStyle(RunvoxColors.subtext)
                Text("評価待ち")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
                Spacer()
                Text(answer.relativeCreatedAt)
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(RunvoxColors.bgPage)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(RunvoxColors.borderSoft)
                .frame(height: 0.5)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            if let rated = MockAnswerRepository.defaultAnswers["q2"] {
                AnswerCard(answer: rated)
            }
            if let unrated = MockAnswerRepository.defaultAnswers["q3"] {
                AnswerCard(answer: unrated)
            }
        }
        .padding(20)
    }
    .background(RunvoxColors.bgPage)
}
