import SwiftUI

/// 質問検索画面（ホームの 🔍 から提示）
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool
    @State private var debounceTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            ZStack {
                RunvoxColors.bgPage.ignoresSafeArea()

                VStack(spacing: 0) {
                    searchBar
                    content
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                        .font(.system(size: 14))
                        .foregroundStyle(RunvoxColors.ink)
                }
            }
            .navigationDestination(for: Question.self) { question in
                QuestionDetailView(question: question)
            }
            .navigationDestination(for: AnswererRoute.self) { route in
                AnswererProfileView(userId: route.userId)
            }
            .onAppear { searchFocused = true }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(RunvoxColors.subtext)

            TextField("質問を検索（例: サブ3.5、ケガ）", text: $viewModel.query)
                .font(.system(size: 15))
                .foregroundStyle(RunvoxColors.ink)
                .autocorrectionDisabled()
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { triggerSearch(immediate: true) }
                .onChange(of: viewModel.query) { _ in triggerSearch(immediate: false) }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.clear()
                    searchFocused = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(RunvoxColors.subtext)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(searchFocused ? RunvoxColors.primary : RunvoxColors.border, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Content states

    @ViewBuilder
    private var content: some View {
        if viewModel.isSearching && viewModel.results.isEmpty {
            Spacer()
            ProgressView()
            Spacer()
        } else if let error = viewModel.errorMessage {
            errorState(message: error)
        } else if !viewModel.hasSearched {
            initialPrompt
        } else if viewModel.results.isEmpty {
            noResults
        } else {
            resultsList
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(viewModel.results.count) 件の結果")
                    .font(.system(size: 11))
                    .foregroundStyle(RunvoxColors.subtext)
                    .padding(.horizontal, 20)

                ForEach(viewModel.results) { question in
                    NavigationLink(value: question) {
                        QuestionCard(question: question)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }

    private var initialPrompt: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(RunvoxColors.subtext)
            Text("キーワードで質問を検索")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
            Text("タイトル・本文から探せます")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noResults: some View {
        VStack(spacing: 10) {
            Spacer()
            Text("🔍")
                .font(.system(size: 40))
            Text("「\(viewModel.trimmedQuery)」に一致する質問がありません")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(RunvoxColors.ink)
                .multilineTextAlignment(.center)
            Text("別のキーワードで試してみてください")
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.subtext)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26))
                .foregroundStyle(RunvoxColors.danger)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(RunvoxColors.ink)
            Button("再試行") { triggerSearch(immediate: true) }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(RunvoxColors.primaryDark)
                .foregroundStyle(.white)
                .clipShape(Capsule())
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Debounced search trigger

    private func triggerSearch(immediate: Bool) {
        debounceTask?.cancel()
        if immediate {
            Task { await viewModel.search() }
            return
        }
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
    }
}

#Preview {
    SearchView()
}
