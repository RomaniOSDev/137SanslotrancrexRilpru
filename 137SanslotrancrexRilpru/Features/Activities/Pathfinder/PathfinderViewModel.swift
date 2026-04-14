import Combine
import Foundation
import SwiftUI

struct GridPoint: Hashable {
    var row: Int
    var col: Int
}

@MainActor
final class PathfinderViewModel: ObservableObject {
    @Published private(set) var rows: Int
    @Published private(set) var cols: Int
    @Published private(set) var walls: Set<GridPoint>
    @Published private(set) var start: GridPoint
    @Published private(set) var end: GridPoint
    @Published var path: [GridPoint]
    @Published var moves: Int
    @Published var isPathInvalid: Bool

    let address: LevelAddress
    private let startDate: Date
    private(set) var optimalSteps: Int

    init(address: LevelAddress) {
        self.address = address
        self.startDate = Date()
        self.path = []
        self.moves = 0
        self.isPathInvalid = false
        self.rows = 5
        self.cols = 5
        self.walls = []
        self.start = GridPoint(row: 0, col: 0)
        self.end = GridPoint(row: 0, col: 0)
        self.optimalSteps = 1

        configure(for: address)
        if Self.shortestPathLength(rows: rows, cols: cols, walls: walls, start: start, end: end) == nil {
            walls = []
        }
        optimalSteps = Self.shortestPathLength(rows: rows, cols: cols, walls: walls, start: start, end: end) ?? 1
    }

    var elapsed: TimeInterval {
        Date().timeIntervalSince(startDate)
    }

    func resetPath() {
        path = []
        isPathInvalid = false
    }

    func handleDrag(to point: GridPoint) {
        guard point.row >= 0, point.row < rows, point.col >= 0, point.col < cols else { return }
        guard !walls.contains(point) else {
            isPathInvalid = true
            return
        }

        if path.isEmpty {
            guard point == start else { return }
            path = [start]
            return
        }

        if let last = path.last {
            if point == last { return }
            if isAdjacent(last, point) {
                if path.count >= 2, path[path.count - 2] == point {
                    path.removeLast()
                    moves += 1
                    isPathInvalid = false
                    return
                }
                if path.contains(point) {
                    isPathInvalid = true
                    return
                }
                path.append(point)
                moves += 1
                isPathInvalid = false
            }
        }
    }

    func evaluateOutcome() -> ActivityOutcome? {
        guard let last = path.last, last == end, path.first == start else { return nil }
        let length = path.count - 1
        guard length > 0 else { return nil }

        let stars = Self.stars(for: length, optimal: optimalSteps, difficulty: address.difficulty)
        let accuracy = min(1, Double(optimalSteps) / Double(max(length, 1)))
        return ActivityOutcome(
            level: address,
            durationSeconds: elapsed,
            moves: moves,
            accuracyRatio: accuracy,
            starsEarned: stars,
            newAchievementIds: []
        )
    }

    func clearIfInvalid() {
        if isPathInvalid {
            path = []
            isPathInvalid = false
        }
    }

    private func configure(for address: LevelAddress) {
        switch address.difficulty {
        case .easy:
            configurePathEasy(stage: address.index)
        case .normal:
            configurePathNormal(stage: address.index)
        case .hard:
            configurePathHard(stage: address.index)
        }
    }

    private func configurePathEasy(stage: Int) {
        rows = 5
        cols = 5
        let pairs: [(GridPoint, GridPoint)] = [
            (GridPoint(row: 4, col: 1), GridPoint(row: 0, col: 3)),
            (GridPoint(row: 4, col: 0), GridPoint(row: 0, col: 4)),
            (GridPoint(row: 4, col: 2), GridPoint(row: 0, col: 2)),
            (GridPoint(row: 3, col: 0), GridPoint(row: 0, col: 4)),
            (GridPoint(row: 4, col: 3), GridPoint(row: 1, col: 0)),
            (GridPoint(row: 2, col: 0), GridPoint(row: 4, col: 4))
        ]
        let pair = pairs[stage % pairs.count]
        start = pair.0
        end = pair.1
        walls = easyWallsStages(seed: stage)
    }

