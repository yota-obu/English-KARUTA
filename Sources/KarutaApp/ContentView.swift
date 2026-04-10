import SwiftUI

struct ContentView: View {
    @State private var onboardingCompleted =
        UserDefaults.standard.bool(forKey: "onboardingCompleted")

    var body: some View {
        if onboardingCompleted {
            HomeView()
                .preferredColorScheme(.light)
        } else {
            OnboardingView(isCompleted: $onboardingCompleted)
                .preferredColorScheme(.light)
        }
    }
}
