import SwiftUI

enum PlayStack: Hashable {
    case levels(BoardActivity)
    case game(LevelAddress)
    case summary(ActivityOutcome)
}

struct PlayRootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ActivitySelectionView { activity in
                path.append(PlayStack.levels(activity))
            }
            .navigationDestination(for: PlayStack.self) { destination in
                switch destination {
                case .levels(let activity):
                    LevelGridView(activity: activity) { level in
                        path.append(PlayStack.game(level))
                    }
                case .game(let address):
                    GameHostingView(path: $path, address: address)
                case .summary(let outcome):
                    ActivityResultView(path: $path, outcome: outcome)
                }
            }
        }
        .tint(Color.appPrimary)
    }
}
