import Foundation

/// One browse category = one tab. Defined per app in `TopicConfig.categories`.
/// The engine renders a tab for each, and each `Entry` stores the category `id`.
struct TopicCategory: Identifiable, Hashable, Sendable {
    /// Stable key stored on every Entry and in Catalog.json (e.g. "alpha").
    let id: String
    /// Tab + navigation title.
    let title: String
    /// SF Symbol for the tab item.
    let symbol: String
    /// Optional Wikipedia source category for `generate_catalog.py`
    /// (e.g. "Category:Golden_Age_of_Piracy"). Not used at runtime.
    let wikipediaCategory: String?

    init(id: String, title: String, symbol: String, wikipediaCategory: String? = nil) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.wikipediaCategory = wikipediaCategory
    }
}
