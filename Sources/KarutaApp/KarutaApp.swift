import SwiftUI
import SwiftData

@main
struct KarutaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [GameSession.self, WrongAnswer.self, WordRecord.self])
    }
}
