import Combine
import Foundation
import SwiftUI

struct AchievementItem: Identifiable, Hashable {
    let id: String
    let title: String
    let detail: String
    let isUnlocked: Bool
}

@MainActor
final class GameProgressStore: ObservableObject {
    private enum Keys {
        static let hasSeenOnboarding = "board.hasSeenOnboarding"
        static let starsByLevel = "board.starsByLevel"
        static let maxUnlockedProgress = "board.maxUnlockedProgress"
        static let totalPlaySeconds = "board.totalPlaySeconds"
        static let totalActivitiesPlayed = "board.totalActivitiesPlayed"
        static let perfectRuns = "board.perfectRuns"
        static let totalMoves = "board.totalMoves"
    }

    private let defaults: UserDefaults

    @Published private(set) var hasSeenOnboarding: Bool
    @Published private(set) var starsByLevel: [String: Int]
    @Published private(set) var maxUnlockedProgress: [String: Int]
    @Published private(set) var totalPlaySeconds: TimeInterval
    @Published private(set) var totalActivitiesPlayed: Int
    @Published private(set) var perfectRuns: Int
    @Published private(set) var totalMoves: Int

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        starsByLevel = Self.decodeDictionary(from: defaults.string(forKey: Keys.starsByLevel))
        maxUnlockedProgress = Self.decodeIntDictionary(from: defaults.string(forKey: Keys.maxUnlockedProgress))
        totalPlaySeconds = defaults.double(forKey: Keys.totalPlaySeconds)
        totalActivitiesPlayed = defaults.integer(forKey: Keys.totalActivitiesPlayed)
        perfectRuns = defaults.integer(forKey: Keys.perfectRuns)
        totalMoves = defaults.integer(forKey: Keys.totalMoves)
        ensureBootstrapUnlocks()
    }

    func markOnboardingSeen() {
        hasSeenOnboarding = true
        defaults.set(true, forKey: Keys.hasSeenOnboarding)
    }

    func stars(for level: LevelAddress) -> Int {
        starsByLevel[level.storageKey(), default: 0]
    }

    func isUnlocked(_ level: LevelAddress) -> Bool {
        let cap = maxUnlockedProgress[progressKey(for: level.activity), default: 0]
        return level.progressionIndex(for: level.activity) <= cap
    }

    func recordCompletion(outcome: ActivityOutcome) {
        let key = outcome.level.storageKey()
        let previous = starsByLevel[key, default: 0]
        if outcome.starsEarned > previous {
            starsByLevel[key] = outcome.starsEarned
        }

        let pKey = progressKey(for: outcome.level.activity)
        let currentCap = maxUnlockedProgress[pKey, default: 0]
        let completedIndex = outcome.level.progressionIndex(for: outcome.level.activity)
        let proposed = min(completedIndex + 1, LevelAddress.maxUnlockedProgressionIndex)
        if proposed > currentCap {
            maxUnlockedProgress[pKey] = proposed
        }

        totalPlaySeconds += outcome.durationSeconds
        totalActivitiesPlayed += 1
        totalMoves += outcome.moves
        if outcome.starsEarned >= 3 {
            perfectRuns += 1
        }

        persistAll()
    }

    func resetAllProgress() {
        starsByLevel = [:]
        maxUnlockedProgress = [:]
        totalPlaySeconds = 0
        totalActivitiesPlayed = 0
        perfectRuns = 0
        totalMoves = 0

        defaults.removeObject(forKey: Keys.starsByLevel)
        defaults.removeObject(forKey: Keys.maxUnlockedProgress)
        defaults.removeObject(forKey: Keys.totalPlaySeconds)
        defaults.removeObject(forKey: Keys.totalActivitiesPlayed)
        defaults.removeObject(forKey: Keys.perfectRuns)
        defaults.removeObject(forKey: Keys.totalMoves)

        ensureBootstrapUnlocks()
        persistAll()

        NotificationCenter.default.post(name: .boardProgressDidReset, object: nil)
    }

    var totalStarsCollected: Int {
        starsByLevel.values.reduce(0, +)
    }

    var completedLevelsCount: Int {
        starsByLevel.values.filter { $0 > 0 }.count
    }

    var achievements: [AchievementItem] {
        let completed = completedLevelsCount
        let totalStars = totalStarsCollected
        let played = totalActivitiesPlayed
        let perfect = perfectRuns
        let seconds = totalPlaySeconds

        return [
            AchievementItem(
                id: "first_finish",
                title: "Opening Move",
                detail: "Finish any level once.",
                isUnlocked: completed >= 1
            ),
            AchievementItem(
                id: "star_gatherer",
                title: "Bright Progress",
                detail: "Collect 15 stars across levels.",
                isUnlocked: totalStars >= 15
            ),
            AchievementItem(
                id: "dedicated_player",
                title: "Focused Sessions",
                detail: "Play 25 activities in total.",
                isUnlocked: played >= 25
            ),
            AchievementItem(
                id: "precision",
                title: "Clean Finish",
                detail: "Earn 10 perfect three-star results.",
                isUnlocked: perfect >= 10
            ),
            AchievementItem(
                id: "explorer",
                title: "Wide Tour",
                detail: "Clear at least one level in every activity.",
                isUnlocked: BoardActivity.allCases.allSatisfy { activity in
                    LevelAddress.progressionOrder(for: activity).contains { self.stars(for: $0) > 0 }
                }
            ),
            AchievementItem(
                id: "marathon",
                title: "Steady Pace",
                detail: "Spend 30 minutes playing in total.",
                isUnlocked: seconds >= 30 * 60
            )
        ]
    }

    func newlyUnlockedAchievements(after outcome: ActivityOutcome) -> [String] {
        let before = Self.achievementUnlockSet(
            stars: starsByLevel,
            played: totalActivitiesPlayed,
            seconds: totalPlaySeconds,
            perfect: perfectRuns
        )

        var stars = starsByLevel
        let key = outcome.level.storageKey()
        let prev = stars[key, default: 0]
        if outcome.starsEarned > prev {
            stars[key] = outcome.starsEarned
        }

        let played = totalActivitiesPlayed + 1
        let seconds = totalPlaySeconds + outcome.durationSeconds
        var perfect = perfectRuns
        if outcome.starsEarned >= 3 {
            perfect += 1
        }

        let after = Self.achievementUnlockSet(
            stars: stars,
            played: played,
            seconds: seconds,
            perfect: perfect
        )

        return Array(after.subtracting(before)).sorted()
    }

    private static func achievementUnlockSet(
        stars: [String: Int],
        played: Int,
        seconds: TimeInterval,
        perfect: Int
    ) -> Set<String> {
        let completedCount = stars.values.filter { $0 > 0 }.count
        let starsSum = stars.values.reduce(0, +)

        var set = Set<String>()
        if completedCount >= 1 { set.insert("first_finish") }
        if starsSum >= 15 { set.insert("star_gatherer") }
        if played >= 25 { set.insert("dedicated_player") }
        if perfect >= 10 { set.insert("precision") }
        let explorer = BoardActivity.allCases.allSatisfy { activity in
            LevelAddress.progressionOrder(for: activity).contains { addr in
                (stars[addr.storageKey()] ?? 0) > 0
            }
        }
        if explorer { set.insert("explorer") }
        if seconds >= 30 * 60 { set.insert("marathon") }

        return set
    }

    private func progressKey(for activity: BoardActivity) -> String {
        "progress.\(activity.rawValue)"
    }

    private func ensureBootstrapUnlocks() {
        for activity in BoardActivity.allCases {
            let key = progressKey(for: activity)
            if maxUnlockedProgress[key] == nil {
                maxUnlockedProgress[key] = 0
            }
        }
        persistAll()
    }

    private func persistAll() {
        defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding)
        defaults.set(Self.encodeDictionary(starsByLevel), forKey: Keys.starsByLevel)
        defaults.set(Self.encodeIntDictionary(maxUnlockedProgress), forKey: Keys.maxUnlockedProgress)
        defaults.set(totalPlaySeconds, forKey: Keys.totalPlaySeconds)
        defaults.set(totalActivitiesPlayed, forKey: Keys.totalActivitiesPlayed)
        defaults.set(perfectRuns, forKey: Keys.perfectRuns)
        defaults.set(totalMoves, forKey: Keys.totalMoves)
    }

    private static func decodeDictionary(from string: String?) -> [String: Int] {
        guard let data = string?.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Int] else {
            return [:]
        }
        return obj
    }

    private static func decodeIntDictionary(from string: String?) -> [String: Int] {
        decodeDictionary(from: string)
    }

    private static func encodeDictionary(_ dict: [String: Int]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: []) else {
            return "{}"
        }
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    private static func encodeIntDictionary(_ dict: [String: Int]) -> String {
        encodeDictionary(dict)
    }
}
