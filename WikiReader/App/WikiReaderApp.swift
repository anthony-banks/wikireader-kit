import SwiftUI
import SwiftData

@main
struct WikiReaderApp: App {
    @State private var environment = AppEnvironment()
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .tint(Palette.accent)
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        }
        .modelContainer(environment.modelContainer)
    }
}
