import SwiftUI
import SwiftData
import UIKit

@main
struct KarutaApp: App {
    init() {
        configureNavigationBar()
        // Eagerly initialize SoundManager so AVAudioSession is active and
        // all SE players are preloaded/warmed up BEFORE the first user tap.
        _ = SoundManager.shared
        // Start BGM if enabled
        Task { @MainActor in
            SoundManager.shared.playBGM()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [GameSession.self, WrongAnswer.self, WordRecord.self])
    }

    private func configureNavigationBar() {
        let titleColor = UIColor(ColorPalette.slate)
        let tintColor = UIColor(ColorPalette.periwinkle)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: titleColor,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = tintColor  // Back button + bar items
    }
}
