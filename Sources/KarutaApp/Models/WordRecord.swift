import Foundation
import SwiftData

/// Tracks per-word stats: correct/wrong counts, mastery status
@Model
final class WordRecord {
    var id: UUID = UUID()
    var dictionaryEntryId: Int64 = 0
    var headword: String = ""
    var firstMeaning: String = ""
    var allMeanings: String = ""
    var pos: String = ""
    var cefrLevel: String = "A1"
    var ipa: String = ""
    var topic: String = ""
    var exampleEn: String = ""
    var exampleJa: String = ""
    var correctCount: Int = 0
    var wrongCount: Int = 0
    var masteredAt: Date?
    var lastSeenAt: Date = Date()
    /// Was the most recent attempt wrong? Used to distinguish "Wrong" vs "Mastered" lists.
    var lastAttemptWrong: Bool = false

    var isMastered: Bool { masteredAt != nil }
    var totalAttempts: Int { correctCount + wrongCount }
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempts)
    }

    var meaningsList: [String] {
        allMeanings.split(separator: "\n").map(String.init)
    }

    init(entry: DictionaryEntry) {
        self.dictionaryEntryId = entry.id
        self.headword = entry.headword
        self.firstMeaning = entry.firstMeaning
        self.allMeanings = entry.allMeanings.joined(separator: "\n")
        self.pos = entry.pos
        self.cefrLevel = entry.cefrLevel.rawValue
        self.ipa = entry.ipa ?? ""
        self.topic = entry.topic ?? ""
        self.exampleEn = entry.exampleEn ?? ""
        self.exampleJa = entry.exampleJa ?? ""
    }
}
