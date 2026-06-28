import SwiftUI

/// Reading-view typography tuned for comfortable long-form reading.
/// All sizes are relative styles so Dynamic Type scales them automatically.
extension Font {
    static let readingBody = Font.system(.body, design: .serif)
    static let readingTitle = Font.system(.largeTitle, design: .serif).weight(.semibold)
    static let readingHeading = Font.system(.title3, design: .serif).weight(.semibold)
}

/// Shared spacing scale so layout stays consistent across screens.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
