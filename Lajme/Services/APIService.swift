import Foundation

final class APIService: Sendable {
    static let shared = APIService()

    // TODO: Replace with your Supabase Edge Function URL
    private let baseURL = "https://cgjqcjksdlzoheoyhmwg.supabase.co/functions/v1/api"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnanFjamtzZGx6b2hlb3lobXdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjA2MzUsImV4cCI6MjA5MTU5NjYzNX0.7-HduY5YeJYDqrFeEZqvgM6uvw9TXmPf4Lkp-1jMcck"

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Ephemeral session with no disk cache — guarantees no local staleness.
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    private init() {}

    // MARK: - Articles

    func fetchArticles(category: String? = nil, country: String? = nil, page: Int = 1, perPage: Int = 20) async throws -> ArticlesResponse {
        guard var components = URLComponents(string: baseURL + "/articles") else {
            throw APIError.invalidResponse
        }
        var queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "per_page", value: "\(perPage)"),
        ]
        if let category, category != "aktuale" {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let country, !country.isEmpty {
            queryItems.append(URLQueryItem(name: "country", value: country))
        }
        components.queryItems = queryItems

        guard let url = components.url else { throw APIError.invalidResponse }
        return try await request(url: url)
    }

    func searchArticles(query: String, page: Int = 1) async throws -> SearchResponse {
        guard var components = URLComponents(string: baseURL + "/articles/search") else {
            throw APIError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: "\(page)"),
        ]

        guard let url = components.url else { throw APIError.invalidResponse }
        return try await request(url: url)
    }

    // MARK: - Sources

    func fetchSources() async throws -> SourcesResponse {
        guard let url = URL(string: baseURL + "/sources") else {
            throw APIError.invalidResponse
        }
        return try await request(url: url)
    }

    // MARK: - Categories

    func fetchCategories() async throws -> CategoriesResponse {
        guard let url = URL(string: baseURL + "/categories") else {
            throw APIError.invalidResponse
        }
        return try await request(url: url)
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(url: URL) async throws -> T {
        // Append a cache-busting parameter to defeat CDN edge caching
        // (Supabase CDN honors Cache-Control: public, max-age=60 from the
        // server response; a unique URL forces a cache miss at the CDN layer)
        var cacheBustedURL = url
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: "_t", value: "\(Int(Date().timeIntervalSince1970))"))
            components.queryItems = items
            cacheBustedURL = components.url ?? url
        }

        var request = URLRequest(url: cacheBustedURL)
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.timeoutInterval = 15
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("no-cache, no-store", forHTTPHeaderField: "Cache-Control")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.noInternet
            case .timedOut:
                throw APIError.timeout
            default:
                throw APIError.noInternet
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError
    case timeout
    case noInternet

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Përgjigje e pavlefshme nga serveri"
        case .httpError(let code):
            return "Gabim nga serveri: \(code)"
        case .decodingError:
            return "Gabim në leximin e të dhënave"
        case .noInternet:
            return "Nuk ka lidhje me internetin"
        case .timeout:
            return "Serveri nuk përgjigjet, provo përsëri"
        }
    }
}
