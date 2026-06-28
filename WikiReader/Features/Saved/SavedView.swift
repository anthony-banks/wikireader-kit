import SwiftUI
import SwiftData

/// Aggregates bookmarks across all categories (spec §9.5). Offline-capable.
struct SavedView: View {
    @Environment(AppEnvironment.self) private var environment

    @Query(
        filter: #Predicate<Entry> { $0.isBookmarked == true },
        sort: \Entry.title
    )
    private var saved: [Entry]

    var body: some View {
        Group {
            if saved.isEmpty {
                EmptyStateView(
                    systemImage: "bookmark",
                    title: "No saved cases",
                    message: "Swipe a row or tap the bookmark in any article to save it here."
                )
            } else {
                List {
                    ForEach(saved) { entry in
                        NavigationLink(value: entry) {
                            EntryRow(entry: entry)
                        }
                        .listRowBackground(Palette.backgroundPrimary)
                        .swipeActions {
                            Button(role: .destructive) {
                                environment.bookmarks.toggle(entry)
                            } label: {
                                Label("Remove", systemImage: "bookmark.slash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .background(Palette.backgroundPrimary)
        .navigationTitle("Saved")
        .navigationDestination(for: Entry.self) { DetailView(entry: $0) }
    }
}
