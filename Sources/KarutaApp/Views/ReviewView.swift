import SwiftUI
import SwiftData

struct ReviewView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var records: [WordRecord] = []
    @State private var selectedRecord: WordRecord?
    @State private var filterLevel: String? = nil
    @State private var filterMode: FilterMode = .wrong
    @State private var counts: (wrong: Int, mastered: Int, total: Int) = (0, 0, 0)

    private let dictionaryService = DictionaryService.shared

    enum FilterMode: String, CaseIterable {
        case wrong = "Wrong"
        case mastered = "Mastered"
        case all = "All"

        var storeMode: ReviewFilterMode {
            switch self {
            case .wrong: return .wrong
            case .mastered: return .mastered
            case .all: return .all
            }
        }
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                filterBar

                if records.isEmpty {
                    Spacer()
                    emptyView
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(records) { record in
                                wordRow(record)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
        .fullScreenCover(item: $selectedRecord) { record in
            WordDetailSheet(record: record)
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 8) {
            // Mode tabs
            HStack(spacing: 0) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    filterTabButton(mode.rawValue, selected: filterMode == mode) {
                        filterMode = mode
                        loadData()
                    }
                }
            }
            .background(ColorPalette.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)

            // Level filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip("All", selected: filterLevel == nil) {
                        filterLevel = nil
                        loadData()
                    }
                    ForEach(CEFRLevel.allCases) { level in
                        filterChip(level.rawValue, selected: filterLevel == level.rawValue) {
                            filterLevel = level.rawValue
                            loadData()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }

            // Counter (played / total dictionary words for current filter)
            HStack(spacing: 4) {
                Text("\(records.count)")
                    .font(FontStyles.bodyLarge)
                    .foregroundStyle(ColorPalette.accentPrimary)
                Text("/")
                    .foregroundStyle(ColorPalette.textTertiary)
                Text("\(currentDictMax)")
                    .foregroundStyle(ColorPalette.textSecondary)
                Text("words")
                    .font(FontStyles.caption)
                    .foregroundStyle(ColorPalette.textTertiary)
                    .padding(.leading, 4)
            }
            .font(FontStyles.bodyMedium)
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }

    private var currentDictMax: Int {
        if let lvl = filterLevel, let level = CEFRLevel(rawValue: lvl) {
            return dictionaryService.wordCount(level: level)
        }
        return CEFRLevel.allCases.reduce(0) { $0 + dictionaryService.wordCount(level: $1) }
    }

    private func filterTabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FontStyles.bodySmall)
                .foregroundStyle(selected ? .white : ColorPalette.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? ColorPalette.accentPrimary : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func filterChip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FontStyles.caption)
                .foregroundStyle(selected ? .white : ColorPalette.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(selected ? ColorPalette.accentPrimary : ColorPalette.backgroundCard))
        }
    }

    // MARK: - Word Row

    private func wordRow(_ record: WordRecord) -> some View {
        HStack(spacing: 12) {
            Button {
                selectedRecord = record
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(record.headword)
                            .font(FontStyles.bodyLarge)
                            .foregroundStyle(ColorPalette.textPrimary)
                        Text(record.cefrLevel)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(CEFRLevel(rawValue: record.cefrLevel)?.color ?? ColorPalette.accentPrimary))
                    }
                    HStack(spacing: 8) {
                        Text(record.firstMeaning)
                            .font(FontStyles.bodySmall)
                            .foregroundStyle(ColorPalette.textSecondary)
                        Spacer()
                        if record.totalAttempts > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ColorPalette.correctGreen)
                                Text("\(record.correctCount)")
                                Image(systemName: "xmark")
                                    .foregroundStyle(ColorPalette.wrongRed)
                                Text("\(record.wrongCount)")
                            }
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(ColorPalette.textTertiary)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            // Mastered toggle
            Button {
                let store = GameHistoryStore(modelContext: modelContext)
                store.toggleWordMastered(record)
                loadData()
            } label: {
                Image(systemName: record.isMastered ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(record.isMastered ? ColorPalette.correctGreen : ColorPalette.textTertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .softCard()
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: filterMode == .mastered ? "tray" : "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(ColorPalette.accentTertiary)
            Text(emptyMessage)
                .font(FontStyles.bodyLarge)
                .foregroundStyle(ColorPalette.textSecondary)
        }
    }

    private var emptyMessage: String {
        switch filterMode {
        case .wrong: return "No wrong answers yet"
        case .mastered: return "No mastered words yet"
        case .all: return "No word records yet"
        }
    }

    private func loadData() {
        let store = GameHistoryStore(modelContext: modelContext)
        records = store.fetchWordRecords(mode: filterMode.storeMode, level: filterLevel)
        counts = store.wordRecordCounts(level: filterLevel)
    }
}

