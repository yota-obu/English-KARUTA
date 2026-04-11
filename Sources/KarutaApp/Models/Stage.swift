import Foundation

/// Game mode types
enum GameMode: String, CaseIterable, Sendable {
    case maxCorrect = "max_correct"   // 1 minute, count how many pairs you can match
    case timeAttack = "time_attack"   // Match 20 pairs as fast as possible

    var displayName: String {
        switch self {
        case .maxCorrect: return "1 Minute Challenge"
        case .timeAttack: return "Time Attack"
        }
    }

    var shortName: String {
        switch self {
        case .maxCorrect: return "1 min"
        case .timeAttack: return "20 pairs"
        }
    }

    var description: String {
        switch self {
        case .maxCorrect: return "Match as many pairs as you can in 60 seconds"
        case .timeAttack: return "Match 20 pairs as fast as possible"
        }
    }

    var icon: String {
        switch self {
        case .maxCorrect: return "timer"
        case .timeAttack: return "bolt.fill"
        }
    }
}

struct Stage: Identifiable, Sendable {
    let id: String
    let level: CEFRLevel
    let mode: GameMode
    let visiblePairs: Int            // always 5 cards per column
    let totalPairs: Int              // for time attack: 15. for max correct: large pool (60)
    let timeLimitSeconds: Double     // for max correct: 60. for time attack: hard cap

    var displayName: String { "\(level.rawValue) \(mode.shortName)" }

    /// Two stages per CEFR level: one max-correct, one time-attack
    static func stages(for level: CEFRLevel) -> [Stage] {
        GameMode.allCases.map { stage(level: level, mode: $0) }
    }

    static func stage(level: CEFRLevel, mode: GameMode) -> Stage {
        switch mode {
        case .maxCorrect:
            return Stage(
                id: "\(level.rawValue)_max",
                level: level,
                mode: .maxCorrect,
                visiblePairs: 5,
                totalPairs: 60,                  // big pool, won't usually be exhausted
                timeLimitSeconds: 60
            )
        case .timeAttack:
            return Stage(
                id: "\(level.rawValue)_attack",
                level: level,
                mode: .timeAttack,
                visiblePairs: 5,
                totalPairs: 20,
                timeLimitSeconds: 300            // hard cap (5 min)
            )
        }
    }

    /// Stage for category mode: fixed 20 pairs, time-attack
    static func categoryStage(rank: CategoryRank) -> Stage {
        Stage(
            id: "category_\(rank.rawValue)",
            level: rank.cefrLevels.first ?? .a1,
            mode: .timeAttack,
            visiblePairs: 5,
            totalPairs: 15,
            timeLimitSeconds: 300
        )
    }
}

/// Category mode rank: A (A1+A2), B (B1+B2)
enum CategoryRank: String, CaseIterable, Identifiable, Sendable {
    case a = "A"
    case b = "B"

    var id: String { rawValue }

    var cefrLevels: [CEFRLevel] {
        switch self {
        case .a: return [.a1, .a2]
        case .b: return [.b1, .b2]
        }
    }

    var displayName: String { "Rank \(rawValue)" }

    var description: String {
        switch self {
        case .a: return "Beginner (A1-A2)"
        case .b: return "Intermediate (B1-B2)"
        }
    }
}
