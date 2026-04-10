import Foundation

struct DictionaryEntry: Identifiable, Sendable, Hashable {
    let id: Int64
    let headword: String
    let pos: String
    let cefrLevel: CEFRLevel
    let firstMeaning: String       // Primary meaning for karuta
    let allMeanings: [String]      // All meanings for review
    let ipa: String?
    let topic: String?
    let exampleEn: String?
    let exampleJa: String?
}
