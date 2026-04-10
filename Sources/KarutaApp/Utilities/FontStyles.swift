import SwiftUI

enum FontStyles {
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let titleSmall = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 18, weight: .medium, design: .rounded)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let cardText = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let scoreText = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let streakText = Font.system(size: 22, weight: .black, design: .rounded)
    static let timerText = Font.system(size: 14, weight: .bold, design: .monospaced)
}
