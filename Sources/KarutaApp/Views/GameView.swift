import SwiftUI

struct GameView: View {
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            VStack {
                // Always visible: back button + debug info
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(ColorPalette.textSecondary)
                    }
                    .padding(.leading, 16)

                    Spacer()
                }
                .padding(.top, 8)

                Spacer()

                // Phase content
                switch viewModel.phase {
                case .loading:
                    loadingView
                case .countdown:
                    countdownOverlay
                case .playing:
                    gameContent
                case .completed, .timeUp:
                    GameResultView(viewModel: viewModel, onDismiss: { dismiss() })
                case .error(let message):
                    errorView(message)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.light)
        .task {
            await viewModel.startGame()
        }
        .onDisappear {
            viewModel.cancelGame()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(ColorPalette.accentPrimary)
                .scaleEffect(1.5)
            Text("Loading words...")
                .font(FontStyles.bodyLarge)
                .foregroundStyle(ColorPalette.textPrimary)
        }
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ColorPalette.timerOrange)
            Text(message)
                .font(FontStyles.bodyMedium)
                .foregroundStyle(ColorPalette.textPrimary)
                .multilineTextAlignment(.center)
            Button("Back") { dismiss() }
                .font(FontStyles.bodyLarge)
                .foregroundStyle(ColorPalette.accentPrimary)
                .padding(.top, 8)
        }
        .padding(32)
    }

    // MARK: - Countdown

    private var countdownOverlay: some View {
        Text("\(viewModel.countdownValue)")
            .font(.system(size: 96, weight: .heavy, design: .rounded))
            .foregroundStyle(ColorPalette.accentPrimary)
            .scaleEffect(1.2)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.countdownValue)
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: 12) {
            // Header: Score + Streak + Timer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)
                    Text("\(viewModel.score)")
                        .font(FontStyles.titleMedium)
                        .foregroundStyle(ColorPalette.textPrimary)
                }

                Spacer()

                StreakBadgeView(streak: viewModel.streak)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Pairs")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)
                    Text("\(viewModel.pairsCompleted)/\(viewModel.stage.totalPairs)")
                        .font(FontStyles.titleSmall)
                        .foregroundStyle(ColorPalette.textPrimary)
                }
            }
            .padding(.horizontal, 20)

            TimerBarView(progress: viewModel.timerProgress, timeRemaining: viewModel.timeRemaining)
                .padding(.horizontal, 20)

            // Card Columns
            HStack(alignment: .top, spacing: GameConstants.columnSpacing) {
                // English column
                VStack(spacing: GameConstants.cardSpacing) {
                    Text("English")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)

                    ForEach(viewModel.englishCards) { card in
                        GameCardView(card: card) {
                            viewModel.selectCard(card, column: .english)
                        }
                    }
                }
                .frame(maxWidth: .infinity)

                // Japanese column
                VStack(spacing: GameConstants.cardSpacing) {
                    Text("日本語")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)

                    ForEach(viewModel.japaneseCards) { card in
                        GameCardView(card: card) {
                            viewModel.selectCard(card, column: .japanese)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)

            Spacer()

            // Score Popup
            if let popup = viewModel.scorePopup {
                ScorePopupView(info: popup)
            }
        }
        .padding(.top, 8)
    }
}
