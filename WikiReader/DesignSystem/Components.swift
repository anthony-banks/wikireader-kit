import SwiftUI

/// A single metadata pill (region, metric, year). Rendered only when the
/// underlying value exists — callers pass nil-safe strings.
struct MetadataChip: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption2.weight(.medium))
            .foregroundStyle(Palette.accentOnFill)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Palette.accentFill, in: Capsule())
    }
}

/// One row in any category list. Optional thumbnail (only when an image loads),
/// title, and up to a few metadata chips that appear only when data exists.
struct EntryRow: View {
    let entry: Entry

    var body: some View {
        HStack(spacing: Spacing.md) {
            thumbnail

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundStyle(Palette.labelPrimary)
                    .lineLimit(2)

                if !chips.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        ForEach(chips, id: \.text) { chip in
                            MetadataChip(systemImage: chip.symbol, text: chip.text)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if entry.isBookmarked {
                Image(systemName: "bookmark.fill")
                    .font(.footnote)
                    .foregroundStyle(Palette.accent)
                    .accessibilityLabel("Bookmarked")
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    /// Shown only when an article image actually loads. With images disabled —
    /// or while loading / on failure — the row renders no preview box at all
    /// (no silhouette placeholder).
    @ViewBuilder private var thumbnail: some View {
        if TopicConfig.showArticleImages, let url = entry.thumbnailURL {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFill()
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private struct Chip { let symbol: String; let text: String }

    private var chips: [Chip] {
        var result: [Chip] = []
        if TopicConfig.showRegionFilter, let country = entry.countryName {
            result.append(Chip(symbol: "globe", text: country))
        }
        if TopicConfig.metricLabel != nil, let value = entry.metric {
            result.append(Chip(symbol: TopicConfig.metricSymbol, text: "\(value)"))
        }
        if TopicConfig.showDateFacet, let year = entry.startDate.map(Self.yearFormatter.string(from:)) {
            result.append(Chip(symbol: "calendar", text: year))
        }
        return Array(result.prefix(2))
    }

    private static let yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
        return f
    }()
}

/// Redacted placeholder shown while seed/cached data loads.
struct SkeletonRow: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Palette.backgroundTertiary)
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: Spacing.sm) {
                RoundedRectangle(cornerRadius: 4).fill(Palette.backgroundTertiary).frame(height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Palette.backgroundTertiary).frame(width: 120, height: 10)
            }
        }
        .padding(.vertical, Spacing.xs)
        .redacted(reason: .placeholder)
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

struct ErrorStateView: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Palette.labelSecondary)
            Text(message)
                .font(.callout)
                .foregroundStyle(Palette.labelSecondary)
                .multilineTextAlignment(.center)
            if let retry {
                Button("Retry", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(Spacing.xl)
    }
}

/// MANDATORY per spec §11. Every reading view shows this; the article title
/// links to its canonical Wikipedia URL and the license links to CC BY-SA 4.0.
struct AttributionFooter: View {
    let title: String
    let articleURL: URL?

    private static let licenseURL = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Divider()
            Text(attributedSource)
                .font(.caption)
                .foregroundStyle(Palette.labelSecondary)
                .tint(Palette.accent)
        }
        .padding(.top, Spacing.lg)
        .accessibilityElement(children: .combine)
    }

    private var attributedSource: AttributedString {
        var string = AttributedString("Source: ")
        var name = AttributedString(title)
        if let articleURL { name.link = articleURL }
        name.font = .caption.italic()
        let middle = AttributedString(" from Wikipedia, licensed under ")
        var license = AttributedString("CC BY-SA 4.0")
        license.link = Self.licenseURL
        let end = AttributedString(".")
        string.append(name)
        string.append(middle)
        string.append(license)
        string.append(end)
        return string
    }
}
