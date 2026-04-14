import SwiftUI

struct LevelGridView: View {
    @EnvironmentObject private var store: GameProgressStore
    let activity: BoardActivity
    let onSelect: (LevelAddress) -> Void

    @State private var difficulty: BoardDifficulty = .easy

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Levels")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Picker("Difficulty", selection: $difficulty) {
                    ForEach(BoardDifficulty.allCases, id: \.self) { item in
                        Text(item.displayTitle).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(4)
                .background(AppDepthChrome.softInsetWell(cornerRadius: 14))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 158), spacing: 14)], spacing: 14) {
                    ForEach(0..<LevelAddress.stagesPerDifficulty, id: \.self) { index in
                        let address = LevelAddress(activity: activity, difficulty: difficulty, index: index)
                        LevelTile(address: address, activity: activity) {
                            if store.isUnlocked(address) {
                                onSelect(address)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Level tile

private struct LevelTilePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

private struct LevelTile: View {
    @EnvironmentObject private var store: GameProgressStore
    let address: LevelAddress
    let activity: BoardActivity
    let onTap: () -> Void

    private var unlocked: Bool {
        store.isUnlocked(address)
    }

    private var stars: Int {
        store.stars(for: address)
    }

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                LevelTileBezel(difficulty: address.difficulty, unlocked: unlocked)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top, spacing: 10) {
                        LevelStageBadge(
                            stage: address.index + 1,
                            difficulty: address.difficulty,
                            unlocked: unlocked
                        )

                        Spacer(minLength: 4)

                        LevelMiniBoardPreview(difficulty: address.difficulty, activity: activity)
                            .frame(width: 52, height: 52)
                            .opacity(unlocked ? 1 : 0.45)

                        LevelLockCapsule(unlocked: unlocked)
                    }

                    Spacer(minLength: 10)

                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { i in
                            LevelStarJewel(filled: i < stars)
                                .frame(width: 24, height: 24)
                        }
                    }

                    Text(unlocked ? "Tap to play" : "Locked")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(unlocked ? Color.appAccent : Color.appTextSecondary)
                        .padding(.top, 8)
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            }
        }
        .buttonStyle(LevelTilePressStyle())
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.72)
    }
}

// MARK: - Bezel & chrome

private struct LevelTileBezel: View {
    let difficulty: BoardDifficulty
    let unlocked: Bool

    private var rimColors: [Color] {
        switch difficulty {
        case .easy:
            return [Color.appAccent.opacity(0.55), Color.appPrimary.opacity(0.35)]
        case .normal:
            return [Color.appPrimary.opacity(0.75), Color.appAccent.opacity(0.45)]
        case .hard:
            return [Color.appPrimary, Color.appAccent.opacity(0.6)]
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(unlocked ? 1 : 0.72),
                            Color.appBackground.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: rimColors, startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: unlocked ? 2 : 1
                )

            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .strokeBorder(Color.appTextPrimary.opacity(0.06), lineWidth: 1)
                .padding(5)

            if !unlocked {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.appBackground.opacity(0.38))

                LevelFrostHatch()
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
        .shadow(color: unlocked ? Color.appPrimary.opacity(0.28) : Color.clear, radius: 14, y: 6)
        .shadow(color: unlocked ? Color.appAccent.opacity(0.12) : Color.clear, radius: 6, y: 3)
    }
}

private struct LevelFrostHatch: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 7
            var p = Path()
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                x += step
            }
            context.stroke(p, with: .color(Color.appTextSecondary.opacity(0.2)), style: StrokeStyle(lineWidth: 1, lineCap: .round))
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Stage badge

private struct LevelStageBadge: View {
    let stage: Int
    let difficulty: BoardDifficulty
    let unlocked: Bool

