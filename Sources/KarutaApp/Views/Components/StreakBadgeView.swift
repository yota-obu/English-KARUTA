import SwiftUI

struct StreakBadgeView: View {
    let streak: Int

    var body: some View {
        if streak >= 3 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(ColorPalette.streakGold)
                Text("\(streak)")
                    .font(FontStyles.streakText)
                    .foregroundStyle(ColorPalette.streakGold)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .softCard(color: ColorPalette.backgroundCard)
            .transition(.scale.combined(with: .opacity))
        }
    }
}
