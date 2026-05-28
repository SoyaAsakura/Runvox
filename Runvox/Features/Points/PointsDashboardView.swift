import SwiftUI

/// マイポイント / ポイントダッシュボード画面
struct PointsDashboardView: View {
    @StateObject private var viewModel: PointsDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    init(userId: String) {
        _viewModel = StateObject(wrappedValue: PointsDashboardViewModel(userId: userId))
    }

    var body: some View {
        ZStack {
            RunvoxColors.bgPage.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    heroCard
                    monthSummary
                    transactionsBlock
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 12)
            }
            .refreshable { await viewModel.refresh() }
        }
        .navigationTitle("マイポイント")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadIfNeeded() }
    }

    // MARK: - Hero card

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CURRENT BALANCE")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.7))
                .tracking(1.4)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.summary?.balance ?? 0)")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                Text("pt")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(RunvoxColors.primary)
            }
            Text("≒ ¥\(viewModel.summary?.balance ?? 0)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.7))

            progressBar
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    RunvoxColors.ink,
                    Color(hex: 0x14373C),
                    RunvoxColors.primaryDark,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
        .shadow(color: RunvoxColors.ink.opacity(0.25), radius: 12, y: 6)
    }

    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("現金化まで（Phase 2 予定）")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.7))
                Spacer()
                Text("\(viewModel.summary?.balance ?? 0) / \(UserPoints.cashoutThreshold) pt")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [RunvoxColors.primary, RunvoxColors.accentLime],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: proxy.size.width * (viewModel.summary?.cashoutProgress ?? 0),
                            height: 6
                        )
                }
            }
            .frame(height: 6)

            if let summary = viewModel.summary, summary.pointsUntilCashout > 0 {
                Text("あと \(summary.pointsUntilCashout) pt で現金化可能予定")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Month summary

    @ViewBuilder
    private var monthSummary: some View {
        if let summary = viewModel.summary {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("今月の獲得")
                        .font(.system(size: 11))
                        .foregroundStyle(RunvoxColors.subtext)
                    HStack(alignment: .lastTextBaseline, spacing: 2) {
                        Text("+\(summary.thisMonthEarned)")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundStyle(RunvoxColors.success)
                        Text("pt")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(RunvoxColors.success)
                    }
                }
                Spacer()
                deltaBadge(percent: summary.lastMonthDeltaPercent)
            }
            .padding(14)
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private func deltaBadge(percent: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: percent >= 0 ? "arrow.up" : "arrow.down")
                .font(.system(size: 10, weight: .bold))
            Text("先月 \(percent >= 0 ? "+" : "")\(percent)%")
        }
        .font(.system(size: 11, weight: .bold))
        .foregroundStyle(percent >= 0 ? RunvoxColors.success : RunvoxColors.danger)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(percent >= 0 ? Color(hex: 0xDFF5E5) : Color(hex: 0xFDE8EA))
        .clipShape(Capsule())
    }

    // MARK: - Transactions

    @ViewBuilder
    private var transactionsBlock: some View {
        VStack(spacing: 10) {
            SectionHeader(
                title: "ポイント履歴",
                count: viewModel.transactions.count,
                systemIcon: "list.bullet.rectangle.fill"
            )
            .padding(.horizontal, 16)

            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.transactions.isEmpty {
            loadingPlaceholder
        } else if let error = viewModel.errorMessage {
            errorState(message: error)
        } else if viewModel.transactions.isEmpty {
            emptyState
        } else {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.transactions.enumerated()), id: \.element.id) { index, tx in
                    PointTransactionRow(transaction: tx)
                    if index < viewModel.transactions.count - 1 {
                        Divider().padding(.leading, 66)
                    }
                }
            }
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
        }
    }

    private var loadingPlaceholder: some View {
        VStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(RunvoxColors.border))
                    .frame(height: 50)
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("💰")
                .font(.system(size: 40))
            Text("まだポイント履歴がありません")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Text("回答に評価が付くとここに表示されます")
                .font(.system(size: 11))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 16)
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
                Task { await viewModel.refresh() }
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
}

#Preview {
    NavigationStack {
        PointsDashboardView(userId: "u-me")
    }
}
