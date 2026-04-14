import Foundation

enum BoardActivity: String, CaseIterable, Codable, Hashable {
    case tileTactics
    case pathfinder
    case strategicStacks

    var displayTitle: String {
        switch self {
        case .tileTactics: return "Tile Tactics"
        case .pathfinder: return "Pathfinder Puzzle"
        case .strategicStacks: return "Strategic Stacks"
        }
    }

    var shortTitle: String {
        switch self {
        case .tileTactics: return "Tiles"
        case .pathfinder: return "Paths"
        case .strategicStacks: return "Stacks"
        }
    }
}

enum BoardDifficulty: String, CaseIterable, Codable, Hashable {
    case easy
    case normal
    case hard

    var displayTitle: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }
}

struct LevelAddress: Hashable, Codable {
    var activity: BoardActivity
    var difficulty: BoardDifficulty
    var index: Int

    /// Stages per difficulty tier (Easy / Normal / Hard). Total per activity = `3 * stagesPerDifficulty`.
    static let stagesPerDifficulty = 6

    static var totalProgressionSteps: Int {
        BoardDifficulty.allCases.count * stagesPerDifficulty
    }

    /// Highest progression index (0-based) after all stages are unlocked.
    static var maxUnlockedProgressionIndex: Int {
        totalProgressionSteps - 1
    }

    static func progressionOrder(for activity: BoardActivity) -> [LevelAddress] {
        var list: [LevelAddress] = []
        for d in BoardDifficulty.allCases {
            for i in 0..<stagesPerDifficulty {
                list.append(LevelAddress(activity: activity, difficulty: d, index: i))
            }
        }
        return list
    }

    func progressionIndex(for activity: BoardActivity) -> Int {
        let order = Self.progressionOrder(for: activity)
        return order.firstIndex(of: self) ?? 0
    }

    func storageKey() -> String {
        "\(activity.rawValue)|\(difficulty.rawValue)|\(index)"
    }

    static func next(after current: LevelAddress) -> LevelAddress? {
        let order = progressionOrder(for: current.activity)
        guard let idx = order.firstIndex(of: current), idx + 1 < order.count else { return nil }
        return order[idx + 1]
    }
}

struct ActivityOutcome: Hashable {
    var level: LevelAddress
    var durationSeconds: TimeInterval
    var moves: Int
    var accuracyRatio: Double
    var starsEarned: Int
    var newAchievementIds: [String]
}

extension Notification.Name {
    static let boardProgressDidReset = Notification.Name("boardProgressDidReset")
}
