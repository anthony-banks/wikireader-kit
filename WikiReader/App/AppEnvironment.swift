import Foundation
import SwiftData
import Observation

/// Composition root. Builds the SwiftData container once and vends the three
/// repositories the views use. Injected into the environment by the App.
@MainActor
@Observable
final class AppEnvironment {
    let modelContainer: ModelContainer
    let catalog: CatalogRepository
    let articles: ArticleRepository
    let bookmarks: BookmarkRepository
    let offline: OfflineDownloader

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: Entry.self)
        } catch {
            // A failed store is unrecoverable; an in-memory fallback keeps the
            // app usable (seed re-loads each launch) rather than crashing.
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: Entry.self, configurations: config)
        }
        self.modelContainer = container

        let context = container.mainContext
        let http = HTTPClient()
        let wikipedia = WikipediaService(http: http)

        self.catalog = CatalogRepository(context: context, wikipedia: wikipedia)
        let articleRepository = ArticleRepository(context: context, wikipedia: wikipedia)
        self.articles = articleRepository
        self.bookmarks = BookmarkRepository(context: context)
        self.offline = OfflineDownloader(articles: articleRepository)
    }
}
