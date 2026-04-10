import Foundation
import SwiftData

@MainActor
final class GameHistoryStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveSession(_ session: GameSession) {
        modelContext.insert(session)
        try? modelContext.save()
    }

    func saveWrongAnswer(_ wrongAnswer: WrongAnswer) {
        modelContext.insert(wrongAnswer)
        try? modelContext.save()
    }

    func fetchSessions(limit: Int = 50) -> [GameSession] {
        var d = FetchDescriptor<GameSession>(
            sortBy: [SortDescriptor(\GameSession.playedAt, order: .reverse)]
        )
        d.fetchLimit = limit
        return (try? modelContext.fetch(d)) ?? []
    }

    // MARK: - Wrong Answers

    func fetchWrongAnswers(masteredOnly: Bool = false, unmasteredOnly: Bool = false, level: String? = nil) -> [WrongAnswer] {
        var d = FetchDescriptor<WrongAnswer>(
            sortBy: [SortDescriptor(\WrongAnswer.headword)]
        )
        if let lvl = level {
            if unmasteredOnly {
                d.predicate = #Predicate<WrongAnswer> { $0.cefrLevel == lvl && $0.masteredAt == nil }
            } else if masteredOnly {
                d.predicate = #Predicate<WrongAnswer> { $0.cefrLevel == lvl && $0.masteredAt != nil }
            } else {
                d.predicate = #Predicate<WrongAnswer> { $0.cefrLevel == lvl }
            }
        } else {
            if unmasteredOnly {
                d.predicate = #Predicate<WrongAnswer> { $0.masteredAt == nil }
            } else if masteredOnly {
                d.predicate = #Predicate<WrongAnswer> { $0.masteredAt != nil }
            }
        }
        return (try? modelContext.fetch(d)) ?? []
    }

    func toggleMastered(_ answer: WrongAnswer) {
        answer.masteredAt = answer.isMastered ? nil : Date()
        try? modelContext.save()
    }

    func unmasteredCount() -> Int {
        let d = FetchDescriptor<WrongAnswer>(
            predicate: #Predicate<WrongAnswer> { $0.masteredAt == nil }
        )
        return (try? modelContext.fetchCount(d)) ?? 0
    }

    // MARK: - Category Best (time-attack: lower elapsed time = better, must be completed)

    func categoryBest(topic: String, rank: String) -> GameSession? {
        var d = FetchDescriptor<GameSession>(
            predicate: #Predicate<GameSession> {
                $0.topic == topic && $0.categoryRank == rank && $0.isCompleted
            },
            sortBy: [SortDescriptor(\GameSession.elapsedSeconds, order: .forward)]
        )
        d.fetchLimit = 1
        return (try? modelContext.fetch(d))?.first
    }

    // MARK: - High Score

    func highScore(level: CEFRLevel, stageNumber: Int? = nil) -> Int {
        let levelStr = level.rawValue
        if let stageNum = stageNumber {
            var d = FetchDescriptor<GameSession>(
                predicate: #Predicate<GameSession> { $0.cefrLevel == levelStr && $0.stageNumber == stageNum },
                sortBy: [SortDescriptor(\GameSession.score, order: .reverse)]
            )
            d.fetchLimit = 1
            return (try? modelContext.fetch(d))?.first?.score ?? 0
        } else {
            var d = FetchDescriptor<GameSession>(
                predicate: #Predicate<GameSession> { $0.cefrLevel == levelStr },
                sortBy: [SortDescriptor(\GameSession.score, order: .reverse)]
            )
            d.fetchLimit = 1
            return (try? modelContext.fetch(d))?.first?.score ?? 0
        }
    }

    // MARK: - Word Records

    /// Record a correct answer.
    /// - If the user has never had a wrong answer for this word, mark it as mastered.
    /// - If they had wrong answers before but got it right this time, keep it in Wrong list (lastAttemptWrong=false but wrongCount > 0).
    func recordCorrect(entry: DictionaryEntry) {
        let record = findOrCreateRecord(entry: entry)
        record.correctCount += 1
        record.lastSeenAt = Date()
        record.lastAttemptWrong = false
        // Auto-master if no past wrong answers
        if record.wrongCount == 0 && record.masteredAt == nil {
            record.masteredAt = Date()
        }
        try? modelContext.save()
    }

    func recordWrong(entry: DictionaryEntry) {
        let record = findOrCreateRecord(entry: entry)
        record.wrongCount += 1
        record.lastSeenAt = Date()
        record.lastAttemptWrong = true
        // If previously mastered, demote
        record.masteredAt = nil
        try? modelContext.save()
    }

    func toggleWordMastered(_ record: WordRecord) {
        record.masteredAt = record.isMastered ? nil : Date()
        try? modelContext.save()
    }

    /// Fetch word records with filter.
    /// - mode: .wrong = unmastered (had at least one wrong), .mastered = mastered, .all = all played
    func fetchWordRecords(mode: ReviewFilterMode = .all, level: String? = nil) -> [WordRecord] {
        var d = FetchDescriptor<WordRecord>(
            sortBy: [SortDescriptor(\WordRecord.headword)]
        )
        if let lvl = level {
            switch mode {
            case .wrong:
                d.predicate = #Predicate<WordRecord> { $0.cefrLevel == lvl && $0.masteredAt == nil }
            case .mastered:
                d.predicate = #Predicate<WordRecord> { $0.cefrLevel == lvl && $0.masteredAt != nil }
            case .all:
                d.predicate = #Predicate<WordRecord> { $0.cefrLevel == lvl }
            }
        } else {
            switch mode {
            case .wrong:
                d.predicate = #Predicate<WordRecord> { $0.masteredAt == nil }
            case .mastered:
                d.predicate = #Predicate<WordRecord> { $0.masteredAt != nil }
            case .all:
                break
            }
        }
        return (try? modelContext.fetch(d)) ?? []
    }

    func unmasteredWrongCount() -> Int {
        let d = FetchDescriptor<WordRecord>(
            predicate: #Predicate<WordRecord> { $0.masteredAt == nil }
        )
        return (try? modelContext.fetchCount(d)) ?? 0
    }

    func wordRecordCounts(level: String? = nil) -> (wrong: Int, mastered: Int, total: Int) {
        let all = fetchWordRecords(mode: .all, level: level)
        let mastered = all.filter { $0.isMastered }.count
        let wrong = all.count - mastered
        return (wrong, mastered, all.count)
    }

    private func findOrCreateRecord(entry: DictionaryEntry) -> WordRecord {
        let entryId = entry.id
        let d = FetchDescriptor<WordRecord>(
            predicate: #Predicate<WordRecord> { $0.dictionaryEntryId == entryId }
        )
        if let existing = (try? modelContext.fetch(d))?.first {
            return existing
        }
        let record = WordRecord(entry: entry)
        modelContext.insert(record)
        return record
    }

    func clearAllHistory() {
        try? modelContext.delete(model: GameSession.self)
        try? modelContext.delete(model: WrongAnswer.self)
        try? modelContext.delete(model: WordRecord.self)
        try? modelContext.save()
    }
}

enum ReviewFilterMode {
    case wrong
    case mastered
    case all
}
