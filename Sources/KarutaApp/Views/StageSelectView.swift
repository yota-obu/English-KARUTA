import SwiftUI
import SwiftData

struct StageSelectView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSessions: [GameSession]
    @State private var selectedLevel: CEFRLevel = .a1
    @State private var selectedStage: Stage?

    private let dictionaryService = DictionaryService.shared

    // MARK: - Best Records

    /// Best for Basic mode (level + game mode combo).
    /// - max_correct: highest score / pairs count
    /// - time_attack: lowest elapsed time among completed sessions
    private func basicBest(level: CEFRLevel, mode: GameMode) -> GameSession? {
        let levelStr = level.rawValue
        let modeStr = mode.rawValue
        let candidates = allSessions.filter {
            $0.cefrLevel == levelStr && $0.gameMode == modeStr && $0.topic == nil
        }
        switch mode {
        case .maxCorrect:
            return candidates.max(by: { $0.correctPairs < $1.correctPairs })
        case .timeAttack:
            return candidates.filter { $0.isCompleted }.min(by: { $0.elapsedSeconds < $1.elapsedSeconds })
        }
    }

    private func categoryBest(topic: String, rank: String) -> GameSession? {
        allSessions
            .filter { $0.topic == topic && $0.categoryRank == rank && $0.isCompleted }
            .min(by: { $0.elapsedSeconds < $1.elapsedSeconds })
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            basicModeContent
                .padding(.top, 32)
        }
        .navigationTitle("Play")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedStage) { stage in
            GameView(viewModel: GameViewModel(
                stage: stage,
                dictionaryService: dictionaryService,
                historyStore: GameHistoryStore(modelContext: modelContext)
            ))
        }
    }

    // MARK: - Basic Mode

    private var basicModeContent: some View {
        VStack(spacing: 20) {
            // Section: Level Select
            sectionLabel("Level Select")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CEFRLevel.allCases) { level in
                        levelChip(level)
                    }
                }
                .padding(.horizontal, 20)
            }

            // Section: Mode Select (between level and mode rows)
            sectionLabel("Select Mode")
                .padding(.top, 4)

            // Available game modes
            VStack(spacing: 14) {
                ForEach(GameMode.allCases, id: \.self) { gameMode in
                    basicModeRow(level: selectedLevel, gameMode: gameMode)
                }

                // Coming soon placeholders
                comingSoonRow(title: "Listening Mode", description: "Match by listening to pronunciation", icon: "ear.fill")
                comingSoonRow(title: "Spelling Mode", description: "Type the correct spelling", icon: "keyboard.fill")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(FontStyles.bodyMedium)
                .fontWeight(.semibold)
                .foregroundStyle(ColorPalette.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func comingSoonRow(title: String, description: String, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(ColorPalette.textTertiary)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(FontStyles.bodyLarge)
                    .foregroundStyle(ColorPalette.textTertiary)
                Text(description)
                    .font(FontStyles.caption)
                    .foregroundStyle(ColorPalette.textTertiary)
            }

            Spacer()

            Text("Coming Soon")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(ColorPalette.slate))
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .softCard()
        .opacity(0.6)
    }

    private func basicModeRow(level: CEFRLevel, gameMode: GameMode) -> some View {
        let best = basicBest(level: level, mode: gameMode)
        let stage = Stage.stage(level: level, mode: gameMode)

        return Button {
            HapticManager.shared.cardTap()
            SoundManager.shared.playSelect()
            selectedStage = stage
        } label: {
            HStack(spacing: 14) {
                Image(systemName: gameMode.icon)
                    .font(.title2)
                    .foregroundStyle(level.color)
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(gameMode.displayName)
                        .font(FontStyles.bodyLarge)
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text(gameMode.description)
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    bestText(for: gameMode, session: best)
                    Text("Best")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .padding(.trailing, 6)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(.vertical, 22)
            .padding(.horizontal, 18)
            .softCard()
        }
        .buttonStyle(LiquidPressStyle())
    }

    @ViewBuilder
    private func bestText(for mode: GameMode, session: GameSession?) -> some View {
        switch mode {
        case .maxCorrect:
            Text("\(session?.correctPairs ?? 0)")
                .font(FontStyles.titleSmall)
                .foregroundStyle((session?.correctPairs ?? 0) > 0 ? ColorPalette.streakGold : ColorPalette.textTertiary)
        case .timeAttack:
            if let s = session {
                Text(String(format: "%.1fs", s.elapsedSeconds))
                    .font(FontStyles.titleSmall)
                    .foregroundStyle(ColorPalette.streakGold)
            } else {
                Text("0.0s")
                    .font(FontStyles.titleSmall)
                    .foregroundStyle(ColorPalette.textTertiary)
            }
        }
    }

    // MARK: - Level Components

    private func levelChip(_ level: CEFRLevel) -> some View {
        Button {
            HapticManager.shared.cardTap()
            SoundManager.shared.playSelect()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                selectedLevel = level
            }
        } label: {
            Text(level.displayName)
                .font(FontStyles.titleSmall)
                .foregroundStyle(selectedLevel == level ? .white : ColorPalette.textSecondary)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(selectedLevel == level ? level.color : ColorPalette.backgroundCard)
                        .shadow(color: selectedLevel == level ? level.color.opacity(0.3) : .clear, radius: 8, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(selectedLevel == level ? .clear : ColorPalette.liquidBorderColor, lineWidth: 1)
                )
        }
        .buttonStyle(LiquidPressStyle())
    }
}
