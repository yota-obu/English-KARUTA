import SwiftUI

struct GameView: View {
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

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

    // MARK: - Helpers

    /// Time string for the current game mode.
    /// - maxCorrect: count DOWN from 60s (remaining)
    /// - timeAttack: count UP from 0s (elapsed)
    private var timeString: String {
        let total: Double
        if viewModel.stage.mode == .maxCorrect {
            total = max(0, viewModel.timeRemaining)
        } else {
            total = max(0, viewModel.timeLimit - viewModel.timeRemaining)
        }
        let mins = Int(total) / 60
        let secs = Int(total) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private var timerColor: Color {
        // Only the count-down (maxCorrect) mode shows urgency colors near zero.
        guard viewModel.stage.mode == .maxCorrect else {
            return ColorPalette.textPrimary
        }
        if viewModel.timeRemaining <= 5 {
            return ColorPalette.timerCritical
        } else if viewModel.timeRemaining <= 10 {
            return ColorPalette.timerOrange
        }
        return ColorPalette.textPrimary
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: 0) {
            // Top: Quit button (left aligned)
            HStack {
                Button {
                    HapticManager.shared.cardTap()
                    viewModel.cancelGame()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ColorPalette.slate)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(ColorPalette.backgroundCard))
                        .shadow(color: ColorPalette.liquidShadowColor, radius: 6, y: 3)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Big metric block — pushed lower so it sits above the cards
            VStack(spacing: 8) {
                if viewModel.stage.mode == .maxCorrect {
                    Text("\(viewModel.pairsCompleted)")
                        .font(.system(size: 120, weight: .heavy, design: .rounded))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .monospacedDigit()
                    Text(timeString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)
                        .monospacedDigit()
                } else {
                    Text("\(viewModel.pairsCompleted) / \(viewModel.stage.totalPairs)")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .monospacedDigit()
                    Text(timeString)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(timerColor)
                        .monospacedDigit()
                }
            }
            .padding(.top, 24)

            Spacer(minLength: 16)

            // Card Columns — use indices so that changing GameCard.id triggers
            // a full view recreation with the transition applied.
            HStack(alignment: .center, spacing: GameConstants.columnSpacing) {
                VStack(spacing: GameConstants.cardSpacing) {
                    ForEach(viewModel.englishCards.indices, id: \.self) { idx in
                        let card = viewModel.englishCards[idx]
                        GameCardView(card: card) {
                            viewModel.selectCard(card, column: .english)
                        }
                        .id(card.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: GameConstants.cardSpacing) {
                    ForEach(viewModel.japaneseCards.indices, id: \.self) { idx in
                        let card = viewModel.japaneseCards[idx]
                        GameCardView(card: card) {
                            viewModel.selectCard(card, column: .japanese)
                        }
                        .id(card.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .animation(.easeInOut(duration: 0.6), value: viewModel.englishCards.map(\.id))
            .animation(.easeInOut(duration: 0.6), value: viewModel.japaneseCards.map(\.id))

            Spacer(minLength: 24)
        }
    }
}
