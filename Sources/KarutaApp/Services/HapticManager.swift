import UIKit

@MainActor
final class HapticManager: Sendable {
    static let shared = HapticManager()

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "hapticEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "hapticEnabled") }
    }

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    func prepare() {
        selectionGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    func cardTap() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
    }

    func correctMatch() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }

    func wrongMatch() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }

    func streakMilestone() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred(intensity: 1.0)
    }

    func countdownTick() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred(intensity: 0.5)
    }

    func gameComplete() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            heavyGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            mediumGenerator.impactOccurred()
        }
    }
}
