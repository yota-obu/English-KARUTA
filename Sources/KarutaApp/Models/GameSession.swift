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
    /// Category mode: topic name (nil for basic mode)
    var topic: String? = nil
    /// Category mode: rank "A"/"B" (nil for basic mode)
    var categoryRank: String? = nil
    /// Game mode: "max_correct" or "time_attack"
    var gameMode: String = "time_attack"

    var accuracy: Double {
        let total = correctPairs + wrongAttempts
        guard total > 0 else { return 0 }
        return Double(correctPairs) / Double(total)
    }

    var level: CEFRLevel? {
        CEFRLevel(rawValue: cefrLevel)
    }

    var modeDisplay: String {
        if let topic = topic {
            return "\(topic)"
        }
        switch gameMode {
        case "max_correct": return "1 min"
        case "time_attack": return "15 pairs"
        default: return ""
        }
    }

    init(cefrLevel: CEFRLevel, stageNumber: Int, score: Int, totalPairs: Int,
         correctPairs: Int, wrongAttempts: Int, maxStreak: Int,
         elapsedSeconds: Double, timeLimitSeconds: Double, isCompleted: Bool,
         topic: String? = nil, categoryRank: String? = nil, gameMode: String = "time_attack") {
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
        self.gameMode = gameMode
    }
}
