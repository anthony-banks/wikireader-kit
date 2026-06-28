import Foundation

// MARK: - Domain transfer object

/// A Sendable, value-type snapshot of catalog data produced by services and
/// the seed loader. Repositories merge these into SwiftData `Entry` rows on
/// the main actor — keeping the non-Sendable `@Model` off the concurrency edge.
struct EntryDraft: Sendable, Hashable {
    var id: String
    var title: String
    /// Category id matching one of TopicConfig.categories.
    var category: String
    var summary: String?
    var articleURLString: String
    var thumbnailURLString: String?
    var metric: Int?
    var countryCode: String?
    var countryName: String?
    var startDate: Date?
}

// MARK: - Bundled seed catalog (Resources/SeedCatalog.json)

struct SeedCatalogFile: Decodable {
    var generatedAt: String?
    var entries: [SeedEntry]
}

struct SeedEntry: Decodable {
    var id: String
    var title: String
    /// Category id matching one of TopicConfig.categories.
    var category: String
    var summary: String?
    var articleURL: String
    var thumbnailURL: String?
    var metric: Int?
    var countryCode: String?
    var countryName: String?
    /// ISO-8601 date string (e.g. "1978-12-11") or nil.
    var startDate: String?

    func toDraft() -> EntryDraft {
        EntryDraft(
            id: id,
            title: title,
            category: category,
            summary: summary,
            articleURLString: articleURL,
            thumbnailURLString: thumbnailURL,
            metric: metric,
            countryCode: countryCode,
            countryName: countryName,
            startDate: SeedEntry.parseDate(startDate)
        )
    }

    static func parseDate(_ string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        if let date = formatter.date(from: string) { return date }
        // Fall back to year-only values like "1978".
        if let year = Int(string.prefix(4)) {
            var components = DateComponents()
            components.year = year
            components.month = 1
            components.day = 1
            return Calendar(identifier: .gregorian).date(from: components)
        }
        return nil
    }
}

// MARK: - Wikipedia REST summary

struct WikiSummary: Decodable {
    struct Thumbnail: Decodable { var source: String }
    struct ContentURLs: Decodable {
        struct Desktop: Decodable { var page: String }
        var desktop: Desktop
    }
    var title: String
    /// REST page type: "standard", "disambiguation", "no-extract", etc.
    var type: String?
    var extract: String?
    var description: String?
    var thumbnail: Thumbnail?
    var content_urls: ContentURLs?

    /// Minimum extract length to count as a real description (mirrors
    /// `Scripts/validate_catalog.py`). Title-only / disambiguation / no-extract
    /// pages fall below this and should be weeded out or hidden.
    static let minExtractLength = 20

    /// Whether this summary carries enough real content to show as a card with
    /// a description, rather than a bare title.
    var isUsable: Bool {
        if let type, type == "disambiguation" || type == "no-extract" { return false }
        let text = (extract ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count >= Self.minExtractLength
    }
}

// MARK: - Wikipedia Action API extract + category members

struct WikiExtractResponse: Decodable {
    struct Query: Decodable { var pages: [String: Page] }
    struct Page: Decodable {
        var title: String
        var extract: String?
    }
    var query: Query
}

struct WikiCategoryMembersResponse: Decodable {
    struct Query: Decodable { var categorymembers: [Member] }
    struct Member: Decodable {
        var title: String
        var ns: Int
    }
    var query: Query
}
