import Combine
import Foundation
import SwiftUI

struct TileCell: Hashable {
    var row: Int
    var col: Int
}

struct PlacedTile: Identifiable, Hashable {
    let id: UUID
    var symbol: Int
    var rotation: Int
}

struct TrayChip: Identifiable, Hashable {
    let id: UUID
    var symbol: Int
}

@MainActor
final class TileTacticsViewModel: ObservableObject {
    @Published private(set) var rows: Int
    @Published private(set) var cols: Int
    @Published private(set) var targetSymbols: [[Int]]
    @Published private(set) var blocked: Set<TileCell>
    @Published private(set) var requiresRotation: Bool
    @Published private(set) var mirrorHint: Bool
    @Published private(set) var targetRotations: [[Int]]

    @Published var trayChips: [TrayChip]
    @Published var placements: [TileCell: PlacedTile]
    @Published var moves: Int
    @Published var incorrectFlash: Set<TileCell>

    let address: LevelAddress
    private var parMoves: Int
    private let start: Date

    init(address: LevelAddress) {
        self.address = address
        self.start = Date()
        self.moves = 0
        self.placements = [:]
        self.incorrectFlash = []
        self.trayChips = []
        self.rows = 3
        self.cols = 3
        self.targetSymbols = []
        self.blocked = []
        self.requiresRotation = false
        self.mirrorHint = false
        self.targetRotations = []
        self.parMoves = 12

        configure(for: address)
        refillTray()
    }

    var elapsed: TimeInterval {
        Date().timeIntervalSince(start)
    }

    func symbol(at cell: TileCell) -> Int? {
        guard cell.row >= 0, cell.row < rows, cell.col >= 0, cell.col < cols else { return nil }
        let value = targetSymbols[cell.row][cell.col]
        return value < 0 ? nil : value
    }

    func isBlocked(_ cell: TileCell) -> Bool {
        blocked.contains(cell)
    }

    func rotatePlacedTile(at cell: TileCell) {
        guard var tile = placements[cell] else { return }
        tile.rotation = (tile.rotation + 1) % 4
        placements[cell] = tile
        moves += 1
    }

    func placeChip(id chipID: UUID, at cell: TileCell) {
        guard let index = trayChips.firstIndex(where: { $0.id == chipID }) else { return }
        if isBlocked(cell) { return }
        let symbol = trayChips[index].symbol
        trayChips.remove(at: index)
        if let existing = placements[cell] {
            trayChips.append(TrayChip(id: UUID(), symbol: existing.symbol))
            placements[cell] = nil
        }
        placements[cell] = PlacedTile(id: UUID(), symbol: symbol, rotation: 0)
        moves += 1
    }

    func removePlaced(at cell: TileCell) {
        guard let tile = placements[cell] else { return }
        placements[cell] = nil
        trayChips.append(TrayChip(id: UUID(), symbol: tile.symbol))
        moves += 1
    }

