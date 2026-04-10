import SwiftUI

struct ShareCardView: View {
    let session: GameSession

    var body: some View {
        VStack(spacing: 16) {
            Text("英単語かるた")
                .font(FontStyles.titleLarge)
                .foregroundStyle(
                    LinearGradient(
                        colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                        startPoint: .leading, endPoint: .trailing
                    )
                )

            Text("\(session.cefrLevel) • \(session.modeDisplay)")
                .font(FontStyles.bodyLarge)
                .foregroundStyle(ColorPalette.textSecondary)

            Text("\(session.score)")
                .font(FontStyles.scoreText)
                .foregroundStyle(ColorPalette.textPrimary)

            HStack(spacing: 24) {
                StatItem(label: "Accuracy", value: "\(Int(session.accuracy * 100))%")
                StatItem(label: "Streak", value: "\(session.maxStreak)")
                StatItem(label: "Pairs", value: "\(session.correctPairs)/\(session.totalPairs)")
            }
        }
        .padding(32)
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(ColorPalette.backgroundCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [ColorPalette.accentPrimary.opacity(0.5), ColorPalette.accentSecondary.opacity(0.5)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

private struct StatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(FontStyles.titleSmall)
                .foregroundStyle(ColorPalette.textPrimary)
            Text(label)
                .font(FontStyles.caption)
                .foregroundStyle(ColorPalette.textTertiary)
        }
    }
}

extension ShareCardView {
    @MainActor
    func renderAsImage() -> UIImage {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage ?? UIImage()
    }
}
