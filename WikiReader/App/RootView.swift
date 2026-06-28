import SwiftUI

/// Root tab shell: one tab per TopicConfig category + Saved + Settings.
/// Also drives the optional one-time first-launch content disclaimer.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false
    @AppStorage("offlineModeEnabled") private var offlineEnabled = false

    var body: some View {
        TabView {
            ForEach(TopicConfig.categories) { category in
                NavigationStack {
                    CategoryListView(category: category)
                }
                .tabItem {
                    Label(category.title, systemImage: category.symbol)
                }
            }

            NavigationStack {
                SavedView()
            }
            .tabItem { Label("Saved", systemImage: "bookmark.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            await environment.catalog.bootstrap()
            // If offline mode is on, top up any articles still missing a body.
            if offlineEnabled {
                environment.offline.start()
            }
        }
        .sheet(isPresented: disclaimerBinding) {
            DisclaimerView { hasSeenDisclaimer = true }
                .interactiveDismissDisabled()
        }
    }

    /// Only presented when the app configures a disclaimer (some topics need
    /// none). When `disclaimerBody` is nil the sheet never shows.
    private var disclaimerBinding: Binding<Bool> {
        Binding(
            get: { TopicConfig.disclaimerBody != nil && !hasSeenDisclaimer },
            set: { showing in if !showing { hasSeenDisclaimer = true } }
        )
    }
}
