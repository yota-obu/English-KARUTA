import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GameSession.playedAt, order: .reverse) private var sessions: [GameSession]

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 48))
                        .foregroundStyle(ColorPalette.textTertiary)
                    Text("No game history yet")
                        .font(FontStyles.bodyLarge)
                        .foregroundStyle(ColorPalette.textSecondary)
                    Text("Play a game to see your results here")
                        .font(FontStyles.bodySmall)
                        .foregroundStyle(ColorPalette.textTertiary)
                }
            } else {
                List {
                    ForEach(sessions) { session in
                        NavigationLink {
                            HistoryDetailView(session: session)
                        } label: {
                            historyRow(session)
                        }
                        .listRowBackground(ColorPalette.backgroundCard)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func historyRow(_ session: GameSession) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(session.cefrLevel)
                        .font(FontStyles.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule().fill(session.level?.color ?? ColorPalette.accentPrimary)
                        )
                    Text(session.modeDisplay)
                        .font(FontStyles.bodyMedium)
                        .foregroundStyle(ColorPalette.textPrimary)
                }

                Text(session.playedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(FontStyles.caption)
                    .foregroundStyle(ColorPalette.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(session.score)")
                    .font(FontStyles.titleSmall)
                    .foregroundStyle(ColorPalette.accentPrimary)
                HStack(spacing: 4) {
                    Image(systemName: session.isCompleted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(session.isCompleted ? ColorPalette.correctGreen : ColorPalette.wrongRed)
                        .font(.caption)
                    Text("\(Int(session.accuracy * 100))%")
                        .font(FontStyles.caption)
                        .foregroundStyle(ColorPalette.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
