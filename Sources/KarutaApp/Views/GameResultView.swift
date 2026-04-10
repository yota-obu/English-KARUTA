import SwiftUI

struct GameResultView: View {
    let viewModel: GameViewModel
    let onDismiss: () -> Void

    @State private var showShare = false
    @State private var appearAnimation = false

    private var isMaxCorrect: Bool { viewModel.stage.mode == .maxCorrect }

    private var headerTitle: String {
        if isMaxCorrect {
            return "Time Up!"
        } else {
            return viewModel.phase.isCompleted ? "Finish!" : "Time Up!"
        }
    }

    private var headerIcon: String {
        if isMaxCorrect {
            return "clock.badge.checkmark.fill"
        }
        return viewModel.phase.isCompleted ? "checkmark.circle.fill" : "clock.badge.exclamationmark.fill"
    }

    private var headerColor: Color {
        if isMaxCorrect {
            return ColorPalette.accentPrimary
        }
        return viewModel.phase.isCompleted ? ColorPalette.correctGreen : ColorPalette.timerOrange
    }

    private var primaryValue: String {
        if isMaxCorrect {
            return "\(viewModel.correctCount)"
        } else {
            let elapsed = viewModel.timeLimit - viewModel.timeRemaining
            return String(format: "%.1fs", elapsed)
        }
    }

    private var primaryLabel: String {
        isMaxCorrect ? "pairs" : "time"
    }

    private var accuracy: Int {
        let total = viewModel.correctCount + viewModel.wrongCount
        guard total > 0 else { return 0 }
        return Int(Double(viewModel.correctCount) / Double(total) * 100)
    }

    private var shareSummary: String {
        if isMaxCorrect {
            return "英単語かるた - \(viewModel.stage.level.rawValue) 1 min: \(viewModel.correctCount) pairs!"
        } else {
            return "英単語かるた - \(viewModel.stage.level.rawValue) 15 pairs: \(primaryValue)!"
        }
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                // Result Header
                VStack(spacing: 8) {
                    Image(systemName: headerIcon)
                        .font(.system(size: 56))
                        .foregroundStyle(headerColor)
                        .scaleEffect(appearAnimation ? 1.0 : 0.3)

                    Text(headerTitle)
                        .font(FontStyles.titleLarge)
                        .foregroundStyle(ColorPalette.textPrimary)

                    Text("\(viewModel.stage.level.rawValue) • \(viewModel.stage.mode.shortName)")
                        .font(FontStyles.bodyMedium)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Primary metric (pairs for 1m, time for 15p)
                VStack(spacing: 4) {
                    Text(primaryValue)
                        .font(FontStyles.scoreText)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .scaleEffect(appearAnimation ? 1.0 : 0.5)
                    Text(primaryLabel)
                        .font(FontStyles.bodyMedium)
                        .foregroundStyle(ColorPalette.textSecondary)
                }

                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    resultStat(icon: "target", label: "Accuracy",
                               value: "\(accuracy)%")
                    resultStat(icon: "xmark.circle", label: "Wrong",
                               value: "\(viewModel.wrongCount)")
                }
                .padding(.horizontal, 20)

                Spacer()

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
                            .foregroundStyle(.white)
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
                .padding(.bottom, 40)
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
                stageNumber: 0,
                score: viewModel.score,
                totalPairs: viewModel.stage.totalPairs,
                correctPairs: viewModel.correctCount,
                wrongAttempts: viewModel.wrongCount,
                maxStreak: viewModel.maxStreak,
                elapsedSeconds: viewModel.timeLimit - viewModel.timeRemaining,
                timeLimitSeconds: viewModel.timeLimit,
                isCompleted: viewModel.phase.isCompleted,
                gameMode: viewModel.stage.mode.rawValue
            )
            let image = ShareCardView(session: session).renderAsImage()
            ShareSheet(items: [image, shareSummary])
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
