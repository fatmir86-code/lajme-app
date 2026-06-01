import Foundation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    var results: [Article] = []
    var isSearching = false
    var hasSearched = false

    private let api = APIService.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            results = []
            hasSearched = false
            return
        }

        searchTask = Task {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            isSearching = true
            do {
                let response = try await api.searchArticles(query: trimmed)
                guard !Task.isCancelled else { return }
                results = response.articles
            } catch {
                guard !Task.isCancelled else { return }
                results = []
            }
            isSearching = false
            hasSearched = true
        }
    }

    func clear() {
        query = ""
        results = []
        hasSearched = false
        searchTask?.cancel()
    }
}
