import SwiftUI
import Observation

@Observable
@MainActor
final class GameViewModel {

    enum GamePhase: Sendable {
        case loading
        case countdown
        case playing
        case completed
        case timeUp
        case error(String)

        var isCompleted: Bool {
            if case .completed = self { return true }
            return false
        }
    }

    // MARK: - State
    var phase: GamePhase = .loading
    var countdownValue: Int = GameConstants.countdownSeconds

    var englishCards: [GameCard] = []
    var japaneseCards: [GameCard] = []
    var selectedEnglishCard: GameCard?
    var selectedJapaneseCard: GameCard?

    var timeRemaining: Double = 0
    var timeLimit: Double = 0
    var timerProgress: Double { timeLimit > 0 ? timeRemaining / timeLimit : 1.0 }

    var score: Int = 0
    var streak: Int = 0
    var maxStreak: Int = 0
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var pairsCompleted: Int = 0

    var scorePopup: ScorePopupInfo?

    let stage: Stage
    let topic: String?  // nil = level mode, non-nil = topic mode
    let categoryRank: CategoryRank?  // for topic mode with rank filter

    // MARK: - Private
    private var wordQueue: [DictionaryEntry] = []
    private var queueIndex: Int = 0
    var timerTask: Task<Void, Never>?

    private let dictionaryService: DictionaryService
    private let historyStore: GameHistoryStore
    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared

    private var sessionId: UUID = UUID()
    private var startTime: Date?

    /// Track entries already counted as wrong in this session (avoid double-counting on repeat misses)
    private var wronglyAttemptedInSession: Set<Int64> = []
    /// Cancellation flag set when stopGame() is called - blocks further sound/haptic
    private var gameCancelled = false

    init(stage: Stage, dictionaryService: DictionaryService, historyStore: GameHistoryStore, topic: String? = nil, categoryRank: CategoryRank? = nil) {
        self.stage = stage
        self.topic = topic
        self.categoryRank = categoryRank
        self.dictionaryService = dictionaryService
        self.historyStore = historyStore
        self.timeLimit = stage.timeLimitSeconds
        self.timeRemaining = stage.timeLimitSeconds
    }

    // MARK: - Game Flow

    func startGame() async {
        gameCancelled = false
        wronglyAttemptedInSession = []
        phase = .loading
        hapticManager.prepare()

        let words: [DictionaryEntry]
        if let topic = topic, let rank = categoryRank {
            words = dictionaryService.fetchWordsByTopic(topic: topic, levels: rank.cefrLevels, count: stage.totalPairs)
        } else if let topic = topic {
            words = dictionaryService.fetchWordsByTopic(topic: topic, count: stage.totalPairs)
        } else {
            words = dictionaryService.fetchWords(level: stage.level, count: stage.totalPairs)
        }

        print("[GameVM] fetched \(words.count) words")

        guard words.count >= stage.visiblePairs else {
            print("[GameVM] ERROR: not enough words (\(words.count) < \(stage.visiblePairs))")
            phase = .error("Not enough words for level \(stage.level.rawValue)")
            return
        }

        wordQueue = words.shuffled()
        queueIndex = 0
        sessionId = UUID()

        fillInitialCards()

        print("[GameVM] cards filled: eng=\(englishCards.count), jpn=\(japaneseCards.count)")

        // Countdown
        phase = .countdown
        for i in (1...GameConstants.countdownSeconds).reversed() {
            countdownValue = i
            hapticManager.countdownTick()
            try? await Task.sleep(for: .seconds(1))
        }

        phase = .playing
        startTime = Date()
        startTimer()
    }

    func selectCard(_ card: GameCard, column: CardColumn) {
        guard case .playing = phase else { return }
        hapticManager.cardTap()

        switch column {
        case .english:
            if selectedEnglishCard?.id == card.id {
                deselectCard(card, in: &englishCards)
                selectedEnglishCard = nil
                return
            }
            if let prev = selectedEnglishCard {
                deselectCard(prev, in: &englishCards)
            }
            selectCardInList(card, in: &englishCards)
            selectedEnglishCard = card

        case .japanese:
            if selectedJapaneseCard?.id == card.id {
                deselectCard(card, in: &japaneseCards)
                selectedJapaneseCard = nil
                return
            }
            if let prev = selectedJapaneseCard {
                deselectCard(prev, in: &japaneseCards)
            }
            selectCardInList(card, in: &japaneseCards)
            selectedJapaneseCard = card
        }

        if selectedEnglishCard != nil && selectedJapaneseCard != nil {
            checkMatch()
        }
    }

    /// Cancel the game completely (called when user dismisses with X button).
    /// Stops timer, prevents further sounds/haptics, and does NOT save a session.
    func cancelGame() {
        gameCancelled = true
        timerTask?.cancel()
        timerTask = nil
    }

