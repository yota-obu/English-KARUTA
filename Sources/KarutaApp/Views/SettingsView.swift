import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var soundEnabled = SoundManager.shared.isEnabled
    @State private var hapticEnabled = HapticManager.shared.isEnabled
    @State private var showClearConfirm = false

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            List {
                Section {
                    Toggle(isOn: $soundEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .onChange(of: soundEnabled) { _, val in
                        SoundManager.shared.isEnabled = val
                    }

                    Toggle(isOn: $hapticEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .onChange(of: hapticEnabled) { _, val in
                        HapticManager.shared.isEnabled = val
                    }
                } header: {
                    Text("Game")
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .listRowBackground(ColorPalette.backgroundCard)

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear All History", systemImage: "trash")
                    }
                } header: {
                    Text("Data")
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .listRowBackground(ColorPalette.backgroundCard)

                Section {
                    creditRow(
                        "『CEFR-J Wordlist Version 1.6』",
                        detail: "東京外国語大学投野由紀夫研究室.（URL: http://www.cefr-j.org/download.html より2026年4月ダウンロード）"
                    )
                    creditRow(
                        "『DiQt English-Japanese Dictionary』",
                        detail: "BooQs Inc."
                    )
                } header: {
                    Text("Credits")
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .listRowBackground(ColorPalette.backgroundCard)

                Section {
                    HStack {
                        Text("Version")
                            .foregroundStyle(ColorPalette.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                }
                .listRowBackground(ColorPalette.backgroundCard)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
                .alert("Clear All History?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                let store = GameHistoryStore(modelContext: modelContext)
                store.clearAllHistory()
            }
        } message: {
            Text("This will permanently delete all game records and review data.")
        }
    }

    private func creditRow(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(FontStyles.bodyMedium)
                .foregroundStyle(ColorPalette.textPrimary)
            Text(detail)
                .font(FontStyles.caption)
                .foregroundStyle(ColorPalette.textTertiary)
        }
        .padding(.vertical, 2)
    }
}
