import SwiftUI

struct SoftCardStyle: ViewModifier {
    var backgroundColor: Color = ColorPalette.backgroundCard
    var cornerRadius: CGFloat = GameConstants.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .shadow(color: ColorPalette.liquidShadowColor, radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(ColorPalette.liquidBorderColor, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func softCard(color: Color = ColorPalette.backgroundCard, cornerRadius: CGFloat = GameConstants.cardCornerRadius) -> some View {
        modifier(SoftCardStyle(backgroundColor: color, cornerRadius: cornerRadius))
    }

    func liquidBackground() -> some View {
        self.background(ColorPalette.backgroundGradient.ignoresSafeArea())
    }
}
