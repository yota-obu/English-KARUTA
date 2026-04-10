import SwiftUI

enum CEFRLevel: String, CaseIterable, Codable, Sendable, Comparable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var description: String {
        switch self {
        case .a1: return "Beginner"
        case .a2: return "Elementary"
        case .b1: return "Intermediate"
        case .b2: return "Upper Intermediate"
        }
    }

    var descriptionJa: String {
        switch self {
        case .a1: return "初級"
        case .a2: return "初級上"
        case .b1: return "中級"
        case .b2: return "中級上"
        }
    }

    var color: Color {
        ColorPalette.levelColor(for: self)
    }

    private var sortOrder: Int {
        switch self {
        case .a1: return 0
        case .a2: return 1
        case .b1: return 2
        case .b2: return 3
        }
    }

    static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
