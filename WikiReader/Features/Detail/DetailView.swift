import SwiftUI

/// Distraction-free reading view (spec §9.2). Fetches + caches the body on first
/// open, then renders instantly offline. Always shows the mandatory attribution
/// footer (§11).
struct DetailView: View {
    @Environment(AppEnvironment.self) private var environment
    @Bindable var entry: Entry

    @State private var phase: Phase = .idle

    enum Phase { case idle, loading, ready, failed(String) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                metadata
                bodyContent
                AttributionFooter(title: entry.title, articleURL: entry.articleURL)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Palette.backgroundPrimary)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    environment.bookmarks.toggle(entry)
                } label: {
                    Image(systemName: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(entry.isBookmarked ? "Remove bookmark" : "Add bookmark")

                if let url = entry.articleURL {
                    ShareLink(item: url, subject: Text(entry.title)) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Link(destination: url) {
                        Image(systemName: "safari")
                    }
                    .accessibilityLabel("Open in Wikipedia")
                }
            }
        }
        .task { await load() }
    }

    // MARK: - Sections

    @ViewBuilder private var header: some View {
        if TopicConfig.showArticleImages, let url = entry.thumbnailURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Rectangle().fill(Palette.backgroundSecondary).frame(height: 180)
            }
            .frame(maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        Text(entry.title)
            .font(.readingTitle)
            .foregroundStyle(Palette.labelPrimary)
    }

    @ViewBuilder private var metadata: some View {
        let chips = metadataChips
        if !chips.isEmpty {
            HStack(spacing: Spacing.sm) {
                ForEach(chips, id: \.text) { chip in
                    MetadataChip(systemImage: chip.symbol, text: chip.text)
                }
            }
        }
    }

    @ViewBuilder private var bodyContent: some View {
        switch phase {
        case .idle, .loading:
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Palette.backgroundSecondary)
                        .frame(height: 14)
                }
            }
            .redacted(reason: .placeholder)
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await load(force: true) }
            }
        case .ready:
            if let summary = entry.summary, entry.body == nil {
                Text(summary).font(.readingBody)
            }
            Text(entry.body ?? "")
                .font(.readingBody)
                .foregroundStyle(Palette.labelPrimary)
                .lineSpacing(6)
                .textSelection(.enabled)
        }
    }

    // MARK: - Loading

    private func load(force: Bool = false) async {
        if entry.hasCachedBody && !force {
            phase = .ready
            return
        }
        phase = .loading
        do {
            try await environment.articles.ensureBody(for: entry)
            phase = .ready
        } catch {
            // If we at least have a summary, let the reader see it.
            if entry.summary != nil {
                phase = .ready
            } else {
                let message = (error as? LocalizedError)?.errorDescription
                    ?? "Couldn't load this article. Check your connection and retry."
                phase = .failed(message)
            }
        }
    }

    private struct Chip { let symbol: String; let text: String }

    private var metadataChips: [Chip] {
        var chips: [Chip] = []
        if TopicConfig.showRegionFilter, let country = entry.countryName {
            chips.append(Chip(symbol: "globe", text: country))
        }
        if let label = TopicConfig.metricLabel, let value = entry.metric {
            chips.append(Chip(symbol: TopicConfig.metricSymbol, text: "\(value) \(label)"))
        }
        if TopicConfig.showDateFacet, let date = entry.startDate {
            chips.append(Chip(symbol: "calendar", text: Self.yearFormatter.string(from: date)))
        }
        return chips
    }

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy"; return f
    }()
}
