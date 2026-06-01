import Foundation

struct Article: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let articleUrl: String
    let imageUrl: String?
    let publishedAt: Date
    let categorySlug: String?
    let isBreaking: Bool
    let source: ArticleSource?
    let relatedSources: [RelatedSource]?

    enum CodingKeys: String, CodingKey {
        case id, title
        case articleUrl = "article_url"
        case imageUrl = "image_url"
        case publishedAt = "published_at"
        case categorySlug = "category_slug"
        case isBreaking = "is_breaking"
        case source
        case relatedSources = "related_sources"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        lhs.id == rhs.id
    }
}

struct RelatedSource: Codable, Hashable, Identifiable {
    let name: String
    let url: String

    var id: String { name + url }
}

struct ArticleSource: Codable, Hashable {
    let id: Int
    let name: String
    let url: String
    let logoUrl: String?
    let country: String?

    enum CodingKeys: String, CodingKey {
        case id, name, url
        case logoUrl = "logo_url"
        case country
    }
}

struct ArticlesResponse: Codable {
    let articles: [Article]
    let page: Int
    let perPage: Int?
    let hasMore: Bool?

    enum CodingKeys: String, CodingKey {
        case articles, page
        case perPage = "per_page"
        case hasMore = "has_more"
    }
}

struct SearchResponse: Codable {
    let articles: [Article]
    let page: Int
    let query: String
}
