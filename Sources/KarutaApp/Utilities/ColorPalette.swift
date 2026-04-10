import SwiftUI

/// Custom 6-color palette
/// - mistWhite  (#F8F9FC) — backgrounds (lightest)
/// - lavender   (#BFC8EA) — soft surfaces, light accent
/// - periwinkle (#738BE7) — primary action / brightest blue
/// - indigo     (#5B67A2) — secondary / strong blue
/// - slate      (#7B86AA) — muted text / borders
/// - charcoal   (#545051) — primary text / dark accent
enum ColorPalette {
    // MARK: - Base Palette (6 colors)
    static let mistWhite  = Color(hex: "F8F9FC")
    static let lavender   = Color(hex: "BFC8EA")
    static let periwinkle = Color(hex: "738BE7")
    static let indigo     = Color(hex: "5B67A2")
    static let slate      = Color(hex: "7B86AA")
    static let charcoal   = Color(hex: "545051")

    // MARK: - Background Layers
    static let backgroundPrimary   = mistWhite
    static let backgroundSecondary = lavender.opacity(0.4)
    static let backgroundCard      = Color.white
    static let backgroundElevated  = Color.white

    // MARK: - Accent (semantic mapping)
    static let accentPrimary   = periwinkle
    static let accentSecondary = indigo
    static let accentTertiary  = lavender

    // MARK: - Text
    static let textPrimary   = charcoal
    static let textSecondary = slate
    static let textTertiary  = slate.opacity(0.6)

    // MARK: - Game State Colors
    static let correctGreen  = periwinkle      // correct → bright periwinkle
    static let wrongRed      = charcoal        // wrong   → dark charcoal
    static let streakGold    = indigo          // streak  → indigo
    static let timerOrange   = indigo
    static let timerCritical = charcoal

    // MARK: - Card Surfaces
    static let cardEnglish  = lavender.opacity(0.45)
    static let cardJapanese = periwinkle.opacity(0.18)
    static let cardSelected = periwinkle.opacity(0.55)

    // MARK: - CEFR Level Colors (mapped from palette)
    static let levelA1 = lavender    // lightest → easiest
    static let levelA2 = slate
    static let levelB1 = periwinkle
    static let levelB2 = indigo      // darkest → hardest

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [mistWhite, lavender.opacity(0.35)],
        startPoint: .top, endPoint: .bottom
    )

    static let accentGradient = LinearGradient(
        colors: [periwinkle, indigo],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: - Liquid effect
    static let liquidShadowColor = indigo.opacity(0.12)
    static let liquidBorderColor = Color.white.opacity(0.7)

    static func levelColor(for level: CEFRLevel) -> Color {
        switch level {
        case .a1: return levelA1
        case .a2: return levelA2
        case .b1: return levelB1
        case .b2: return levelB2
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
