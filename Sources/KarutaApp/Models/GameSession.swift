import Foundation
import SwiftData

@Model
final class GameSession {
    var id: UUID
    var cefrLevel: String
    var stageNumber: Int
    var score: Int
    var totalPairs: Int
    var correctPairs: Int
    var wrongAttempts: Int
    var maxStreak: Int
    var elapsedSeconds: Double
    var timeLimitSeconds: Double
    var playedAt: Date
    var isCompleted: Bool
    /// Category mode: topic name (nil for level mode)
    var topic: String? = nil
    /// Category mode: rank "A"/"B"/"C" (nil for level mode)
    var categoryRank: String? = nil

    var accuracy: Double {
        let total = correctPairs + wrongAttempts
        guard total > 0 else { return 0 }
        return Double(correctPairs) / Double(total)
    }

    var level: CEFRLevel? {
        CEFRLevel(rawValue: cefrLevel)
    }

    init(cefrLevel: CEFRLevel, stageNumber: Int, score: Int, totalPairs: Int,
         correctPairs: Int, wrongAttempts: Int, maxStreak: Int,
         elapsedSeconds: Double, timeLimitSeconds: Double, isCompleted: Bool,
         topic: String? = nil, categoryRank: String? = nil) {
        self.id = UUID()
        self.cefrLevel = cefrLevel.rawValue
        self.stageNumber = stageNumber
        self.score = score
        self.totalPairs = totalPairs
        self.correctPairs = correctPairs
        self.wrongAttempts = wrongAttempts
        self.maxStreak = maxStreak
        self.elapsedSeconds = elapsedSeconds
        self.timeLimitSeconds = timeLimitSeconds
        self.playedAt = Date()
        self.isCompleted = isCompleted
        self.topic = topic
        self.categoryRank = categoryRank
    }
}
