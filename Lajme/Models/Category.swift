import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let slug: String
    let icon: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, icon
        case sortOrder = "sort_order"
    }

    // SF Symbols mapping for each category
    var sfSymbol: String {
        switch slug {
        case "aktuale": return "newspaper"
        case "politike": return "building.columns"
        case "ekonomi": return "chart.line.uptrend.xyaxis"
        case "sport": return "sportscourt"
        case "bote": return "globe.europe.africa"
        case "kulture": return "theatermasks"
        case "teknologji": return "desktopcomputer"
        default: return "newspaper"
        }
    }

    /// Shared category slug → display name mapping (eliminates duplication across views)
    static func displayName(for slug: String) -> String {
        switch slug {
        case "aktuale": return "Aktuale"
        case "politike": return "Politikë"
        case "ekonomi": return "Ekonomi"
        case "sport": return "Sport"
        case "bote": return "Botë"
        case "kulture": return "Kulturë & Showbiz"
        case "teknologji": return "Teknologji"
        default: return slug.capitalized
        }
    }

    // Default categories for when API is unavailable
    static let defaults: [Category] = [
        Category(id: 0, name: "Aktuale", slug: "aktuale", icon: nil, sortOrder: 0),
        Category(id: 1, name: "Politikë", slug: "politike", icon: nil, sortOrder: 1),
        Category(id: 2, name: "Ekonomi", slug: "ekonomi", icon: nil, sortOrder: 2),
        Category(id: 3, name: "Sport", slug: "sport", icon: nil, sortOrder: 3),
        Category(id: 4, name: "Botë", slug: "bote", icon: nil, sortOrder: 4),
        Category(id: 5, name: "Kulturë & Showbiz", slug: "kulture", icon: nil, sortOrder: 5),
    ]
}

struct CategoriesResponse: Codable {
    let categories: [Category]
}
