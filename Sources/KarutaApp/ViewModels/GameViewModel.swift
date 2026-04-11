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
    /// ID of the saved session for this play (used for "is new record" lookup)
    var lastSessionId: UUID?
    /// Final elapsed seconds at game end (matches the value saved to DB)
    var finalElapsedSeconds: Double = 0

    /// Track entries already counted as wrong in this session (avoid double-counting on repeat misses)
    private var wronglyAttemptedInSession: Set<Int64> = []
    /// Cancellation flag set when stopGame() is called - blocks further sound/haptic
    private var gameCancelled = false
    /// Pending debounced refill task — restarts on every new match so consecutive
    /// matches accumulate before a single batched refill happens.
    private var refillTask: Task<Void, Never>?
    /// Earliest deadline by which the refill MUST happen, even if more matches keep coming.
    /// Set the first time a match occurs while no refill is pending. Cleared after refill.
    private var refillDeadline: Date?

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
        refillDeadline = nil
        finalElapsedSeconds = 0
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
        refillTask?.cancel()
        refillTask = nil
        soundManager.stopAllSE()
    }

    /// Internal stop (used when game finishes naturally).
    func stopGame() {
        timerTask?.cancel()
        timerTask = nil
        refillTask?.cancel()
        refillTask = nil
        soundManager.stopCountdown()
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

        // Reset to nil first so SwiftUI recreates the popup view (re-triggers onAppear animation)
        scorePopup = nil
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

        // Time-attack mode: stage clear when target pairs reached
        if stage.mode == .timeAttack && pairsCompleted >= stage.totalPairs {
            // Capture elapsed time AT THE MOMENT OF COMPLETION (not after delay)
            let elapsedAtCompletion = startTime.map { Date().timeIntervalSince($0) } ?? 0
            finalElapsedSeconds = elapsedAtCompletion

            // Slight delay so the matched fade is visible before result
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                if gameCancelled { return }
                phase = .completed
                stopGame()
                soundManager.playGameOver()
                hapticManager.gameComplete()
                saveResultWithFixedElapsed(elapsedAtCompletion, completed: true)
            }
            return
        }

        // Debounced refill with a max deadline.
        // - Each new match resets the wait to 1.1s
        // - But the refill MUST happen within 1.8s of the first pending match
        let now = Date()
        let debounceMs: Int = 1100
        let maxWaitMs: Int = 1800
        if refillDeadline == nil {
            refillDeadline = now.addingTimeInterval(Double(maxWaitMs) / 1000.0)
        }
        let deadline = refillDeadline ?? now.addingTimeInterval(Double(maxWaitMs) / 1000.0)
        let untilDeadlineMs = max(0, Int(deadline.timeIntervalSince(now) * 1000))
        let waitMs = min(debounceMs, untilDeadlineMs)

        refillTask?.cancel()
        refillTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(waitMs))
            if Task.isCancelled || gameCancelled { return }
            refillDeadline = nil
            refillNextCard()
        }
    }

    /// Refill ALL currently matched slots at once with new entries.
    /// When multiple slots are matched simultaneously, english and japanese
    /// mappings are shuffled independently so the pair order is scrambled.
    private func refillNextCard() {
        let engMatchedIndices = englishCards.indices.filter { englishCards[$0].state == .matched }
        let jpnMatchedIndices = japaneseCards.indices.filter { japaneseCards[$0].state == .matched }
        let count = min(engMatchedIndices.count, jpnMatchedIndices.count)
        guard count > 0 else { return }
        guard queueIndex + count <= wordQueue.count else {
            // Not enough remaining entries — fall back to partial refill
            let remain = wordQueue.count - queueIndex
            if remain <= 0 { return }
            refillSingleBatch(entryCount: remain, engSlots: engMatchedIndices, jpnSlots: jpnMatchedIndices)
            return
        }
        refillSingleBatch(entryCount: count, engSlots: engMatchedIndices, jpnSlots: jpnMatchedIndices)
    }

    private func refillSingleBatch(entryCount: Int, engSlots: [Int], jpnSlots: [Int]) {
        let entries = (0..<entryCount).map { i -> DictionaryEntry in
            let e = wordQueue[queueIndex + i]
            return e
        }
        queueIndex += entryCount

        // Shuffle independently so row position doesn't correlate between columns
        let engOrder = Array(engSlots.prefix(entryCount)).shuffled()
        let jpnOrder = Array(jpnSlots.prefix(entryCount)).shuffled()

        for i in 0..<entryCount {
            let entry = entries[i]
            let engIdx = engOrder[i]
            let jpnIdx = jpnOrder[i]
            englishCards[engIdx] = GameCard(entryId: entry.id, displayText: entry.headword, column: .english)
            japaneseCards[jpnIdx] = GameCard(entryId: entry.id, displayText: entry.firstMeaning, column: .japanese)
        }
    }

    private func handleWrongMatch(eng: GameCard, jpn: GameCard) {
        streak = 0
        wrongCount += 1

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
        let count = min(stage.visiblePairs, wordQueue.count)
        guard count > 0 else {
            englishCards = []
            japaneseCards = []
            return
        }

        // Initial set: all 5 pairs present, each column independently shuffled.
        let entries = Array(wordQueue.prefix(count))
        queueIndex = count

        let engCards: [GameCard] = entries.map {
            GameCard(entryId: $0.id, displayText: $0.headword, column: .english)
        }
        let jpnCards: [GameCard] = entries.map {
            GameCard(entryId: $0.id, displayText: $0.firstMeaning, column: .japanese)
        }

        englishCards = engCards.shuffled()
        japaneseCards = jpnCards.shuffled()
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
        var countdownStarted = false
        timerTask = Task { @MainActor in
            while !Task.isCancelled && !gameCancelled && timeRemaining > 0 {
                try? await Task.sleep(for: .milliseconds(50))
                if Task.isCancelled || gameCancelled { return }
                timeRemaining -= 0.05

                // Play countdown sound ONCE when entering the warning threshold
                if !countdownStarted && timeRemaining <= GameConstants.timerWarningThreshold {
                    countdownStarted = true
                    soundManager.playCountdown()
                }

                // Light haptic tick each second during warning period
                if timeRemaining <= GameConstants.timerWarningThreshold &&
                    timeRemaining.truncatingRemainder(dividingBy: 1.0) < 0.06 {
                    hapticManager.countdownTick()
                }

                if timeRemaining <= 0 {
                    timeRemaining = 0
                    if gameCancelled { return }
                    // Stop countdown sound immediately at zero
                    soundManager.stopCountdown()
                    // For max-correct mode, time up = natural completion
                    let isCompleted = (stage.mode == .maxCorrect)
                    phase = isCompleted ? .completed : .timeUp
                    soundManager.playGameOver()
                    hapticManager.gameComplete()
                    saveResult(completed: isCompleted)
                    return
                }
            }
        }
    }

    // MARK: - Persistence

    private func saveResult(completed: Bool) {
        let elapsed = startTime.map { Date().timeIntervalSince($0) } ?? timeLimit
        finalElapsedSeconds = elapsed
        saveSessionInternal(elapsed: elapsed, completed: completed)
    }

    /// Save with an externally-fixed elapsed time (used by time-attack completion to
    /// avoid the 300ms post-match delay being counted in the score).
    private func saveResultWithFixedElapsed(_ elapsed: Double, completed: Bool) {
        finalElapsedSeconds = elapsed
        saveSessionInternal(elapsed: elapsed, completed: completed)
    }

    private func saveSessionInternal(elapsed: Double, completed: Bool) {
        let session = GameSession(
            cefrLevel: stage.level,
            stageNumber: 0,
            score: score,
            totalPairs: stage.totalPairs,
            correctPairs: correctCount,
            wrongAttempts: wrongCount,
            maxStreak: maxStreak,
            elapsedSeconds: elapsed,
            timeLimitSeconds: timeLimit,
            isCompleted: completed,
            topic: topic,
            categoryRank: categoryRank?.rawValue,
            gameMode: stage.mode.rawValue
        )
        lastSessionId = session.id
        historyStore.saveSession(session)
    }
}

struct ScorePopupInfo: Identifiable {
    let id = UUID()
    let points: Int
    let streak: Int
}
