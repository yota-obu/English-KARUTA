import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, description: String)] = [
        ("rectangle.on.rectangle.angled", "Match the Pairs",
         "Tap an English word, then tap its Japanese translation to match them!"),
        ("timer", "Beat the Clock",
         "Complete all pairs before time runs out. Wrong answers cost 3 seconds!"),
        ("flame.fill", "Build Streaks",
         "Consecutive correct matches boost your score multiplier up to 3x!"),
        ("chart.bar.fill", "Track & Improve",
         "Review wrong answers with example sentences and watch your progress grow."),
    ]

    var body: some View {
        ZStack {
            ColorPalette.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        VStack(spacing: 24) {
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )

                            Text(pages[index].title)
                                .font(FontStyles.titleLarge)
                                .foregroundStyle(ColorPalette.textPrimary)

                            Text(pages[index].description)
                                .font(FontStyles.bodyMedium)
                                .foregroundStyle(ColorPalette.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? ColorPalette.accentPrimary : ColorPalette.textTertiary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }

                Spacer()

                // Start Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                        isCompleted = true
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Next" : "Start Playing")
                        .font(FontStyles.bodyLarge)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [ColorPalette.accentPrimary, ColorPalette.accentSecondary],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
