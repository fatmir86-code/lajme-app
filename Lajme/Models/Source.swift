import Foundation

struct Source: Codable, Identifiable, Hashable {
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

struct SourcesResponse: Codable {
    let sources: [Source]
}
