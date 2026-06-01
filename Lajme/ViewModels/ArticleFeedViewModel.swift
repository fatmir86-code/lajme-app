import Foundation

@MainActor
@Observable
final class ArticleFeedViewModel {
    var articles: [Article] = []
    var categories: [Category] = Category.defaults
    var selectedCategory: String = "aktuale"
    var selectedCountry: String? {
        didSet {
            if selectedCountry != oldValue {
                UserDefaults.standard.set(selectedCountry ?? "", forKey: "lajme.selectedCountry")
            }
        }
    }
    var isLoading = false
    var isLoadingMore = false
    var error: String?
    var hasMore = true

    private var currentPage = 1
    private let api = APIService.shared

    init() {
        // Restore saved country filter (empty string = "all countries" = nil)
        let savedCountry = UserDefaults.standard.string(forKey: "lajme.selectedCountry") ?? ""
        self.selectedCountry = savedCountry.isEmpty ? nil : savedCountry
        // Auto-refresh is owned by the view via .task(id: scenePhase) — no Timer here.
    }

    // MARK: - Data loading

    func loadArticles() async {
        isLoading = true
        error = nil
        currentPage = 1

        let category = selectedCategory
        let country = selectedCountry
        defer { isLoading = false }
        do {
            let response = try await api.fetchArticles(
                category: category,
                country: country,
                page: 1
            )
            // If user changed category/country mid-load, abandon this result
            guard selectedCategory == category, selectedCountry == country else { return }
            articles = response.articles
            hasMore = response.hasMore ?? false
        } catch is CancellationError {
            // Ignore
        } catch {
            self.error = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isLoadingMore, !isLoading, hasMore else { return }
        isLoadingMore = true

        let nextPage = currentPage + 1
        let category = selectedCategory
        let country = selectedCountry

        do {
            let response = try await api.fetchArticles(
                category: category,
                country: country,
                page: nextPage
            )
            guard selectedCategory == category, selectedCountry == country else {
                isLoadingMore = false
                return
            }
            let existingIds = Set(articles.map(\.id))
            let newArticles = response.articles.filter { !existingIds.contains($0.id) }
            articles.append(contentsOf: newArticles)
            currentPage = nextPage
            hasMore = response.hasMore ?? false
        } catch {
            // Silent fail
        }

        isLoadingMore = false
    }

    func selectCategory(_ slug: String) async {
        guard slug != selectedCategory else { return }
        selectedCategory = slug
        await loadArticles()
    }

    func selectCountry(_ code: String?) async {
        guard code != selectedCountry else { return }
        selectedCountry = code
        await loadArticles()
    }

    func loadCategories() async {
        do {
            let response = try await api.fetchCategories()
            if !response.categories.isEmpty {
                categories = response.categories
            }
        } catch {
            // Keep defaults
        }
    }

    func refresh() async {
        await loadArticles()
    }
}
