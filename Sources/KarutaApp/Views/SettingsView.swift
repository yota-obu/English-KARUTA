import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.requestReview) private var requestReview
    @State private var seEnabled = SoundManager.shared.isSEEnabled
    @State private var hapticEnabled = HapticManager.shared.isEnabled
    @State private var showClearConfirm = false
    @State private var showShareSheet = false

    // TODO: 公開時に正しい値へ差し替える
    private let feedbackEmail = "support@example.com"
    private let appStoreId = "id0000000000"
    private var appStoreURL: URL {
        URL(string: "https://apps.apple.com/app/\(appStoreId)")!
    }
    private var appStoreReviewURL: URL {
        URL(string: "https://apps.apple.com/app/\(appStoreId)?action=write-review")!
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            List {
                Section {
                    Toggle(isOn: $seEnabled) {
                        Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                    .onChange(of: seEnabled) { _, val in
                        SoundManager.shared.isSEEnabled = val
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
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Button {
                        sendFeedback()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share App", systemImage: "square.and.arrow.up.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }

                    Button {
                        requestReview()
                    } label: {
                        Label("Rate App", systemImage: "star.fill")
                            .foregroundStyle(ColorPalette.textPrimary)
                    }
                } header: {
                    Text("Support")
                        .foregroundStyle(ColorPalette.textTertiary)
                }
                .listRowBackground(ColorPalette.backgroundCard)

                Section {
                    creditRow(
                        "CEFR-J Wordlist Version 1.6",
                        detail: "Yukio Tono Laboratory, Tokyo University of Foreign Studies. (Downloaded from http://www.cefr-j.org/download.html in April 2026)"
                    )
                    creditRow(
                        "DiQt English-Japanese Dictionary",
                        detail: "BooQs Inc."
                    )
                    creditRow(
                        "Sound Effects",
                        detail: "Pocket Sound – https://pocket-se.info/"
                    )

                    HStack {
                        Text("Version")
                            .foregroundStyle(ColorPalette.textPrimary)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            seEnabled = SoundManager.shared.isSEEnabled
            hapticEnabled = HapticManager.shared.isEnabled
        }
        .alert("Clear All History?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                let store = GameHistoryStore(modelContext: modelContext)
                store.clearAllHistory()
            }
        } message: {
            Text("This will permanently delete all game records and review data.")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "英単語かるたで楽しく語彙力アップ!",
                appStoreURL
            ])
        }
    }

    private func sendFeedback() {
        let subject = "英単語かるた Feedback"
        let body = "\n\n---\nApp Version: \(appVersion)\niOS: \(UIDevice.current.systemVersion)\nDevice: \(UIDevice.current.model)"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(feedbackEmail)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
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
