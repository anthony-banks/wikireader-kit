import Foundation

/// Wikipedia REST + Action API: lead summaries, full clean article text, and
/// category traversal for Cold/Strange cases (spec §6.2, §6.3).
struct WikipediaService: Sendable {
    let http: HTTPClient

    private static let restBase = "https://en.wikipedia.org/api/rest_v1"
    private static let actionBase = "https://en.wikipedia.org/w/api.php"

    /// Lead summary used for cards and the detail header.
    func summary(title: String) async throws -> WikiSummary {
        let encoded = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        guard let url = URL(string: "\(Self.restBase)/page/summary/\(encoded)") else {
            throw HTTPError.badURL
        }
        return try await http.getJSON(WikiSummary.self, url: url)
    }

    /// Full plain-text article body (markup stripped) for the reading view.
    func extract(title: String) async throws -> String {
        guard var components = URLComponents(string: Self.actionBase) else { throw HTTPError.badURL }
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "prop", value: "extracts"),
            URLQueryItem(name: "explaintext", value: "1"),
            URLQueryItem(name: "exsectionformat", value: "plain"),
            URLQueryItem(name: "redirects", value: "1"),
            URLQueryItem(name: "titles", value: title),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
        ]
        guard let url = components.url else { throw HTTPError.badURL }

        // formatversion=2 returns pages as an array, not a keyed object.
        struct V2: Decodable {
            struct Query: Decodable { var pages: [Page] }
            struct Page: Decodable { var title: String; var extract: String? }
            var query: Query
        }
        let response = try await http.getJSON(V2.self, url: url)
        guard let extract = response.query.pages.first?.extract, !extract.isEmpty else {
            throw HTTPError.decoding
        }
        return extract
    }

    /// Article titles belonging to a category (Cold/Strange sourcing).
    func categoryMembers(category: String) async throws -> [String] {
        guard var components = URLComponents(string: Self.actionBase) else { throw HTTPError.badURL }
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "categorymembers"),
            URLQueryItem(name: "cmtitle", value: "Category:\(category)"),
            URLQueryItem(name: "cmlimit", value: "max"),
            URLQueryItem(name: "cmtype", value: "page"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "formatversion", value: "2"),
        ]
        guard let url = components.url else { throw HTTPError.badURL }

        struct V2: Decodable {
            struct Query: Decodable { var categorymembers: [Member] }
            struct Member: Decodable { var title: String; var ns: Int }
            var query: Query
        }
        let response = try await http.getJSON(V2.self, url: url)
        // ns == 0 keeps article pages only (drops "Category:"/"Template:" members).
        return response.query.categorymembers.filter { $0.ns == 0 }.map(\.title)
    }
}
