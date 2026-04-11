import AVFoundation
import UIKit

@MainActor
final class SoundManager: NSObject, @unchecked Sendable {
    static let shared = SoundManager()

    // MARK: - State
    var isSEEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "seEnabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "seEnabled") }
    }

    var isBGMEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "bgmEnabled") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "bgmEnabled")
            if newValue {
                playBGM()
            } else {
                stopBGM()
            }
        }
    }

    /// Legacy compatibility
    var isEnabled: Bool {
        get { isSEEnabled }
        set { isSEEnabled = newValue }
    }

    // MARK: - Players
    private var sePlayers: [String: AVAudioPlayer] = [:]
    private var bgmPlayer: AVAudioPlayer?
    private let seVolume: Float = 0.25     // default 25%
    private let bgmVolume: Float = 0.15    // 15% subtle background
    private let quietVolume: Float = 0.05  // for long/loud sounds (timeup, countdown) — 5%

    // MARK: - Setup
    override init() {
        super.init()
        configureAudioSession()
        preloadSE()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[SoundManager] AudioSession config failed: \(error)")
        }
    }

    func preload() {}

    private func preloadSE() {
        let sounds = ["select", "correct", "wrong", "countdown", "timeup"]
        for name in sounds {
            if let url = Bundle.main.url(forResource: name, withExtension: "caf")
                ?? Bundle.main.url(forResource: name, withExtension: "wav")
                ?? Bundle.main.url(forResource: name, withExtension: "mp3")
                ?? Bundle.main.url(forResource: name, withExtension: "m4a") {
                if let player = try? AVAudioPlayer(contentsOf: url) {
                    player.volume = seVolume
                    player.prepareToPlay()
                    sePlayers[name] = player
                }
            }
        }
        // Warm up: play select sound silently at volume 0 so the audio pipeline
        // is fully primed before the first user tap.
        if let warmup = sePlayers["select"] {
            let originalVolume = warmup.volume
            warmup.volume = 0
            warmup.play()
            warmup.stop()
            warmup.currentTime = 0
            warmup.volume = originalVolume
        }
    }

    // MARK: - SE
    func playSelect()    { playSE("select",    fallback: 1104) }
    func playCorrect()   { playSE("correct",   fallback: 1057) }
    func playWrong()     { playSE("wrong",     fallback: 1053) }
    func playCountdown() { playSE("countdown", fallback: 1103, volume: quietVolume) }
    func playTimeUp()    { playSE("timeup",    fallback: 1026, volume: quietVolume) }

    // Legacy aliases
    func playCombo()    { playSE("correct", fallback: 1025) }
    func playGameOver() { playTimeUp() }

    /// Stop all currently playing SE (used at game end to silence countdown).
    func stopAllSE() {
        for (_, player) in sePlayers {
            if player.isPlaying { player.stop() }
        }
    }

    /// Stop a specific SE.
    func stopSE(_ name: String) {
        sePlayers[name]?.stop()
    }

    func stopCountdown() {
        sePlayers["countdown"]?.stop()
    }

    private func playSE(_ name: String, fallback: SystemSoundID, volume: Float? = nil) {
        guard isSEEnabled else { return }
        if let player = sePlayers[name] {
            player.volume = volume ?? seVolume
            player.currentTime = 0
            player.play()
        } else {
            AudioServicesPlaySystemSound(fallback)
        }
    }

    // MARK: - BGM
    func playBGM() {
        guard isBGMEnabled else { return }
        if bgmPlayer == nil {
            let url = Bundle.main.url(forResource: "bgm", withExtension: "m4a")
                ?? Bundle.main.url(forResource: "bgm", withExtension: "mp3")
                ?? Bundle.main.url(forResource: "bgm", withExtension: "caf")
                ?? Bundle.main.url(forResource: "bgm", withExtension: "wav")
            guard let url = url, let player = try? AVAudioPlayer(contentsOf: url) else {
                print("[SoundManager] BGM file not found")
                return
            }
            player.numberOfLoops = -1
            player.volume = bgmVolume
            player.prepareToPlay()
            bgmPlayer = player
        }
        bgmPlayer?.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
    }

    func pauseBGM() {
        bgmPlayer?.pause()
    }
}