    private func easyWallsStages(seed: Int) -> Set<GridPoint> {
        let pool: [GridPoint] = [
            GridPoint(row: 3, col: 2),
            GridPoint(row: 2, col: 2),
            GridPoint(row: 1, col: 3),
            GridPoint(row: 2, col: 1),
            GridPoint(row: 3, col: 1),
            GridPoint(row: 1, col: 2),
            GridPoint(row: 2, col: 3),
            GridPoint(row: 3, col: 3)
        ]
        let count = min(pool.count, seed + 1)
        return Set(pool.prefix(count))
    }

    private func configurePathNormal(stage: Int) {
        rows = 6
        cols = 6
        start = GridPoint(row: 5, col: min(1, stage % 3))
        end = GridPoint(row: 0, col: max(3, 5 - (stage % 3)))
        walls = normalWalls(seed: stage)
        if stage >= 4 {
            walls.formUnion([
                GridPoint(row: 2, col: 2),
                GridPoint(row: 3, col: 3)
            ])
        }
    }

    private func configurePathHard(stage: Int) {
        rows = 7
        cols = 7
        start = GridPoint(row: 6, col: 1 + (stage % 3))
        end = GridPoint(row: 0, col: 3 + (stage % 2))
        walls = hardWalls(seed: stage)
        if stage >= 3 {
            walls.insert(GridPoint(row: 3, col: 3))
        }
        if stage >= 5 {
            walls.formUnion([
                GridPoint(row: 2, col: 4),
                GridPoint(row: 4, col: 2)
            ])
        }
    }

    private func normalWalls(seed: Int) -> Set<GridPoint> {
        var set = Set<GridPoint>()
        for r in 1..<5 {
            set.insert(GridPoint(row: r, col: (r + seed) % 5 + 1))
        }
        set.insert(GridPoint(row: 2, col: 4))
        set.insert(GridPoint(row: 4, col: 2))
        return set
    }

    private func hardWalls(seed: Int) -> Set<GridPoint> {
        var set = Set<GridPoint>()
        for c in stride(from: 1, through: 5, by: 2) {
            set.insert(GridPoint(row: 3, col: c + (seed % 2)))
        }
        for r in 1..<6 {
            if r % 3 == 0 {
                set.insert(GridPoint(row: r, col: (r + seed) % 6))
            }
        }
        return set
    }

    private func isAdjacent(_ a: GridPoint, _ b: GridPoint) -> Bool {
        abs(a.row - b.row) + abs(a.col - b.col) == 1
    }

    private static func shortestPathLength(
        rows: Int,
        cols: Int,
        walls: Set<GridPoint>,
        start: GridPoint,
        end: GridPoint
    ) -> Int? {
        var queue: [GridPoint] = [start]
        var dist: [GridPoint: Int] = [start: 0]
        let dirs = [GridPoint(row: -1, col: 0), GridPoint(row: 1, col: 0), GridPoint(row: 0, col: -1), GridPoint(row: 0, col: 1)]

        while !queue.isEmpty {
            let cur = queue.removeFirst()
            if cur == end {
                return dist[cur]
            }
            for d in dirs {
                let next = GridPoint(row: cur.row + d.row, col: cur.col + d.col)
                guard next.row >= 0, next.row < rows, next.col >= 0, next.col < cols else { continue }
                guard !walls.contains(next) else { continue }
                if dist[next] != nil { continue }
                dist[next] = (dist[cur] ?? 0) + 1
                queue.append(next)
            }
        }
        return nil
    }

    private static func stars(for length: Int, optimal: Int, difficulty: BoardDifficulty) -> Int {
        let slack: Int
        switch difficulty {
        case .easy: slack = 2
        case .normal: slack = 4
        case .hard: slack = 6
        }
        if length <= optimal { return 3 }
        if length <= optimal + slack { return 2 }
        return 1
    }
}
