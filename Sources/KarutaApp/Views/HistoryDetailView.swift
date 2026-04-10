import SwiftUI

struct HistoryDetailView: View {
    let session: GameSession

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "clock.badge.exclamationmark.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(session.isCompleted ? ColorPalette.correctGreen : ColorPalette.timerOrange)

                        Text(session.isCompleted ? "Stage Clear!" : "Time Up!")
                            .font(FontStyles.titleLarge)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text("\(session.cefrLevel) Stage \(session.stageNumber)")
                            .font(FontStyles.bodyMedium)
                            .foregroundStyle(ColorPalette.textSecondary)

                        Text(session.playedAt.formatted(date: .long, time: .shortened))
                            .font(FontStyles.caption)
                            .foregroundStyle(ColorPalette.textTertiary)
                    }

                    // Score
                    Text("\(session.score)")
                        .font(FontStyles.scoreText)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )

                    // Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        detailStat(icon: "target", label: "Accuracy", value: "\(Int(session.accuracy * 100))%")
                        detailStat(icon: "flame.fill", label: "Max Streak", value: "\(session.maxStreak)")
                        detailStat(icon: "checkmark.circle", label: "Correct", value: "\(session.correctPairs)/\(session.totalPairs)")
                        detailStat(icon: "xmark.circle", label: "Wrong", value: "\(session.wrongAttempts)")
                        detailStat(icon: "timer", label: "Time", value: String(format: "%.1fs", session.elapsedSeconds))
                        detailStat(icon: "hourglass", label: "Limit", value: "\(Int(session.timeLimitSeconds))s")
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
            }

    private func detailStat(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ColorPalette.accentTertiary)
            Text(value)
                .font(FontStyles.titleSmall)
                .foregroundStyle(ColorPalette.textPrimary)
            Text(label)
                .font(FontStyles.caption)
                .foregroundStyle(ColorPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .softCard(color: ColorPalette.backgroundCard)
    }
}
