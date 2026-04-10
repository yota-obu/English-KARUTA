import SwiftUI

struct GameCardView: View {
    let card: GameCard
    let onTap: () -> Void

    @State private var shakeOffset: CGFloat = 0

    private var cardColor: Color {
        switch card.state {
        case .idle:
            return card.column == .english ? ColorPalette.cardEnglish : ColorPalette.cardJapanese
        case .selected:
            return ColorPalette.cardSelected
        case .matched:
            return ColorPalette.correctGreen.opacity(0.3)
        case .wrong:
            return ColorPalette.wrongRed.opacity(0.3)
        }
    }

    private var borderColor: Color {
        switch card.state {
        case .selected: return ColorPalette.accentPrimary
        case .matched: return ColorPalette.correctGreen
        case .wrong: return ColorPalette.wrongRed
        default: return ColorPalette.liquidBorderColor
        }
    }

    var body: some View {
        Button(action: onTap) {
            Text(card.displayText)
                .font(FontStyles.cardText)
                .foregroundStyle(ColorPalette.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                .fill(cardColor)
                .shadow(color: ColorPalette.liquidShadowColor, radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GameConstants.cardCornerRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: card.state == .idle ? 1 : 2)
        )
        .scaleEffect(card.state == .selected ? 1.05 : 1.0)
        .opacity(card.state == .matched ? 0.0 : 1.0)
        .offset(x: shakeOffset)
        .animation(.spring(response: GameConstants.springResponse, dampingFraction: GameConstants.springDamping), value: card.state)
        .onChange(of: card.state) { _, newState in
            if newState == .wrong {
                shakeAnimation()
            }
        }
        .allowsHitTesting(card.state == .idle || card.state == .selected)
    }

    private func shakeAnimation() {
        let d = GameConstants.shakeAnimationDuration / 6
        withAnimation(.easeInOut(duration: d)) { shakeOffset = -10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + d) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = 10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d * 2) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + d * 3) {
            withAnimation(.easeInOut(duration: d)) { shakeOffset = 0 }
        }
    }
}
