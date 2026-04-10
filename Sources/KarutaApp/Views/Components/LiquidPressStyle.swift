import SwiftUI

/// Liquid-feel button press style: scale + slight rotation + spring back.
struct LiquidPressStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.94

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(
                .interpolatingSpring(stiffness: 280, damping: 14),
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    HapticManager.shared.cardTap()
                }
            }
    }
}
