import Foundation
import SQLite3
import os

final class DictionaryService: @unchecked Sendable {
    static let shared = DictionaryService()

    private var db: OpaquePointer?
    private let logger = Logger(subsystem: "com.karutaapp", category: "Dictionary")

    init() {
        openDatabase()
    }

    deinit {
        if let db = db { sqlite3_close(db) }
    }

    private func openDatabase() {
        let url = Bundle.main.url(forResource: "dictionary", withExtension: "sqlite")
            ?? Bundle.main.url(forResource: "dictionary", withExtension: "sqlite", subdirectory: "Resources")

        guard let dbPath = url?.path else {
            logger.error("dictionary.sqlite not found in bundle")
            return
        }

        if sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            logger.info("DB opened at \(dbPath)")
        } else {
            logger.error("Failed to open DB")
            db = nil
        }
    }

    // MARK: - Fetch by level

    func fetchWords(level: CEFRLevel, count: Int, excluding: Set<Int64> = []) -> [DictionaryEntry] {
        let excludeClause = excluding.isEmpty ? "" : " AND id NOT IN (\(excluding.map { String($0) }.joined(separator: ",")))"
        let query = "SELECT id, headword, pos, cefr_level, first_meaning, all_meanings, ipa, topic, example_en, example_ja FROM entries WHERE cefr_level = '\(level.rawValue)'\(excludeClause) ORDER BY RANDOM() LIMIT \(count)"
        return executeQuery(query, fallbackLevel: level)
    }

    // MARK: - Fetch by topic

    func fetchWordsByTopic(topic: String, count: Int, excluding: Set<Int64> = []) -> [DictionaryEntry] {
        let excludeClause = excluding.isEmpty ? "" : " AND id NOT IN (\(excluding.map { String($0) }.joined(separator: ",")))"
        let safeTopic = topic.replacingOccurrences(of: "'", with: "''")
        let query = "SELECT id, headword, pos, cefr_level, first_meaning, all_meanings, ipa, topic, example_en, example_ja FROM entries WHERE topic LIKE '%\(safeTopic)%'\(excludeClause) ORDER BY RANDOM() LIMIT \(count)"
        return executeQuery(query, fallbackLevel: .a1)
    }

    /// Fetch words by topic AND restrict to certain CEFR levels.
    func fetchWordsByTopic(topic: String, levels: [CEFRLevel], count: Int) -> [DictionaryEntry] {
        let safeTopic = topic.replacingOccurrences(of: "'", with: "''")
        let levelList = levels.map { "'\($0.rawValue)'" }.joined(separator: ",")
        let query = "SELECT id, headword, pos, cefr_level, first_meaning, all_meanings, ipa, topic, example_en, example_ja FROM entries WHERE topic LIKE '%\(safeTopic)%' AND cefr_level IN (\(levelList)) ORDER BY RANDOM() LIMIT \(count)"
        return executeQuery(query, fallbackLevel: levels.first ?? .a1)
    }

    func topicWordCount(topic: String, levels: [CEFRLevel]) -> Int {
        guard let db = db else { return 0 }
        let safeTopic = topic.replacingOccurrences(of: "'", with: "''")
        let levelList = levels.map { "'\($0.rawValue)'" }.joined(separator: ",")
        let query = "SELECT COUNT(*) FROM entries WHERE topic LIKE '%\(safeTopic)%' AND cefr_level IN (\(levelList))"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    // MARK: - Fetch single

    func fetchEntry(id: Int64) -> DictionaryEntry? {
        let query = "SELECT id, headword, pos, cefr_level, first_meaning, all_meanings, ipa, topic, example_en, example_ja FROM entries WHERE id = \(id)"
        return executeQuery(query, fallbackLevel: .a1).first
    }

    // MARK: - Topics

    func allTopics() -> [String] {
        guard let db = db else { return [] }
        let query = "SELECT DISTINCT topic FROM entries WHERE topic IS NOT NULL AND topic != '' ORDER BY topic"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var topics: [String] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            if let ptr = sqlite3_column_text(stmt, 0) {
                topics.append(String(cString: ptr))
            }
        }
        return topics
    }

    func wordCount(level: CEFRLevel) -> Int {
        guard let db = db else { return 0 }
        let query = "SELECT COUNT(*) FROM entries WHERE cefr_level = '\(level.rawValue)'"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    func topicWordCount(topic: String) -> Int {
        guard let db = db else { return 0 }
        let safeTopic = topic.replacingOccurrences(of: "'", with: "''")
        let query = "SELECT COUNT(*) FROM entries WHERE topic LIKE '%\(safeTopic)%'"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return 0 }
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_step(stmt) == SQLITE_ROW else { return 0 }
        return Int(sqlite3_column_int(stmt, 0))
    }

    // MARK: - Private

    private func executeQuery(_ query: String, fallbackLevel: CEFRLevel) -> [DictionaryEntry] {
        guard let db = db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var entries: [DictionaryEntry] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            guard let hwPtr = sqlite3_column_text(stmt, 1),
                  let posPtr = sqlite3_column_text(stmt, 2),
                  let cefrPtr = sqlite3_column_text(stmt, 3),
                  let firstPtr = sqlite3_column_text(stmt, 4),
                  let allPtr = sqlite3_column_text(stmt, 5) else { continue }

            let allMeaningsStr = String(cString: allPtr)
            let allMeanings = allMeaningsStr.split(separator: "\n").map(String.init)

            entries.append(DictionaryEntry(
                id: sqlite3_column_int64(stmt, 0),
                headword: String(cString: hwPtr),
                pos: String(cString: posPtr),
                cefrLevel: CEFRLevel(rawValue: String(cString: cefrPtr)) ?? fallbackLevel,
                firstMeaning: String(cString: firstPtr),
                allMeanings: allMeanings,
                ipa: sqlite3_column_text(stmt, 6).map { String(cString: $0) },
                topic: sqlite3_column_text(stmt, 7).map { String(cString: $0) },
                exampleEn: sqlite3_column_text(stmt, 8).map { String(cString: $0) },
                exampleJa: sqlite3_column_text(stmt, 9).map { String(cString: $0) }
            ))
        }
        return entries
    }
}
