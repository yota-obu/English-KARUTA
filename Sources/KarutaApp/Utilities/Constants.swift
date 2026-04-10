import Foundation

enum GameConstants {
    static let defaultTimeLimit: Double = 105.0        // 1:45
    static let countdownSeconds: Int = 3
    static let baseScore: Int = 10
    static let timePenalty: Double = 3.0
    static let timerWarningThreshold: Double = 10.0

    static let cardCornerRadius: CGFloat = 20
    static let cardShadowRadius: CGFloat = 8
    static let cardSpacing: CGFloat = 10
    static let columnSpacing: CGFloat = 16

    static let matchAnimationDuration: Double = 0.3
    static let shakeAnimationDuration: Double = 0.4
    static let cardSlideInDuration: Double = 0.35
    static let springResponse: Double = 0.3
    static let springDamping: Double = 0.6

    static let streakMilestone: Int = 5

    enum Scoring {
        static func calculate(basePoints: Int = GameConstants.baseScore,
                              streak: Int,
                              timeRemaining: Double,
                              timeLimit: Double) -> Int {
            let speedBonus = max(1.0, 1.0 + (timeRemaining / timeLimit) * 0.5)
            let streakMultiplier: Double = switch streak {
            case 0...2: 1.0
            case 3...5: 1.5
            case 6...9: 2.0
            case 10...14: 2.5
            default: 3.0
            }
            return Int(Double(basePoints) * speedBonus * streakMultiplier)
        }
    }
}
