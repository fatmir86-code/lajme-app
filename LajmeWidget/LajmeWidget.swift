import WidgetKit
import SwiftUI

// MARK: - Minimal API layer (self-contained; the widget target doesn't
// link the app's models to keep the extension lean)

struct WidgetArticle: Identifiable, Decodable {
    let id: String
    let title: String
    let articleUrl: String
    let publishedAt: Date
    let sourceName: String

    /// Same smart-link the app's share sheet uses: routes into the app via
    /// universal link (handled by handleIncomingURL), falls back to a
    /// landing page if the app were ever missing.
    var deepLink: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "fatmir86-code.github.io"
        components.path = "/a/"
        components.queryItems = [
            URLQueryItem(name: "u", value: articleUrl),
            URLQueryItem(name: "t", value: title),
            URLQueryItem(name: "s", value: sourceName),
        ]
        return components.url ?? URL(string: "https://apps.apple.com/app/id6762101297")!
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, source
        case articleUrl = "article_url"
        case publishedAt = "published_at"
    }
    private enum SourceKeys: String, CodingKey { case name }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        articleUrl = try c.decode(String.self, forKey: .articleUrl)
        publishedAt = try c.decode(Date.self, forKey: .publishedAt)
        if let source = try? c.nestedContainer(keyedBy: SourceKeys.self, forKey: .source) {
            sourceName = (try? source.decode(String.self, forKey: .name)) ?? "Lajme"
        } else {
            sourceName = "Lajme"
        }
    }

    init(id: String, title: String, articleUrl: String, publishedAt: Date, sourceName: String) {
        self.id = id
        self.title = title
        self.articleUrl = articleUrl
        self.publishedAt = publishedAt
        self.sourceName = sourceName
    }
}

private struct WidgetArticlesResponse: Decodable {
    let articles: [WidgetArticle]
}

enum WidgetAPI {
    private static let baseURL = "https://cgjqcjksdlzoheoyhmwg.supabase.co/functions/v1/api"
    private static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnanFjamtzZGx6b2hlb3lobXdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjA2MzUsImV4cCI6MjA5MTU5NjYzNX0.7-HduY5YeJYDqrFeEZqvgM6uvw9TXmPf4Lkp-1jMcck"

    static func fetchTopArticles(limit: Int) async -> [WidgetArticle] {
        guard var components = URLComponents(string: baseURL + "/articles") else { return [] }
        components.queryItems = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_page", value: "\(limit)"),
            URLQueryItem(name: "_t", value: "\(Int(Date().timeIntervalSince1970))"),
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let decoded = try? decoder.decode(WidgetArticlesResponse.self, from: data) else {
            return []
        }
        return decoded.articles
    }
}

// MARK: - Timeline

struct HeadlinesEntry: TimelineEntry {
    let date: Date
    let articles: [WidgetArticle]
}

struct HeadlinesProvider: TimelineProvider {
    private static let placeholderArticles = [
        WidgetArticle(id: "1", title: "Lajmet më të fundit nga Kosova dhe Shqipëria",
                      articleUrl: "https://example.com", publishedAt: Date(), sourceName: "Lajme"),
        WidgetArticle(id: "2", title: "Të gjitha burimet shqiptare në një vend",
                      articleUrl: "https://example.com", publishedAt: Date(), sourceName: "Lajme"),
        WidgetArticle(id: "3", title: "Raportuar edhe nga burime të tjera",
                      articleUrl: "https://example.com", publishedAt: Date(), sourceName: "Lajme"),
    ]

    func placeholder(in context: Context) -> HeadlinesEntry {
        HeadlinesEntry(date: Date(), articles: Self.placeholderArticles)
    }

    func getSnapshot(in context: Context, completion: @escaping (HeadlinesEntry) -> Void) {
        Task {
            let articles = await WidgetAPI.fetchTopArticles(limit: 5)
            completion(HeadlinesEntry(
                date: Date(),
                articles: articles.isEmpty ? Self.placeholderArticles : articles
            ))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HeadlinesEntry>) -> Void) {
        Task {
            let articles = await WidgetAPI.fetchTopArticles(limit: 5)
            let entry = HeadlinesEntry(date: Date(), articles: articles)
            // Refresh roughly twice an hour; on failure retry sooner.
            let next = Date().addingTimeInterval(articles.isEmpty ? 10 * 60 : 30 * 60)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }
}

// MARK: - Views

private let widgetBackground = Color(
    light: Color(red: 0.969, green: 0.961, blue: 0.941),  // matches app cream
    dark: Color(red: 0.07, green: 0.07, blue: 0.07)
)

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

struct SmallHeadlineView: View {
    let entry: HeadlinesEntry

    var body: some View {
        if let article = entry.articles.first {
            VStack(alignment: .leading, spacing: 6) {
                Text("L")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                Spacer(minLength: 0)
                Text(article.title)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .lineLimit(5)
                    .lineSpacing(1)
                Text(article.sourceName.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .widgetURL(article.deepLink)
        } else {
            Text("Hap Lajme për lajmet e fundit")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(.secondary)
        }
    }
}

struct MediumHeadlinesView: View {
    let entry: HeadlinesEntry

    var body: some View {
        if entry.articles.isEmpty {
            Text("Hap Lajme për lajmet e fundit")
                .font(.system(size: 13, design: .serif))
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 7) {
                ForEach(entry.articles.prefix(3)) { article in
                    Link(destination: article.deepLink) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(article.sourceName.uppercased())
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .tracking(0.5)
                            Text(article.title)
                                .font(.system(size: 12.5, weight: .semibold, design: .serif))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct LajmeWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HeadlinesEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumHeadlinesView(entry: entry)
            default:
                SmallHeadlineView(entry: entry)
            }
        }
        .containerBackground(widgetBackground, for: .widget)
    }
}

// MARK: - Widget declaration

struct LajmeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LajmeHeadlines", provider: HeadlinesProvider()) { entry in
            LajmeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Lajmet kryesore")
        .description("Titujt më të fundit nga burimet shqiptare.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LajmeWidgetBundle: WidgetBundle {
    var body: some Widget {
        LajmeWidget()
    }
}
