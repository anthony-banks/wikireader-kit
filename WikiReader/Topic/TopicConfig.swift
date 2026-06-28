import SwiftUI

// ============================================================================
//  TOPIC CONFIG — the ONE file you edit to make a new app.
//  Everything topic-specific lives here. You should not need to touch anything
//  outside the `Topic/` folder (this file + Catalog.json + the AccentColor and
//  AppIcon assets). The engine reads from here.
//
//  Markers `// ⟨REPLACE⟩` show what to change per app.
//  Tip: `scaffold.py` fills most of this from a small topic.json for you.
// ============================================================================

enum TopicConfig {

    // MARK: - Identity  ⟨REPLACE⟩

    /// Display name used in About + the Wikimedia User-Agent. Keep it short.
    static let appName = "WikiReader"

    /// One-line description shown in About.
    static let tagline = "A Wikipedia reference reader."

    /// Longer About blurb — what this app is and the respectful framing.
    static let aboutText =
        "A clean, distraction-free reference reader sourced entirely from Wikipedia. "
        + "Browse curated topics, read offline, and save what interests you."

    // MARK: - Contact / URLs  ⟨REPLACE⟩  (Wikimedia blocks placeholder agents)

    static let supportEmail = "you@example.com"
    static let websiteURL = URL(string: "https://example.com")!
    static let privacyPolicyURL = URL(string: "https://example.com/privacy.html")!

    // MARK: - Categories (the tabs)  ⟨REPLACE⟩
    //  `id` is the stable key stored on each entry and in Catalog.json.
    //  `wikipediaCategory` is optional and only used by generate_catalog.py.

    static let categories: [TopicCategory] = [
        TopicCategory(id: "alpha", title: "Topic A", symbol: "circle",
                      wikipediaCategory: "Category:Replace_me_A"),
        TopicCategory(id: "beta",  title: "Topic B", symbol: "square",
                      wikipediaCategory: "Category:Replace_me_B"),
        TopicCategory(id: "gamma", title: "Topic C", symbol: "triangle",
                      wikipediaCategory: "Category:Replace_me_C"),
    ]

    // MARK: - Metric facet  ⟨REPLACE⟩
    //  A single optional number per entry (e.g. "victims", "ships", "year built").
    //  Set `metricLabel` to nil to hide the metric chip + filter entirely.

    static let metricLabel: String? = nil
    static let metricSymbol = "number"
    static let metricThresholds = [1, 5, 10, 20, 50]

    // MARK: - Which facets appear

    /// The "region/country" filter + chip.
    static let showRegionFilter = true
    /// Chronological sort + the year chip.
    static let showDateFacet = true

    // MARK: - First-launch disclaimer  ⟨REPLACE or leave nil⟩
    //  Set both to nil for topics that need no content warning (e.g. odd facts).

    static let disclaimerTitle: String? = nil
    static let disclaimerBody: String? = nil

    // MARK: - Feature flags

    /// Article images are off by default: per-file Wikipedia image licenses vary
    /// and some are non-free, which is risky in a paid app. Flip on only after
    /// adding a Commons-license check.
    static let showArticleImages = false

    // MARK: - Derived (don't edit)

    static var wikimediaUserAgent: String {
        "\(appName.replacingOccurrences(of: " ", with: ""))/1.0 "
        + "(\(websiteURL.absoluteString); \(supportEmail))"
    }

    static func category(for id: String) -> TopicCategory? {
        categories.first { $0.id == id }
    }
}
