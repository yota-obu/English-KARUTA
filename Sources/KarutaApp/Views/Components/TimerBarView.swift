import SwiftUI

struct TimerBarView: View {
    let progress: Double
    let timeRemaining: Double

    private var barColor: Color {
        if timeRemaining <= GameConstants.timerWarningThreshold {
            return timeRemaining <= 5 ? ColorPalette.timerCritical : ColorPalette.timerOrange
        }
        return ColorPalette.accentPrimary
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(ColorPalette.backgroundSecondary)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(barColor)
                        .frame(width: geo.size.width * max(0, progress), height: 10)
                        .animation(.linear(duration: 0.05), value: progress)
                }
            }
            .frame(height: 10)

            Text(timeString)
                .font(FontStyles.timerText)
                .foregroundStyle(barColor)
        }
    }

    private var timeString: String {
        let mins = Int(timeRemaining) / 60
        let secs = Int(timeRemaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
