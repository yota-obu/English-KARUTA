import SwiftUI

struct GameResultView: View {
    let viewModel: GameViewModel
    let onDismiss: () -> Void

    @State private var showShare = false
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Result Header
                    VStack(spacing: 8) {
                        Image(systemName: viewModel.phase.isCompleted ? "checkmark.circle.fill" : "clock.badge.exclamationmark.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(viewModel.phase.isCompleted ? ColorPalette.correctGreen : ColorPalette.timerOrange)
                            .scaleEffect(appearAnimation ? 1.0 : 0.3)

                        Text(viewModel.phase.isCompleted ? "Stage Clear!" : "Time Up!")
                            .font(FontStyles.titleLarge)
                            .foregroundStyle(ColorPalette.textPrimary)

                        Text("\(viewModel.stage.level.rawValue) Stage \(viewModel.stage.subLevel)")
                            .font(FontStyles.bodyMedium)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }

                    // Score
                    Text("\(viewModel.score)")
                        .font(FontStyles.scoreText)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .scaleEffect(appearAnimation ? 1.0 : 0.5)

                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        resultStat(icon: "target", label: "Accuracy",
                                   value: "\(Int(Double(viewModel.correctCount) / Double(max(1, viewModel.correctCount + viewModel.wrongCount)) * 100))%")
                        resultStat(icon: "flame.fill", label: "Max Streak",
                                   value: "\(viewModel.maxStreak)")
                        resultStat(icon: "checkmark.circle", label: "Correct",
                                   value: "\(viewModel.correctCount)/\(viewModel.stage.totalPairs)")
                        resultStat(icon: "xmark.circle", label: "Wrong",
                                   value: "\(viewModel.wrongCount)")
                    }
                    .padding(.horizontal, 20)

                    // Buttons
                    VStack(spacing: 12) {
                        Button(action: { showShare = true }) {
                            Label("Share Result", systemImage: "square.and.arrow.up")
                                .font(FontStyles.bodyLarge)
                                .foregroundStyle(ColorPalette.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .softCard(color: ColorPalette.backgroundElevated)
                        }

                        Button(action: onDismiss) {
                            Text("Back to Menu")
                                .font(FontStyles.bodyLarge)
                                .foregroundStyle(ColorPalette.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 40)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appearAnimation = true
            }
        }
        .sheet(isPresented: $showShare) {
            let session = GameSession(
                cefrLevel: viewModel.stage.level,
                stageNumber: viewModel.stage.subLevel,
                score: viewModel.score,
                totalPairs: viewModel.stage.totalPairs,
                correctPairs: viewModel.correctCount,
                wrongAttempts: viewModel.wrongCount,
                maxStreak: viewModel.maxStreak,
                elapsedSeconds: viewModel.timeLimit - viewModel.timeRemaining,
                timeLimitSeconds: viewModel.timeLimit,
                isCompleted: viewModel.phase.isCompleted
            )
            let image = ShareCardView(session: session).renderAsImage()
            ShareSheet(items: [image, "Karuta - \(viewModel.stage.level.rawValue) Stage \(viewModel.stage.subLevel): \(viewModel.score) points!"])
        }
    }

    private func resultStat(icon: String, label: String, value: String) -> some View {
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
