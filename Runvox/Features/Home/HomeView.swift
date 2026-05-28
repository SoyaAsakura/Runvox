import SwiftUI

/// ホーム画面（最新質問のタイムライン）
struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var viewModel = HomeViewModel()
    @State private var showPostSheet = false
    @State private var showMyPageSheet = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                RunvoxColors.bgPage.ignoresSafeArea()
                content
                fab
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { logoTitle }
                ToolbarItem(placement: .topBarTrailing) { searchButton }
                ToolbarItem(placement: .topBarTrailing) { notificationButton }
                ToolbarItem(placement: .topBarTrailing) { myPageButton }
            }
            .navigationDestination(for: Question.self) { question in
                QuestionDetailView(question: question)
            }
            .sheet(isPresented: $showPostSheet) {
                if let user = auth.currentUser {
                    PostQuestionView(asker: user) { newQuestion in
                        viewModel.prepend(newQuestion)
                    }
                }
            }
            .sheet(isPresented: $showMyPageSheet) {
                MyPageView()
                    .environmentObject(auth)
            }
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
        }
    }

    // MARK: - Top bar

    private var logoTitle: some View {
        HStack(spacing: 0) {
            Text("Run").font(.system(size: 20, weight: .black))
            Text(".").font(.system(size: 20, weight: .black)).foregroundStyle(RunvoxColors.primary)
            Text("vox").font(.system(size: 20, weight: .black))
        }
        .foregroundStyle(RunvoxColors.ink)
    }

    private var searchButton: some View {
        Button {
            // TODO: 検索画面
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
        }
    }

    private var notificationButton: some View {
        Button {
            // TODO: 通知一覧
        } label: {
            Image(systemName: "bell")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
        }
    }

    private var myPageButton: some View {
        Button {
            showMyPageSheet = true
        } label: {
            Image(systemName: "person.circle")
                .font(.system(size: 18))
                .foregroundStyle(RunvoxColors.ink)
        }
    }

    // MARK: - Main content

    @ViewBuilder
    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                categoryFilter
                questionList
                Color.clear.frame(height: 80) // FAB との余白
            }
            .padding(.top, 8)
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: "すべて",
                    style: viewModel.selectedCategory == nil ? .selected : .outline,
                    showHashtag: false
                )
                .onTapGesture {
                    Task { await viewModel.selectCategory(nil) }
                }

                ForEach(QuestionCategory.allCases) { category in
                    CategoryChip(
                        label: category.displayName,
                        style: viewModel.selectedCategory == category ? .selected : .outline,
                        showHashtag: false
                    )
                    .onTapGesture {
                        Task { await viewModel.selectCategory(category) }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private var questionList: some View {
        if viewModel.isLoading && viewModel.questions.isEmpty {
            loadingSkeleton
        } else if let errorMessage = viewModel.errorMessage {
            errorState(message: errorMessage)
        } else if viewModel.questions.isEmpty {
            emptyState
        } else {
            VStack(spacing: 12) {
                ForEach(viewModel.questions) { question in
                    NavigationLink(value: question) {
                        QuestionCard(question: question)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RunvoxColors.border)
                    )
                    .frame(height: 110)
                    .opacity(0.6)
            }
        }
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🏃‍♂️")
                .font(.system(size: 48))
            Text("まだ質問がありません")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Text("FAB から最初の質問を投稿してみましょう")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(RunvoxColors.danger)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(RunvoxColors.ink)
                .multilineTextAlignment(.center)
            Button {
                Task { await viewModel.refresh() }
            } label: {
                Text("再試行")
                    .font(.system(size: 13, weight: .bold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RunvoxColors.primaryDark)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
    }

    // MARK: - FAB

    private var fab: some View {
        Button {
            showPostSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                Text("質問する")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(RunvoxColors.primaryDark)
            .clipShape(Capsule())
            .shadow(color: RunvoxColors.primaryDark.opacity(0.4), radius: 14, y: 6)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthService.previewSignedIn())
}
