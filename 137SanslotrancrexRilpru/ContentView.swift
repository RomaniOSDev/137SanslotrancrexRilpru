import SwiftUI

struct ContentView: View {
    @StateObject private var store = GameProgressStore()

    var body: some View {
        Group {
            if store.hasSeenOnboarding {
                MainTabView()
            } else {
                OnboardingContainer(store: store)
            }
        }
        .environmentObject(store)
    }
}

#Preview {
    ContentView()
}
