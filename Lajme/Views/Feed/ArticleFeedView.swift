import SwiftUI
import SwiftData
import SafariServices

struct ArticleFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel = ArticleFeedViewModel()
    @State private var searchVM = SearchViewModel()
    @State private var selectedArticleURL: IdentifiableURL?
    @State private var shareItem: ShareableArticle?
    @State private var readIds: Set<String> = []
    @State private var isSearching = false
    @State private var showCountryPicker = false

    @Query private var readArticles: [ReadArticle]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                if isSearching {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15))
                            .foregroundStyle(Color(.tertiaryLabel))

                        TextField("Kërko lajme...", text: $searchVM.query)
                            .font(.system(size: 15))
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .onSubmit { searchVM.search() }

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSearching = false
                                searchVM.clear()
                            }
                        } label: {
                            Text("Anulo")
                                .font(.system(size: 15))
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !isSearching {
                    CategoryTabView(
                        categories: viewModel.categories,
                        selectedSlug: $viewModel.selectedCategory
                    ) { slug in
                        Task { await viewModel.selectCategory(slug) }
                    }
                    .padding(.top, 4)

                    Divider()
                        .padding(.top, 4)
                }

                // Content
                if isSearching {
                    searchContent
                } else {
                    feedContent
                }
            }
            .background(Color.appBackground)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isSearching {
                        Text("L")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .foregroundStyle(.primary)
                    }
                }
                ToolbarItem(placement: .principal) {
                    if !isSearching {
                        Button {
                            showCountryPicker = true
                        } label: {
                            HStack(spacing: 5) {
                                Text(CountryFilter.label(for: viewModel.selectedCountry))
                                    .font(.system(size: 15, weight: .semibold, design: .serif))
                                    .foregroundStyle(Color.primary)
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedCountry == nil
                                        ? Color(.systemGray6)
                                        : Color.primary.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.selectedCountry == nil
                                        ? Color.clear
                                        : Color.primary.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Burimet sipas vendit. Zgjedhur: \(CountryFilter.label(for: viewModel.selectedCountry))")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if !isSearching {
                        HStack(spacing: 16) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isSearching = true
                                }
                            } label: {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                            }

                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedArticleURL) { item in
                ArticleWebView(url: item.url)
            }
            .confirmationDialog(
                "Burimet sipas vendit",
                isPresented: $showCountryPicker,
                titleVisibility: .visible
            ) {
                ForEach(CountryFilter.options, id: \.label) { option in
                    Button(CountryFilter.labelWithFlag(for: option.code)) {
                        Task { await viewModel.selectCountry(option.code) }
                    }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: item.shareItems)
            }
            .task {
                readIds = Set(readArticles.map(\.articleId))
                purgeOldReadArticles()
                async let cats: () = viewModel.loadCategories()
                async let arts: () = viewModel.loadArticles()
                _ = await (cats, arts)
            }
            .task(id: scenePhase) {
                // Auto-refresh loop: fires on every scenePhase change.
                // When app goes to background, this task is cancelled.
                // When app returns to foreground, a fresh task starts.
                guard scenePhase == .active else { return }
                // Immediate refresh on foreground
                await viewModel.refresh()
                // Then refresh every 120 seconds
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(120))
                    guard !Task.isCancelled else { break }
                    await viewModel.refresh()
                }
            }
            .onChange(of: searchVM.query) { searchVM.search() }
            .onOpenURL { incomingURL in
                handleIncomingURL(incomingURL)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                if let webURL = userActivity.webpageURL {
                    handleIncomingURL(webURL)
                }
            }
            .onChange(of: readArticles) {
                readIds = Set(readArticles.map(\.articleId))
            }
        }
    }

    // MARK: - Feed content

    @ViewBuilder
    private var feedContent: some View {
        if viewModel.isLoading && viewModel.articles.isEmpty {
            Spacer()
            ProgressView().tint(.primary)
            Spacer()
        } else if let error = viewModel.error, viewModel.articles.isEmpty {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
                Text(error)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
                Button("Provo përsëri") {
                    Task { await viewModel.refresh() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 40)
            Spacer()
        } else if viewModel.articles.isEmpty && !viewModel.isLoading {
            // No articles match the current category + country filter
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "newspaper")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .accessibilityHidden(true)
                Text("Nuk ka lajme për këtë filtër")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Provo të ndryshosh vendin ose kategorinë.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.articles) { article in
                        Button {
                            markAsRead(article)
                            openArticle(article)
                        } label: {
                            VStack(spacing: 0) {
                                ArticleCardView(
                                    article: article,
                                    isRead: readIds.contains(article.id),
                                    onShare: {
                                        shareItem = ShareableArticle(article: article)
                                    },
                                    onOpenRelated: { related in
                                        openRelated(related, parentArticle: article)
                                    }
                                )
                                Divider().padding(.horizontal, 20)
                            }
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            if article == viewModel.articles.last {
                                Task { await viewModel.loadMore() }
                            }
                        }
                    }

                    if viewModel.isLoadingMore {
                        ProgressView()
                            .tint(.primary)
                            .padding(20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
    }

    // MARK: - Search results

    @ViewBuilder
    private var searchContent: some View {
        if searchVM.query.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.tertiaryLabel))
                Text("Shkruaj për të kërkuar lajme")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            Spacer()
        } else if searchVM.isSearching {
            Spacer()
            ProgressView().tint(.primary)
            Spacer()
        } else if searchVM.hasSearched && searchVM.results.isEmpty {
            Spacer()
            VStack(spacing: 8) {
                Text("Asnjë rezultat")
                    .font(.system(size: 16, weight: .semibold))
                Text("Nuk u gjetën lajme për \"\(searchVM.query)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            Spacer()
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchVM.results) { article in
                        VStack(spacing: 0) {
                            ArticleCardView(
                                article: article,
                                isRead: readIds.contains(article.id),
                                onShare: {
                                    shareItem = ShareableArticle(article: article)
                                }
                            )
                            Divider().padding(.horizontal, 20)
                        }
                        .onTapGesture {
                            markAsRead(article)
                            openArticle(article)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
        }
    }

    // MARK: - Helpers

    private func openArticle(_ article: Article) {
        guard let url = URL(string: article.articleUrl),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return }
        selectedArticleURL = IdentifiableURL(url: url)
    }

    /// Handles an incoming universal link of the form:
    ///   https://fatmir86-code.github.io/a/?u=<article_url>&t=<title>&s=<source>
    /// Opens the article URL in Safari. We deliberately open the source URL
    /// (not the landing page) since the user is already in the app.
    private func handleIncomingURL(_ url: URL) {
        guard url.host == "fatmir86-code.github.io" else { return }
        guard url.path == "/a" || url.path == "/a/" || url.path.hasPrefix("/a/") else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let articleURLString = components?.queryItems?.first(where: { $0.name == "u" })?.value,
           let articleURL = URL(string: articleURLString),
           let scheme = articleURL.scheme?.lowercased(),
           ["http", "https"].contains(scheme) {
            selectedArticleURL = IdentifiableURL(url: articleURL)
        }
    }

    private func openRelated(_ related: RelatedSource, parentArticle: Article) {
        guard let url = URL(string: related.url),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return }
        markAsRead(parentArticle)
        selectedArticleURL = IdentifiableURL(url: url)
    }

    private func markAsRead(_ article: Article) {
        guard !readIds.contains(article.id) else { return }
        let read = ReadArticle(articleId: article.id)
        modelContext.insert(read)
        readIds.insert(article.id)
    }

    private func purgeOldReadArticles() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let predicate = #Predicate<ReadArticle> { $0.readAt < cutoff }
        try? modelContext.delete(model: ReadArticle.self, where: predicate)
    }
}

// MARK: - Share support

struct ShareableArticle: Identifiable {
    let id = UUID()
    let article: Article

    /// Build a smart-link URL that:
    /// - opens the article directly in Lajme if the recipient has the app installed
    ///   (via iOS Universal Links — see apple-app-site-association on the domain)
    /// - falls back to a minimal landing page (title + "Read" + "Download app") otherwise
    private var smartLink: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "fatmir86-code.github.io"
        components.path = "/a/"
        components.queryItems = [
            URLQueryItem(name: "u", value: article.articleUrl),
            URLQueryItem(name: "t", value: article.title),
            URLQueryItem(name: "s", value: article.source?.name ?? "Lajme"),
        ]
        return components.url ?? URL(string: "https://apps.apple.com/app/id6762101297")!
    }

    var shareItems: [Any] {
        // One share item: the smart link. Title is included in a preview on iOS.
        let title = "\(article.title) — \(article.source?.name ?? "Lajme")"
        return [title, smartLink]
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
