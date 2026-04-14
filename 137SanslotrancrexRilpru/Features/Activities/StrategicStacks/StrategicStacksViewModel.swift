import Combine
import Foundation
import SwiftUI

struct StackCard: Identifiable, Hashable {
    let id: UUID
    var value: Int
    var tint: Int
}

@MainActor
final class StrategicStacksViewModel: ObservableObject {
    @Published private(set) var target: Int
    @Published var hand: [StackCard]
    @Published var stack: [StackCard]
    @Published var moves: Int

    let address: LevelAddress
    private let start: Date
    private var parMoves: Int

    init(address: LevelAddress) {
        self.address = address
        self.start = Date()
        self.moves = 0
        self.target = 0
        self.hand = []
        self.stack = []
        self.parMoves = 3

        configure(for: address)
    }

    var elapsed: TimeInterval {
        Date().timeIntervalSince(start)
    }

    var currentSum: Int {
        stack.map(\.value).reduce(0, +)
    }

    func place(_ card: StackCard) {
        guard let index = hand.firstIndex(where: { $0.id == card.id }) else { return }
        hand.remove(at: index)
        stack.append(card)
        moves += 1
    }

    func undoLast() {
        guard let last = stack.popLast() else { return }
        hand.append(last)
        moves += 1
    }

    func resetBoard() {
        moves = 0
        configure(for: address)
    }

    func evaluateOutcome() -> ActivityOutcome? {
        guard hand.isEmpty, currentSum == target else { return nil }
        let stars = Self.stars(moves: moves, par: parMoves, difficulty: address.difficulty)
        let accuracy = min(1, Double(parMoves) / Double(max(moves, 1)))
        return ActivityOutcome(
            level: address,
            durationSeconds: elapsed,
            moves: moves,
            accuracyRatio: accuracy,
            starsEarned: stars,
            newAchievementIds: []
        )
    }

    private func configure(for address: LevelAddress) {
        stack = []
        let stage = address.index
        switch address.difficulty {
        case .easy:
            let presets: [[Int]] = [
                [2, 2, 2],
                [1, 2, 3],
                [1, 1, 2, 2],
                [3, 1, 2],
                [2, 3, 1],
                [1, 1, 1, 3]
            ]
            applyStackPreset(presets[stage % presets.count], stage: stage, difficulty: .easy)
        case .normal:
            let presets: [[Int]] = [
                [3, 2, 2, 3],
                [4, 1, 2, 1, 2],
                [2, 2, 3, 3],
                [5, 2, 2, 1],
                [3, 3, 3, 1],
                [4, 3, 2, 1]
            ]
            applyStackPreset(presets[stage % presets.count], stage: stage, difficulty: .normal)
        case .hard:
            let presets: [[Int]] = [
                [1, 2, 3, 4, 5],
                [2, 2, 3, 3, 4],
                [6, 2, 1, 1, 3, 2],
                [1, 1, 2, 2, 3, 3, 2],
                [5, 5, 2, 3],
                [4, 4, 4, 2, 3]
            ]
            applyStackPreset(presets[stage % presets.count], stage: stage, difficulty: .hard)
        }
    }

    private func applyStackPreset(_ values: [Int], stage: Int, difficulty: BoardDifficulty) {
        target = values.reduce(0, +)
        let tierBase: Int
        switch difficulty {
        case .easy: tierBase = 0
        case .normal: tierBase = 6
        case .hard: tierBase = 12
        }
        hand = values.enumerated().map { idx, value in
            StackCard(id: UUID(), value: value, tint: idx + stage * 2 + tierBase)
        }.shuffled()
        parMoves = values.count
    }

    private static func stars(moves: Int, par: Int, difficulty: BoardDifficulty) -> Int {
        let cushion: Int
        switch difficulty {
        case .easy: cushion = 3
        case .normal: cushion = 5
        case .hard: cushion = 7
        }
        if moves <= par { return 3 }
        if moves <= par + cushion { return 2 }
        return 1
    }
}
