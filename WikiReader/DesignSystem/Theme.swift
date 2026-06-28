import SwiftUI

/// Semantic colors. Each maps to a named Color Set in Assets.xcassets that
/// carries both a light ("Any Appearance") and dark value. Views reference
/// these by name only — never raw hex — so light/dark both stay correct.
enum Palette {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let backgroundTertiary = Color("BackgroundTertiary")
    static let labelPrimary = Color("LabelPrimary")
    static let labelSecondary = Color("LabelSecondary")
    static let labelTertiary = Color("LabelTertiary")
    static let separator = Color("Separator")
    /// Primary accent — swap AccentColor.colorset (or via scaffold.py) to rebrand.
    static let accent = Color("AccentColor")
    static let accentPressed = Color("AccentPressed")
    static let accentFill = Color("AccentFill")
    static let accentOnFill = Color("AccentOnFill")
}

/// User-selectable appearance. Persisted as a raw string in AppStorage.
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// nil tells SwiftUI to follow the system setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
