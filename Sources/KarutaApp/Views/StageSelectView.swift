import SwiftUI
import SwiftData

struct StageSelectView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedLevel: CEFRLevel = .a1
    @State private var selectedStage: Stage?
    @State private var mode: PlayMode = .level

    // Category mode state
    @State private var selectedRank: CategoryRank = .a
    @State private var pendingTopic: String?
    @State private var pendingRank: CategoryRank?

    private let dictionaryService = DictionaryService.shared

    enum PlayMode: String, CaseIterable {
        case level = "Level"
        case topic = "Category"
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 16) {
                Picker("Mode", selection: $mode) {
                    ForEach(PlayMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)

                if mode == .level {
                    levelModeContent
                } else {
                    topicModeContent
                }
            }
            .padding(.top, 8)
        }
        .navigationTitle("Select Level")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedStage) { stage in
            GameView(viewModel: GameViewModel(
                stage: stage,
                dictionaryService: dictionaryService,
                historyStore: GameHistoryStore(modelContext: modelContext),
                topic: pendingTopic,
                categoryRank: pendingRank
            ))
        }
    }

    // MARK: - Level Mode

    private var levelModeContent: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CEFRLevel.allCases) { level in
                        levelChip(level)
                    }
                }
                .padding(.horizontal, 20)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Stage.stages(for: selectedLevel)) { stage in
                        subLevelRow(stage)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Topic/Category Mode

    private var topicModeContent: some View {
        VStack(spacing: 16) {
            // Rank picker
            HStack(spacing: 10) {
                ForEach(CategoryRank.allCases) { rank in
                    rankChip(rank)
                }
            }
            .padding(.horizontal, 20)

            // Topic list filtered by rank
            ScrollView {
                LazyVStack(spacing: 10) {
                    let topics = dictionaryService.allTopics()
                    let mainTopics = uniqueMainTopics(from: topics)
                    ForEach(mainTopics, id: \.self) { topic in
                        let count = dictionaryService.topicWordCount(topic: topic, levels: selectedRank.cefrLevels)
                        if count >= 15 {
                            topicRow(topic: topic, wordCount: count)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func uniqueMainTopics(from raw: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for r in raw {
            for part in r.components(separatedBy: ";") {
                let t = part.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty && !seen.contains(t) {
                    seen.insert(t)
                    result.append(t)
                }
            }
        }
        return result.sorted()
    }

    private func rankChip(_ rank: CategoryRank) -> some View {
        Button {
            HapticManager.shared.cardTap()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                selectedRank = rank
            }
        } label: {
            VStack(spacing: 3) {
                Text(rank.displayName)
                    .font(FontStyles.titleSmall)
                Text(rank.description)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
            }
            .foregroundStyle(selectedRank == rank ? .white : ColorPalette.textSecondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(selectedRank == rank ? ColorPalette.accentPrimary : ColorPalette.backgroundCard)
                    .shadow(color: selectedRank == rank ? ColorPalette.accentPrimary.opacity(0.3) : .clear, radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selectedRank == rank ? .clear : ColorPalette.liquidBorderColor, lineWidth: 1)
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LiquidPressStyle())
    }

    private func topicRow(topic: String, wordCount: Int) -> some View {
        let store = GameHistoryStore(modelContext: modelContext)
        let best = store.categoryBest(topic: topic, rank: selectedRank.rawValue)

        return Button {
            HapticManager.shared.cardTap()
            pendingTopic = topic
            pendingRank = selectedRank
            selectedStage = Stage.categoryStage(rank: selectedRank)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic)
                        .font(FontStyles.bodyLarge)
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text("\(wordCount) words • 15 pairs")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if let best = best {
                        Text(String(format: "%.1fs", best.elapsedSeconds))
                            .font(FontStyles.titleSmall)
                            .foregroundStyle(ColorPalette.streakGold)
                    } else {
                        Text("0.0s")
                            .font(FontStyles.titleSmall)
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                    Text("Best")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .padding(.trailing, 6)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .softCard()
        }
        .buttonStyle(LiquidPressStyle())
    }

    // MARK: - Level Components

    private func levelChip(_ level: CEFRLevel) -> some View {
        Button {
            HapticManager.shared.cardTap()
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

    private func subLevelRow(_ stage: Stage) -> some View {
        let store = GameHistoryStore(modelContext: modelContext)
        let highScore = store.highScore(level: stage.level, stageNumber: stage.subLevel)

        return Button {
            HapticManager.shared.cardTap()
            pendingTopic = nil
            pendingRank = nil
            selectedStage = stage
        } label: {
            HStack(spacing: 0) {
                Text("\(stage.subLevel)")
                    .font(FontStyles.titleMedium)
                    .foregroundStyle(stage.level.color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(stage.level.rawValue) - Level \(stage.subLevel)")
                        .font(FontStyles.bodyMedium)
                        .foregroundStyle(ColorPalette.textPrimary)
                    HStack(spacing: 12) {
                        Label("\(stage.totalPairs) pairs", systemImage: "square.grid.2x2")
                        Label("\(Int(stage.timeLimitSeconds))s", systemImage: "timer")
                    }
                    .font(FontStyles.caption)
                    .foregroundStyle(ColorPalette.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(highScore)")
                        .font(FontStyles.titleSmall)
                        .foregroundStyle(highScore > 0 ? ColorPalette.streakGold : ColorPalette.textTertiary)
                    Text("Best")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .padding(.trailing, 8)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .softCard()
        }
        .buttonStyle(LiquidPressStyle())
    }
}
