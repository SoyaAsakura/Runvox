import SwiftUI

/// ポイント履歴の 1 行
struct PointTransactionRow: View {
    let transaction: PointTransaction

    var body: some View {
        HStack(spacing: 12) {
            dateBlock
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.questionTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RunvoxColors.ink)
                    .lineLimit(1)
                metaRow
            }
            Spacer(minLength: 8)
            pointsBadge
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var dateBlock: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(transaction.shortDate)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .frame(width: 40, alignment: .leading)
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            StarRating(rating: transaction.stars, size: 10)
            Text("×")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(RunvoxColors.subtext)
            RankBadge(rank: transaction.rank, size: 14)
            Text("(\(String(format: "%.1f", transaction.multiplier)))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(RunvoxColors.subtext)
        }
    }

    private var pointsBadge: some View {
        Text("+\(transaction.pointsAwarded)")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundStyle(RunvoxColors.success)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(MockPointRepository.defaultTransactions.prefix(5)) { tx in
            PointTransactionRow(transaction: tx)
            Divider().padding(.leading, 66)
        }
    }
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(RunvoxColors.border)
    )
    .padding()
    .background(RunvoxColors.bgPage)
}