// MARK: - Word Detail Sheet

struct WordDetailSheet: View {
    let record: WordRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(record.headword)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(ColorPalette.textPrimary)

                            if !record.ipa.isEmpty {
                                Text(record.ipa)
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundStyle(ColorPalette.textTertiary)
                            }
                        }

                        // Badges
                        HStack(spacing: 8) {
                            infoBadge(record.cefrLevel, color: CEFRLevel(rawValue: record.cefrLevel)?.color ?? ColorPalette.accentPrimary)
                            infoBadge(record.pos, color: ColorPalette.textTertiary)
                            if !record.topic.isEmpty {
                                let mainTopic = record.topic.components(separatedBy: ";").first?.trimmingCharacters(in: .whitespaces) ?? ""
                                if !mainTopic.isEmpty {
                                    infoBadge(mainTopic, color: ColorPalette.accentTertiary)
                                }
                            }
                        }

                        // Stats
                        if record.totalAttempts > 0 {
                            HStack(spacing: 16) {
                                statBox(label: "Correct", value: "\(record.correctCount)", color: ColorPalette.correctGreen)
                                statBox(label: "Wrong", value: "\(record.wrongCount)", color: ColorPalette.wrongRed)
                                statBox(label: "Accuracy", value: "\(Int(record.accuracy * 100))%", color: ColorPalette.accentPrimary)
                            }
                        }

                        Divider()

                        // All meanings
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Meanings")
                                .font(FontStyles.bodyLarge)
                                .foregroundStyle(ColorPalette.textPrimary)

                            let meanings = record.meaningsList
                            ForEach(Array(meanings.enumerated()), id: \.offset) { index, meaning in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(FontStyles.bodySmall)
                                        .foregroundStyle(ColorPalette.accentPrimary)
                                        .frame(width: 20, alignment: .trailing)
                                    Text(meaning)
                                        .font(FontStyles.bodyMedium)
                                        .foregroundStyle(ColorPalette.textPrimary)
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .softCard(color: ColorPalette.cardJapanese.opacity(0.3))

                        // Examples
                        if !record.exampleEn.isEmpty || !record.exampleJa.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Example")
                                    .font(FontStyles.bodyLarge)
                                    .foregroundStyle(ColorPalette.textPrimary)

                                if !record.exampleEn.isEmpty {
                                    Text(record.exampleEn)
                                        .font(FontStyles.bodyMedium)
                                        .foregroundStyle(ColorPalette.textPrimary)
                                        .padding(14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .softCard(color: ColorPalette.cardEnglish)
                                }
                                if !record.exampleJa.isEmpty {
                                    Text(record.exampleJa)
                                        .font(FontStyles.bodyMedium)
                                        .foregroundStyle(ColorPalette.textPrimary)
                                        .padding(14)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .softCard(color: ColorPalette.cardJapanese)
                                }
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(ColorPalette.accentPrimary)
                }
            }
        }
    }

    private func infoBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(FontStyles.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(color))
    }

    private func statBox(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(FontStyles.titleSmall)
                .foregroundStyle(color)
            Text(label)
                .font(FontStyles.caption)
                .foregroundStyle(ColorPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .softCard()
    }
}
