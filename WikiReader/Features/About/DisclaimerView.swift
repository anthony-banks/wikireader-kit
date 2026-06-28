import SwiftUI

/// One-time, dismissible first-launch content disclaimer (spec §12).
struct DisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundStyle(Palette.accent)

            Text(TopicConfig.disclaimerTitle ?? "Before you begin")
                .font(.title.weight(.semibold))
                .foregroundStyle(Palette.labelPrimary)

            Text(TopicConfig.disclaimerBody ?? "")
                .font(.callout)
                .foregroundStyle(Palette.labelSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.md)

            Spacer()

            Button(action: onAccept) {
                Text("I understand")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(Spacing.xl)
        .background(Palette.backgroundPrimary)
    }
}
