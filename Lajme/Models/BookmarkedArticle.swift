import Foundation
import SwiftData

@Model
final class BookmarkedArticle {
    @Attribute(.unique) var articleId: String
    var title: String
    var articleUrl: String
    var publishedAt: Date
    var categorySlug: String?
    var sourceName: String
    var sourceCountry: String?
    var bookmarkedAt: Date

    init(from article: Article) {
        self.articleId = article.id
        self.title = article.title
        self.articleUrl = article.articleUrl
        self.publishedAt = article.publishedAt
        self.categorySlug = article.categorySlug
        self.sourceName = article.source?.name ?? ""
        self.sourceCountry = article.source?.country
        self.bookmarkedAt = Date()
    }

    var asArticle: Article {
        Article(
            id: articleId,
            title: title,
            articleUrl: articleUrl,
            imageUrl: nil,
            publishedAt: publishedAt,
            categorySlug: categorySlug,
            isBreaking: false,
            source: ArticleSource(
                id: 0,
                name: sourceName,
                url: "",
                logoUrl: nil,
                country: sourceCountry
            ),
            relatedSources: nil
        )
    }
}

/// Tracks which articles the user has already seen
@Model
final class ReadArticle {
    @Attribute(.unique) var articleId: String
    var readAt: Date

    init(articleId: String) {
        self.articleId = articleId
        self.readAt = Date()
    }
}
