import Foundation
import SwiftData

@Model
final class WrongAnswer {
    var id: UUID
    var sessionId: UUID
    var dictionaryEntryId: Int64
    var headword: String = ""
    var firstMeaning: String = ""
    var allMeanings: String = ""     // newline-separated
    var pos: String = ""
    var cefrLevel: String = "A1"
    var ipa: String = ""
    var topic: String = ""
    var exampleEn: String = ""
    var exampleJa: String = ""
    var masteredAt: Date?
    var createdAt: Date

    var isMastered: Bool { masteredAt != nil }

    var meaningsList: [String] {
        allMeanings.split(separator: "\n").map(String.init)
    }

    init(sessionId: UUID, entry: DictionaryEntry) {
        self.id = UUID()
        self.sessionId = sessionId
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
        self.masteredAt = nil
        self.createdAt = Date()
    }
}
