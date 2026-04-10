import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<WordRecord> { $0.masteredAt == nil }) private var unmasteredRecords: [WordRecord]
    @State private var showStageSelect = false
    @State private var showHistory = false
    @State private var showReview = false
    @State private var showSettings = false

    private var unreviewedCount: Int { unmasteredRecords.count }

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundGradient.ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // Logo
                    VStack(spacing: 8) {
                        Text("英単語かるた")
                            .font(.custom("HiraMaruProN-W4", size: 44))
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )

                        Text("English Vocabulary Karuta")
                            .font(.custom("HiraMaruProN-W4", size: 18))
                            .foregroundStyle(ColorPalette.textSecondary)
                    }

                    Spacer()

                    // Menu Buttons
                    VStack(spacing: 14) {
                        menuButton(title: "Play", icon: "play.fill", accent: ColorPalette.periwinkle) {
                            SoundManager.shared.playSelect()
                            showStageSelect = true
                        }

                        menuButton(title: "Review", icon: "book.fill", accent: ColorPalette.indigo, badge: unreviewedCount) {
                            SoundManager.shared.playSelect()
                            showReview = true
                        }

                        menuButton(title: "History", icon: "clock.fill", accent: ColorPalette.lavender) {
                            SoundManager.shared.playSelect()
                            showHistory = true
                        }

                        menuButton(title: "Settings", icon: "gearshape.fill", accent: ColorPalette.slate) {
                            SoundManager.shared.playSelect()
                            showSettings = true
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            }
            .navigationDestination(isPresented: $showStageSelect) {
                StageSelectView()
            }
            .navigationDestination(isPresented: $showHistory) {
                HistoryView()
            }
            .navigationDestination(isPresented: $showReview) {
                ReviewView()
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private func menuButton(title: String, icon: String, accent: Color, badge: Int = 0, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accent)
                    .frame(width: 28)
                Text(title)
                    .font(FontStyles.bodyLarge)
                    .foregroundStyle(ColorPalette.textPrimary)
                Spacer()
                if badge > 0 {
                    Text("\(badge)")
                        .font(FontStyles.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(accent))
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                    .fill(ColorPalette.backgroundCard)
                    .shadow(color: ColorPalette.liquidShadowColor, radius: 12, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(LiquidPressStyle())
    }
}
