import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \BookmarkedArticle.bookmarkedAt, order: .reverse)
    private var bookmarks: [BookmarkedArticle]

    @State private var selectedArticleURL: IdentifiableURL?
    @State private var shareItem: ShareableArticle?

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 28))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .accessibilityHidden(true)
                    Text("Asnjë lajm i ruajtur")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("Trokit \(Image(systemName: "bookmark")) te një lajm për ta ruajtur këtu.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(.secondaryLabel))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(bookmarks) { bookmark in
                            let article = bookmark.asArticle
                            Button {
                                openArticle(article)
                            } label: {
                                VStack(spacing: 0) {
                                    ArticleCardView(
                                        article: article,
                                        isBookmarked: true,
                                        onShare: {
                                            shareItem = ShareableArticle(article: article)
                                        },
                                        onToggleBookmark: {
                                            modelContext.delete(bookmark)
                                        }
                                    )
                                    Divider().padding(.horizontal, 20)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Color.appBackground)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Të ruajtura")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
            }
        }
        .sheet(item: $selectedArticleURL) { item in
            ArticleWebView(url: item.url)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: item.shareItems)
        }
    }

    private func openArticle(_ article: Article) {
        guard let url = URL(string: article.articleUrl),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme) else { return }
        selectedArticleURL = IdentifiableURL(url: url)
    }
}