    /// Internal stop (used when game finishes naturally).
    func stopGame() {
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Match Logic

    private func checkMatch() {
        guard let eng = selectedEnglishCard, let jpn = selectedJapaneseCard else { return }

        if eng.entryId == jpn.entryId {
            handleCorrectMatch(eng: eng, jpn: jpn)
        } else {
            handleWrongMatch(eng: eng, jpn: jpn)
        }

        selectedEnglishCard = nil
        selectedJapaneseCard = nil
    }

    private func handleCorrectMatch(eng: GameCard, jpn: GameCard) {
        streak += 1
        maxStreak = max(maxStreak, streak)
        correctCount += 1
        pairsCompleted += 1

        let points = GameConstants.Scoring.calculate(
            streak: streak,
            timeRemaining: timeRemaining,
            timeLimit: timeLimit
        )
        score += points

        scorePopup = ScorePopupInfo(points: points, streak: streak)

        setCardState(eng, state: .matched, in: &englishCards)
        setCardState(jpn, state: .matched, in: &japaneseCards)

        soundManager.playCorrect()
        hapticManager.correctMatch()

        // Record correct answer
        if let entry = dictionaryService.fetchEntry(id: eng.entryId) {
            historyStore.recordCorrect(entry: entry)
        }

        if streak > 0 && streak % GameConstants.streakMilestone == 0 {
            soundManager.playCombo()
            hapticManager.streakMilestone()
        }

        Task { @MainActor in
            // Cards stay as .matched (invisible via opacity) for 0.3s
            try? await Task.sleep(for: .milliseconds(300))
            if gameCancelled { return }

            if pairsCompleted >= stage.totalPairs {
                phase = .completed
                stopGame()
                soundManager.playGameOver()
                hapticManager.gameComplete()
                saveResult(completed: true)
                return
            }

            // Wait before replacing with new card in same slot
            try? await Task.sleep(for: .milliseconds(600))
            if gameCancelled { return }
            // Pull ONE entry and use it for both columns to keep them paired
            if queueIndex < wordQueue.count {
                let entry = wordQueue[queueIndex]
                queueIndex += 1
                replaceMatchedSlot(in: &englishCards, with: entry, column: .english)
                replaceMatchedSlot(in: &japaneseCards, with: entry, column: .japanese)
            }
        }
    }

    private func handleWrongMatch(eng: GameCard, jpn: GameCard) {
        streak = 0
        wrongCount += 1
        timeRemaining = max(0, timeRemaining - GameConstants.timePenalty)

        setCardState(eng, state: .wrong, in: &englishCards)
        setCardState(jpn, state: .wrong, in: &japaneseCards)

        soundManager.playWrong()
        hapticManager.wrongMatch()

        // Record wrong answer (only first time per session for each word)
        if !wronglyAttemptedInSession.contains(eng.entryId) {
            wronglyAttemptedInSession.insert(eng.entryId)
            if let entry = dictionaryService.fetchEntry(id: eng.entryId) {
                historyStore.recordWrong(entry: entry)
            }
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            if gameCancelled { return }
            setCardState(eng, state: .idle, in: &englishCards)
            setCardState(jpn, state: .idle, in: &japaneseCards)
        }
    }

    // MARK: - Card Management

    private func fillInitialCards() {
        englishCards = []
        japaneseCards = []

        let count = min(stage.visiblePairs, wordQueue.count)
        var engCards: [GameCard] = []
        var jpnCards: [GameCard] = []

        for i in 0..<count {
            let entry = wordQueue[i]
            engCards.append(GameCard(entryId: entry.id, displayText: entry.headword, column: .english))
            jpnCards.append(GameCard(entryId: entry.id, displayText: entry.firstMeaning, column: .japanese))
        }
        queueIndex = count

        englishCards = engCards.shuffled()
        japaneseCards = jpnCards.shuffled()
    }

    /// Replace the first .matched card in a column with a new word (same position).
    /// The entry is provided externally so both columns receive a properly paired entry.
    private func replaceMatchedSlot(in cards: inout [GameCard], with entry: DictionaryEntry, column: CardColumn) {
        guard let idx = cards.firstIndex(where: { $0.state == .matched }) else { return }
        let displayText = column == .english ? entry.headword : entry.firstMeaning
        let newCard = GameCard(entryId: entry.id, displayText: displayText, column: column)
        withAnimation(.spring(response: GameConstants.springResponse, dampingFraction: GameConstants.springDamping)) {
            cards[idx] = newCard
        }
    }

    private func selectCardInList(_ card: GameCard, in cards: inout [GameCard]) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].state = .selected
        }
    }

    private func deselectCard(_ card: GameCard, in cards: inout [GameCard]) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].state = .idle
        }
    }

    private func setCardState(_ card: GameCard, state: GameCard.CardState, in cards: inout [GameCard]) {
        if let idx = cards.firstIndex(where: { $0.id == card.id }) {
            cards[idx].state = state
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerTask = Task { @MainActor in
            while !Task.isCancelled && !gameCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled || gameCancelled { return }
                timeRemaining -= 0.05

                if timeRemaining <= GameConstants.timerWarningThreshold &&
                    timeRemaining.truncatingRemainder(dividingBy: 1.0) < 0.06 {
                    soundManager.playCountdown()
                    hapticManager.countdownTick()
                }

                if timeRemaining <= 0 {
                    timeRemaining = 0
                    if gameCancelled { return }
                    phase = .timeUp
                    soundManager.playGameOver()
                    hapticManager.gameComplete()
                    saveResult(completed: false)
                    return
                }
            }
        }
    }

    // MARK: - Persistence

    private func saveResult(completed: Bool) {
        let elapsed = startTime.map { Date().timeIntervalSince($0) } ?? timeLimit
        let session = GameSession(
            cefrLevel: stage.level,
            stageNumber: stage.subLevel,
            score: score,
            totalPairs: stage.totalPairs,
            correctPairs: correctCount,
            wrongAttempts: wrongCount,
            maxStreak: maxStreak,
            elapsedSeconds: elapsed,
            timeLimitSeconds: timeLimit,
            isCompleted: completed,
            topic: topic,
            categoryRank: categoryRank?.rawValue
        )
        historyStore.saveSession(session)
    }
}

struct ScorePopupInfo: Identifiable {
    let id = UUID()
    let points: Int
    let streak: Int
}
