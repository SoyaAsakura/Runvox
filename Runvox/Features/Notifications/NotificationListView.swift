import SwiftUI

/// 通知一覧画面（ホームの鈴アイコンから提示）
struct NotificationListView: View {
    @StateObject private var viewModel: NotificationListViewModel
    @Environment(\.dismiss) private var dismiss

    /// シートを閉じた後にホーム側がバッジを更新するためのコールバック
    private let onClose: (() -> Void)?

    init(userId: String, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: NotificationListViewModel(userId: userId))
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()
                content
            }
            .navigationTitle("通知")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        onClose?()
                        dismiss()
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(RunvoxColors.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.hasUnread {
                        Button("すべて既読") {
                            Task { await viewModel.markAllAsRead() }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(RunvoxColors.primaryDark)
                    }
                }
            }
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.notifications.isEmpty {
            ProgressView().padding(40)
        } else if let error = viewModel.errorMessage, viewModel.notifications.isEmpty {
            errorState(message: error)
        } else if viewModel.notifications.isEmpty {
            emptyState
        } else {
            list
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                    Button {
                        Task { await viewModel.markAsRead(notification) }
                        // TODO: targetPath があれば該当画面へ遷移
                    } label: {
                        NotificationRow(notification: notification)
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.notifications.count - 1 {
                        Divider().padding(.leading, 64)
                    }
                }
            }
            .background(.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(RunvoxColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(16)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundStyle(RunvoxColors.subtext)
            Text("通知はありません")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Text("回答や評価が届くとここに表示されます")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
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
        .padding(40)
    }
}

#Preview("With notifications") {
    NotificationListView(userId: MockNotificationRepository.sampleUserId)
}

#Preview("Empty") {
    NotificationListView(
        userId: "empty-user"
    )
}
