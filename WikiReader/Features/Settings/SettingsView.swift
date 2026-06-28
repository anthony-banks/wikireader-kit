import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue
    @AppStorage("offlineModeEnabled") private var offlineEnabled = false
    @State private var showingClearConfirm = false

    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $themeRaw) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
            }

            Section("Offline") {
                Toggle("Download all articles", isOn: $offlineEnabled)
                    .onChange(of: offlineEnabled) { _, enabled in
                        if enabled {
                            environment.offline.start()
                        } else {
                            environment.offline.cancel()
                        }
                    }
                offlineStatus
                Text("Pre-downloads every article so the whole catalog reads offline. Downloads are added to your cache; turning this off keeps what's already saved.")
                    .font(.caption)
                    .foregroundStyle(Palette.labelSecondary)
            }

            Section("Storage") {
                Button("Clear cached articles") { showingClearConfirm = true }
                Text("Removes downloaded article text. Your bookmarks are kept; articles re-download when next opened.")
                    .font(.caption)
                    .foregroundStyle(Palette.labelSecondary)
            }

            Section("About") {
                NavigationLink {
                    AboutView()
                } label: {
                    Label("About & Sources", systemImage: "info.circle")
                }
            }
        }
        .navigationTitle("Settings")
        .background(Palette.backgroundPrimary)
        .confirmationDialog("Clear cached articles?", isPresented: $showingClearConfirm, titleVisibility: .visible) {
            Button("Clear", role: .destructive) { environment.articles.clearCachedBodies() }
            Button("Cancel", role: .cancel) {}
        }
    }

    @ViewBuilder private var offlineStatus: some View {
        let downloader = environment.offline
        switch downloader.state {
        case .downloading:
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    ProgressView(value: downloader.progress)
                    Text("\(downloader.completed)/\(downloader.total)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Palette.labelSecondary)
                }
                Text("Downloading articles…")
                    .font(.caption)
                    .foregroundStyle(Palette.labelSecondary)
            }
        case .completed where offlineEnabled:
            Label(
                downloader.failures > 0
                    ? "All available articles saved (\(downloader.failures) couldn't be fetched)"
                    : "All articles saved for offline",
                systemImage: "checkmark.circle"
            )
            .font(.caption)
            .foregroundStyle(Palette.accent)
        default:
            EmptyView()
        }
    }
}