    func checkWin() -> Bool {
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = TileCell(row: r, col: c)
                if isBlocked(cell) { continue }
                guard let expected = symbol(at: cell) else { continue }
                guard let placed = placements[cell] else { return false }
                if placed.symbol != expected { return false }
                if requiresRotation {
                    let needed = targetRotations[r][c]
                    if placed.rotation % 4 != needed % 4 { return false }
                }
            }
        }
        return true
    }

    func computeOutcomeIfSolved() -> ActivityOutcome? {
        guard checkWin() else { return nil }
        let duration = elapsed
        let stars = Self.starRating(moves: moves, par: parMoves, difficulty: address.difficulty)
        let accuracy = min(1, Double(parMoves) / Double(max(moves, 1)))
        return ActivityOutcome(
            level: address,
            durationSeconds: duration,
            moves: moves,
            accuracyRatio: accuracy,
            starsEarned: stars,
            newAchievementIds: []
        )
    }

    private func refillTray() {
        trayChips = []
        for r in 0..<rows {
            for c in 0..<cols {
                let cell = TileCell(row: r, col: c)
                if isBlocked(cell) { continue }
                if let sym = symbol(at: cell) {
                    trayChips.append(TrayChip(id: UUID(), symbol: sym))
                }
            }
        }
        trayChips.shuffle()
        placements = [:]
    }

    func resetBoard() {
        moves = 0
        configure(for: address)
        refillTray()
    }

    private func configure(for address: LevelAddress) {
        switch address.difficulty {
        case .easy:
            configureEasyStage(address.index)
        case .normal:
            configureNormalStage(address.index)
        case .hard:
            configureHardStage(address.index)
        }

        for cell in blocked {
            if cell.row < rows, cell.col < cols {
                targetSymbols[cell.row][cell.col] = -1
            }
        }

        let playable = rows * cols - blocked.count
        parMoves = max(playable + 4, playable * 2)
    }

    private func configureEasyStage(_ stage: Int) {
        rows = 3
        cols = 3
        requiresRotation = false
        targetRotations = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        switch stage {
        case 0:
            mirrorHint = false
            targetSymbols = [
                [0, 1, 2],
                [1, -1, 1],
                [2, 0, 1]
            ]
            blocked = [TileCell(row: 1, col: 1)]
        case 1:
            mirrorHint = true
            targetSymbols = patternEasyMirror()
            blocked = []
        case 2:
            mirrorHint = true
            targetSymbols = patternEasyBands()
            blocked = []
        case 3:
            mirrorHint = false
            targetSymbols = patternEasyGenerated(seed: 3)
            blocked = [TileCell(row: 1, col: 1)]
        case 4:
            mirrorHint = true
            targetSymbols = patternEasyGenerated(seed: 4)
            blocked = []
        default:
            mirrorHint = true
            targetSymbols = patternEasyGenerated(seed: 5)
            blocked = [TileCell(row: 0, col: 1), TileCell(row: 1, col: 0)]
        }
    }

    private func configureNormalStage(_ stage: Int) {
        rows = 4
        cols = 4
        mirrorHint = false
        requiresRotation = true
        let boardSeed = stage % 3
        targetSymbols = patternNormalBoard(index: boardSeed)
        blocked = normalTierBlocks(stage: stage)
        targetRotations = patternRotations(rows: rows, cols: cols, seed: stage)
    }

    private func configureHardStage(_ stage: Int) {
        rows = 5
        cols = 5
        mirrorHint = stage >= 3
        requiresRotation = true
        targetSymbols = patternHardBoard(index: stage % 3)
        blocked = hardObstacles(index: stage)
        if stage >= 4 {
            blocked.insert(TileCell(row: 0, col: 2))
            blocked.insert(TileCell(row: 4, col: 2))
        }
        targetRotations = patternRotations(rows: rows, cols: cols, seed: stage &+ 3)
    }

    private func patternEasyMirror() -> [[Int]] {
        [
            [0, 0, 2],
            [1, 2, 1],
            [2, 1, 0]
        ]
    }

    private func patternEasyBands() -> [[Int]] {
        [
            [2, 1, 0],
            [1, 0, 2],
            [0, 2, 1]
        ]
    }

    private func patternEasyGenerated(seed: Int) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 3), count: 3)
        for r in 0..<3 {
            for c in 0..<3 {
                grid[r][c] = (r * 4 + c * 3 + seed * 2) % 4
            }
        }
        return grid
    }

    private func patternNormalBoard(index: Int) -> [[Int]] {
        let base: [[Int]] = [
            [0, 1, 2, 3],
            [3, 2, 1, 0],
            [1, 0, 3, 2],
            [2, 3, 0, 1]
        ]
        if index == 1 {
            return base.map { row in row.map { ($0 + 1) % 4 } }
        }
        if index == 2 {
            return base.map { row in row.map { ($0 + 3) % 4 } }
        }
        return base.map { row in row.map { ($0 + 2) % 4 } }
    }

    private func normalTierBlocks(stage: Int) -> Set<TileCell> {
        var set: Set<TileCell> = [
            TileCell(row: 0, col: 3),
            TileCell(row: 3, col: 0)
        ]
        if stage >= 3 {
            set.insert(TileCell(row: 1, col: 1))
            set.insert(TileCell(row: 2, col: 2))
        }
        if stage >= 5 {
            set.insert(TileCell(row: 0, col: 1))
        }
        return set
    }

    private func patternHardBoard(index: Int) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 5), count: 5)
        for r in 0..<5 {
            for c in 0..<5 {
                grid[r][c] = (r + c + index) % 4
            }
        }
        return grid
    }

    private func hardObstacles(index: Int) -> Set<TileCell> {
        let seeds: [TileCell] = [
            TileCell(row: 1, col: 2),
            TileCell(row: 2, col: 3),
            TileCell(row: 3, col: 1),
            TileCell(row: 2, col: 2),
            TileCell(row: 1, col: 3),
            TileCell(row: 3, col: 2)
        ]
        let count = min(seeds.count, 2 + (index % 3) + (index / 3))
        return Set(seeds.prefix(count))
    }

    private func patternRotations(rows: Int, cols: Int, seed: Int) -> [[Int]] {
        var result = Array(repeating: Array(repeating: 0, count: cols), count: rows)
        for r in 0..<rows {
            for c in 0..<cols {
                result[r][c] = (r + c + seed) % 4
            }
        }
        return result
    }

    private static func starRating(moves: Int, par: Int, difficulty: BoardDifficulty) -> Int {
        let cushion: Int
        switch difficulty {
        case .easy: cushion = 6
        case .normal: cushion = 10
        case .hard: cushion = 14
        }
        if moves <= par { return 3 }
        if moves <= par + cushion { return 2 }
        return 1
    }
}
