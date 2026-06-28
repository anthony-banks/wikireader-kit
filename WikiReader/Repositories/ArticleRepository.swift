import Foundation
import SwiftData

/// Fetches an article's full body on demand the first time its detail view
/// opens, then caches it permanently in SwiftData so the article is readable
/// offline forever after (spec §6.4, §9.6).
@MainActor
final class ArticleRepository {
    private let context: ModelContext
    private let wikipedia: WikipediaService

    init(context: ModelContext, wikipedia: WikipediaService) {
        self.context = context
        self.wikipedia = wikipedia
    }

    /// Ensures `entry.body` is populated. No-op (instant, offline) if cached.
    /// Throws a user-presentable HTTPError when a first fetch fails offline.
    func ensureBody(for entry: Entry, markViewed: Bool = true) async throws {
        if markViewed { entry.lastViewedAt = Date() }

        if entry.hasCachedBody {
            if markViewed { try? context.save() }
            return
        }

        let title = entry.wikiTitle
        // Backfill the summary/thumbnail too if we never had them (seed-lite rows).
        if entry.summary == nil || entry.thumbnailURLString == nil {
            if let summary = try? await wikipedia.summary(title: title) {
                entry.summary = entry.summary ?? summary.extract
                entry.thumbnailURLString = entry.thumbnailURLString ?? summary.thumbnail?.source
                if entry.articleURLString.isEmpty,
                   let page = summary.content_urls?.desktop.page {
                    entry.articleURLString = page
                }
            }
        }

        let body = try await wikipedia.extract(title: title)
        entry.body = body
        entry.bodyFetchedAt = Date()
        try? context.save()
    }

    /// Entries whose full body hasn't been cached yet — the work list for a
    /// bulk offline download.
    func entriesNeedingBody() -> [Entry] {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.body == nil },
            sortBy: [SortDescriptor(\.title)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func clearCachedBodies() {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.body != nil }
        )
        guard let entries = try? context.fetch(descriptor) else { return }
        for entry in entries {
            entry.body = nil
            entry.bodyFetchedAt = nil
        }
        try? context.save()
    }
}

extension Entry {
    /// The Wikipedia page title, derived from the canonical article URL's last
    /// path component (handles the "enwiki:{title}" id form too).
    var wikiTitle: String {
        if let url = articleURL, let last = url.pathComponents.last {
            return last.removingPercentEncoding ?? last
        }
        if id.hasPrefix("enwiki:") { return String(id.dropFirst("enwiki:".count)) }
        return title
    }
}
