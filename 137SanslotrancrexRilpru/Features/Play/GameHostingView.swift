import SwiftUI

struct GameHostingView: View {
    @EnvironmentObject private var store: GameProgressStore
    @Binding var path: NavigationPath
    var address: LevelAddress

    var body: some View {
        Group {
            switch address.activity {
            case .tileTactics:
                TileTacticsView(address: address, onComplete: finish)
            case .pathfinder:
                PathfinderView(address: address, onComplete: finish)
            case .strategicStacks:
                StrategicStacksView(address: address, onComplete: finish)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func finish(_ raw: ActivityOutcome) {
        let unlocked = store.newlyUnlockedAchievements(after: raw)
        let merged = ActivityOutcome(
            level: raw.level,
            durationSeconds: raw.durationSeconds,
            moves: raw.moves,
            accuracyRatio: raw.accuracyRatio,
            starsEarned: raw.starsEarned,
            newAchievementIds: unlocked
        )
        store.recordCompletion(outcome: merged)
        path.removeLast()
        path.append(PlayStack.summary(merged))
    }
}
