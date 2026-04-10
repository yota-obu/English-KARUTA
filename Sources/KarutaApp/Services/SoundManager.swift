import AVFoundation
import UIKit

@MainActor
final class SoundManager: Sendable {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]

    var isEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "soundEnabled") }
    }

    func preload() {
        let sounds = ["correct", "wrong", "combo", "countdown", "gameover"]
        for name in sounds {
            if let url = Bundle.main.url(forResource: name, withExtension: "caf", subdirectory: "Resources") {
                players[name] = try? AVAudioPlayer(contentsOf: url)
                players[name]?.prepareToPlay()
            }
        }
    }

    func playCorrect() {
        play("correct", fallbackSystemSound: 1057)
    }

    func playWrong() {
        play("wrong", fallbackSystemSound: 1053)
    }

    func playCombo() {
        play("combo", fallbackSystemSound: 1025)
    }

    func playCountdown() {
        play("countdown", fallbackSystemSound: 1103)
    }

    func playGameOver() {
        play("gameover", fallbackSystemSound: 1026)
    }

    private func play(_ name: String, fallbackSystemSound: SystemSoundID) {
        guard isEnabled else { return }
        if let player = players[name] {
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(fallbackSystemSound)
        }
    }
}
