import Foundation

struct GameCard: Identifiable, Sendable, Hashable {
    let id: UUID
    let entryId: Int64
    let displayText: String
    let column: CardColumn
    var state: CardState

    init(entryId: Int64, displayText: String, column: CardColumn) {
        self.id = UUID()
        self.entryId = entryId
        self.displayText = displayText
        self.column = column
        self.state = .idle
    }

    enum CardState: Sendable, Hashable {
        case idle
        case selected
        case matched
        case wrong
    }
}

enum CardColumn: Sendable, Hashable {
    case english
    case japanese
}
