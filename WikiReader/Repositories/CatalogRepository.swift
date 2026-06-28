import Foundation
import SwiftData

/// Owns the local catalog: seeds it from the bundled Catalog.json on launch and
/// serves it to the UI. The UI never blocks on the network — it reads the local
/// store, which is always populated from the bundled seed.
///
/// The bundled seed is generated offline by `Scripts/generate_catalog.py`, so
/// there's no in-app catalog crawling. (Article *bodies* are still fetched and
/// cached on demand by ArticleRepository.)
@MainActor
final class CatalogRepository {
    private let context: ModelContext
    private let wikipedia: WikipediaService

    init(context: ModelContext, wikipedia: WikipediaService) {
        self.context = context
        self.wikipedia = wikipedia
    }

    /// Called once on launch. Seeds from the bundle if entries are missing.
    func bootstrap() async {
        syncSeed()
    }

    // MARK: - Seed

    /// Inserts any bundled seed entries not already in the store. Runs every
    /// launch (not just the first) so adding rows to Catalog.json shows up
    /// without wiping the app — existing entries, bookmarks, and cached bodies
    /// are left untouched.
    private func syncSeed() {
        guard
            let url = Bundle.main.url(forResource: "SeedCatalog", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let file = try? JSONDecoder().decode(SeedCatalogFile.self, from: data)
        else {
            assertionFailure("SeedCatalog.json missing or malformed")
            return
        }
        let now = Date()
        var inserted = 0
        for draft in file.entries.map({ $0.toDraft() }) {
            let id = draft.id
            let descriptor = FetchDescriptor<Entry>(predicate: #Predicate { $0.id == id })
            let exists = ((try? context.fetchCount(descriptor)) ?? 0) > 0
            if !exists {
                insert(draft, updatedAt: now)
                inserted += 1
            }
        }
        if inserted > 0 { try? context.save() }
    }

    private func insert(_ draft: EntryDraft, updatedAt: Date) {
        let entry = Entry(
            id: draft.id,
            title: draft.title,
            categoryID: draft.category,
            summary: draft.summary,
            articleURLString: draft.articleURLString,
            thumbnailURLString: draft.thumbnailURLString,
            metric: draft.metric,
            countryCode: draft.countryCode,
            countryName: draft.countryName,
            startDate: draft.startDate,
            catalogUpdatedAt: updatedAt
        )
        context.insert(entry)
    }
}