    private var badgeGradient: [Color] {
        switch difficulty {
        case .easy:
            return [Color.appAccent.opacity(0.9), Color.appPrimary.opacity(0.75)]
        case .normal:
            return [Color.appPrimary, Color.appAccent.opacity(0.85)]
        case .hard:
            return [Color.appPrimary, Color.appPrimary.opacity(0.55)]
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(colors: badgeGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .overlay(
                    Circle()
                        .strokeBorder(Color.appTextPrimary.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(unlocked ? 0.35 : 0), radius: 6, y: 2)

            Text("\(stage)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.appBackground)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: 46, height: 46)
    }
}

// MARK: - Mini board

private struct LevelMiniBoardPreview: View {
    let difficulty: BoardDifficulty
    let activity: BoardActivity

    private var grid: Int {
        switch difficulty {
        case .easy: return 3
        case .normal: return 4
        case .hard: return 5
        }
    }

    var body: some View {
        Canvas { context, size in
            let n = CGFloat(grid)
            let cell = min(size.width, size.height) / n
            let inset: CGFloat = 2

            let board = Path(roundedRect: CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2), cornerRadius: 8)
            context.fill(board, with: .color(Color.appBackground.opacity(0.55)))
            context.stroke(board, with: .color(Color.appAccent.opacity(0.4)), lineWidth: 1)

            for r in 0..<grid {
                for c in 0..<grid {
                    let rect = CGRect(
                        x: inset + CGFloat(c) * cell + 1,
                        y: inset + CGFloat(r) * cell + 1,
                        width: cell - 2 * inset - 1,
                        height: cell - 2 * inset - 1
                    )
                    let cellPath = Path(roundedRect: rect, cornerRadius: 3)
                    let lit = highlightCell(row: r, col: c, grid: grid, activity: activity, difficulty: difficulty)
                    context.fill(
                        cellPath,
                        with: .color(lit ? Color.appPrimary.opacity(0.55) : Color.appSurface.opacity(0.9))
                    )
                    context.stroke(cellPath, with: .color(Color.appAccent.opacity(0.25)), lineWidth: 0.5)
                }
            }

            let token = Path(ellipseIn: CGRect(x: size.width * 0.58, y: size.height * 0.12, width: 8, height: 8))
            context.fill(token, with: .color(Color.appAccent))
            context.stroke(token, with: .color(Color.appPrimary), lineWidth: 1)
        }
    }

    private func highlightCell(row: Int, col: Int, grid: Int, activity: BoardActivity, difficulty: BoardDifficulty) -> Bool {
        let tier: Int
        switch difficulty {
        case .easy: tier = 1
        case .normal: tier = 2
        case .hard: tier = 3
        }
        let seed = tier &+ row &+ col
        switch activity {
        case .tileTactics:
            return (row + col + seed) % 3 == 0
        case .pathfinder:
            return row == col || row + col == grid - 1
        case .strategicStacks:
            return row >= grid - 2
        }
    }
}

// MARK: - Lock capsule

private struct LevelLockCapsule: View {
    let unlocked: Bool

    var body: some View {
        HStack(spacing: 4) {
            LockGlyph(open: unlocked)
                .frame(width: 16, height: 16)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.appBackground.opacity(0.45))
                .overlay(
                    Capsule()
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - Star jewel

private struct LevelStarJewel: View {
    let filled: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 * 0.88
            var star = Path()
            for i in 0..<10 {
                let angle = CGFloat(i) * .pi / 5 - .pi / 2
                let r = i.isMultiple(of: 2) ? radius : radius * 0.42
                let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
                if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
            }
            star.closeSubpath()

            if filled {
                context.addFilter(.shadow(color: Color.appAccent.opacity(0.55), radius: 3, x: 0, y: 0))
            }
            context.fill(star, with: .color(filled ? Color.appPrimary : Color.appSurface))
            context.stroke(star, with: .color(filled ? Color.appAccent : Color.appTextSecondary.opacity(0.45)), lineWidth: 1.2)
        }
    }
}

private struct LockGlyph: View {
    let open: Bool

    var body: some View {
        Canvas { context, size in
            let bodyRect = CGRect(x: size.width * 0.28, y: size.height * 0.42, width: size.width * 0.44, height: size.height * 0.46)
            var shackle = Path()
            shackle.addRoundedRect(
                in: CGRect(x: size.width * 0.22, y: size.height * 0.18, width: size.width * 0.56, height: size.height * 0.38),
                cornerSize: CGSize(width: 10, height: 10)
            )
            context.stroke(shackle, with: .color(Color.appAccent), lineWidth: 2)
            context.fill(Path(roundedRect: bodyRect, cornerRadius: 6), with: .color(open ? Color.appPrimary.opacity(0.35) : Color.appSurface))
            context.stroke(Path(roundedRect: bodyRect, cornerRadius: 6), with: .color(Color.appPrimary), lineWidth: 2)
        }
    }
}
