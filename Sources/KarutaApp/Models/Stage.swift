import Foundation

struct Stage: Identifiable, Sendable {
    let id: String
    let level: CEFRLevel
    let subLevel: Int             // 1-7 within each CEFR level
    let visiblePairs: Int         // always 5
    let totalPairs: Int
    let timeLimitSeconds: Double

    var displayName: String { "\(level.rawValue)-\(subLevel)" }

    /// Stages for a specific CEFR level (7 stages each)
    static func stages(for level: CEFRLevel) -> [Stage] {
        (1...7).map { sub in
            Stage(
                id: "\(level.rawValue)_\(sub)",
                level: level,
                subLevel: sub,
                visiblePairs: 5,
                totalPairs: totalPairs(for: sub),
                timeLimitSeconds: timeLimit(for: sub)
            )
        }
    }

    // Sub-level 1: 10 pairs → Sub-level 7: 22 pairs
    private static func totalPairs(for sub: Int) -> Int {
        switch sub {
        case 1: return 10
        case 2: return 12
        case 3: return 14
        case 4: return 16
        case 5: return 18
        case 6: return 20
        case 7: return 22
        default: return 10
        }
    }

    // Sub-level 1: 95s → Sub-level 7: 65s
    private static func timeLimit(for sub: Int) -> Double {
        switch sub {
        case 1: return 95
        case 2: return 90
        case 3: return 85
        case 4: return 80
        case 5: return 75
        case 6: return 70
        case 7: return 65
        default: return 90
        }
    }

    /// Stage for category mode: fixed 15 pairs, time-attack
    static func categoryStage(rank: CategoryRank) -> Stage {
        Stage(
            id: "category_\(rank.rawValue)",
            level: rank.cefrLevels.first ?? .a1,
            subLevel: 0,
            visiblePairs: 5,
            totalPairs: 15,
            timeLimitSeconds: 120  // generous for time-attack
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
