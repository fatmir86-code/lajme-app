import Foundation
import SwiftData

@MainActor
final class BookmarkService {
    static let shared = BookmarkService()

    private init() {}

    func isBookmarked(_ articleId: String, in context: ModelContext) -> Bool {
        let predicate = #Predicate<BookmarkedArticle> { $0.articleId == articleId }
        let descriptor = FetchDescriptor(predicate: predicate)
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    func toggleBookmark(for article: Article, in context: ModelContext) {
        let articleId = article.id
        let predicate = #Predicate<BookmarkedArticle> { $0.articleId == articleId }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
        } else {
            let bookmark = BookmarkedArticle(from: article)
            context.insert(bookmark)
        }
    }

    func fetchBookmarks(in context: ModelContext) -> [BookmarkedArticle] {
        let descriptor = FetchDescriptor<BookmarkedArticle>(
            sortBy: [SortDescriptor(\.bookmarkedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
