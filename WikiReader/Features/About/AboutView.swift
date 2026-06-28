import SwiftUI

/// About + mandatory Sources/licensing (spec §9.8, §11). Carries the general
/// Wikipedia / CC BY-SA credit and the privacy statement.
struct AboutView: View {
    private let licenseURL = URL(string: "https://creativecommons.org/licenses/by-sa/4.0/")!
    private let wikipediaURL = URL(string: "https://en.wikipedia.org")!
    private let privacyURL = TopicConfig.privacyPolicyURL

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(TopicConfig.appName)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.labelPrimary)
                    Text(version)
                        .font(.caption)
                        .foregroundStyle(Palette.labelSecondary)
                }
                Text(TopicConfig.aboutText)
                    .font(.callout)
                    .foregroundStyle(Palette.labelPrimary)
            }

            Section("Sources & licensing") {
                Text("Article content is sourced from Wikipedia, © its contributors, and is licensed under Creative Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0). Each article links back to its original Wikipedia page.")
                    .font(.callout)
                    .foregroundStyle(Palette.labelPrimary)
                Link("Creative Commons CC BY-SA 4.0", destination: licenseURL)
                Link("Wikipedia", destination: wikipediaURL)
            }

            Section("Privacy") {
                Text("This app collects no personal data. Bookmarks and cached articles are stored only on your device. There are no analytics, ads, or tracking.")
                    .font(.callout)
                    .foregroundStyle(Palette.labelPrimary)
                Link("Privacy policy", destination: privacyURL)
            }

            Section("Developer") {
                Text("Contact: \(TopicConfig.supportEmail)")
                    .font(.callout)
                    .foregroundStyle(Palette.labelSecondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Palette.accent)
    }
}
