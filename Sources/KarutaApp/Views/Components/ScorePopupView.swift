import SwiftUI

struct ScorePopupView: View {
    let info: ScorePopupInfo

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text("+\(info.points)")
            .font(FontStyles.titleSmall)
            .fontWeight(.bold)
            .foregroundStyle(info.streak >= 5 ? ColorPalette.streakGold : ColorPalette.correctGreen)
            .offset(y: offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    offset = -60
                    opacity = 0
                }
            }
    }
}
