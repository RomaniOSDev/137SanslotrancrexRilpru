import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: GameProgressStore
    @Binding var selectedTab: AppShellTab

    private var maxPossibleStars: Int {
        BoardActivity.allCases.count * LevelAddress.totalProgressionSteps * 3
    }

    private var starProgress: Double {
        guard maxPossibleStars > 0 else { return 0 }
        return min(1, Double(store.totalStarsCollected) / Double(maxPossibleStars))
    }

    private var focusHint: String {
        if let line = nextOpenStageLine() {
            return line
        }
        if store.completedLevelsCount >= LevelAddress.totalProgressionSteps * BoardActivity.allCases.count {
            return "You have cleared every listed stage. Replay for cleaner stars."
        }
        return "Choose an activity in Play to open the level grid."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero

                statsRow

                progressCard

                focusCard

                shortcutsSection

                tipFooter
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
    }

    // MARK: - Sections

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            HomeHeroBackdrop()
                .frame(height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Board home")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)

                Text("Plan routes, place pieces, and stack values in one calm hub.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.85)
            }
            .padding(22)
        }
        .shadow(color: Color.appPrimary.opacity(0.22), radius: 18, x: 0, y: 10)
        .shadow(color: Color.appTextPrimary.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            HomeStatChip(
                title: "Stars",
                value: "\(store.totalStarsCollected)",
                caption: "Across all boards"
            )
            HomeStatChip(
                title: "Cleared",
                value: "\(store.completedLevelsCount)",
                caption: "Stages with a win"
            )
            HomeStatChip(
                title: "Time",
                value: formatShortTime(store.totalPlaySeconds),
                caption: "In sessions"
            )
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collection")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.appSurface)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appAccent.opacity(0.9), Color.appPrimary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * starProgress))
                        .animation(.easeInOut(duration: 0.35), value: starProgress)
                }
            }
            .frame(height: 14)

            Text("\(store.totalStarsCollected) / \(maxPossibleStars) stars available in the catalog.")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.appSurface.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.14), radius: 12, x: 0, y: 6)
        )
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label {
                Text("Suggested next step")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            } icon: {
                HomeSparkGlyph()
                    .frame(width: 22, height: 22)
            }

            Text(focusHint)
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    selectedTab = .play
                }
            } label: {
                Text("Open Play")
            }
            .boardPrimaryButton()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface,
                            Color.appBackground.opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.appPrimary.opacity(0.35), lineWidth: 1.5)
                )
                .shadow(color: Color.appAccent.opacity(0.18), radius: 14, x: 0, y: 7)
        )
    }

    private var shortcutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activities")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)

            VStack(spacing: 10) {
                ForEach(BoardActivity.allCases, id: \.self) { activity in
                    HomeActivityShortcutRow(activity: activity) {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedTab = .play
                        }
                    }
                }
            }
        }
    }

    private var tipFooter: some View {
        Text("Tip: use Achievements to track milestones, and Profile to review totals or reset progress.")
            .font(.footnote)
            .foregroundStyle(Color.appTextSecondary.opacity(0.95))
            .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func nextOpenStageLine() -> String? {
        for activity in BoardActivity.allCases {
            for level in LevelAddress.progressionOrder(for: activity) {
                guard store.isUnlocked(level) else { continue }
                let earned = store.stars(for: level)
                if earned < 3 {
                    return "\(activity.displayTitle) · \(level.difficulty.displayTitle) · Stage \(level.index + 1)"
                }
            }
        }
        return nil
    }

    private func formatShortTime(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "0m"
    }
}

// MARK: - Hero

private struct HomeHeroBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appSurface,
                    Color.appBackground.opacity(0.95),
                    Color.appSurface.opacity(0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { context, size in
                var wave = Path()
                wave.move(to: CGPoint(x: 0, y: size.height * 0.62))
                wave.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.48),
                    control1: CGPoint(x: size.width * 0.28, y: size.height * 0.38),
                    control2: CGPoint(x: size.width * 0.72, y: size.height * 0.78)
                )
                wave.addLine(to: CGPoint(x: size.width, y: size.height))
                wave.addLine(to: CGPoint(x: 0, y: size.height))
                wave.closeSubpath()
                context.fill(wave, with: .color(Color.appPrimary.opacity(0.12)))

                for i in 0..<6 {
                    let x = CGFloat(i) / 5 * size.width * 0.85 + size.width * 0.08
                    let y = size.height * 0.22 + sin(CGFloat(i) * 0.9) * 10
                    let r: CGFloat = 4 + CGFloat(i % 3) * 2
                    let dot = Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r))
                    context.fill(dot, with: .color(Color.appAccent.opacity(0.35 - Double(i) * 0.04)))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }
}

// MARK: - Stat chip

private struct HomeStatChip: View {
    let title: String
    let value: String
    let caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(caption)
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.appAccent)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.appSurface.opacity(0.95), Color.appSurface.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.appPrimary.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Activity shortcut

private struct HomeActivityShortcutRow: View {
    let activity: BoardActivity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                HomeActivityGlyph(activity: activity)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
                Spacer(minLength: 6)
                HomeShortcutChevron()
                    .frame(width: 12, height: 14)
            }
            .padding(14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.94), Color.appBackground.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.22), lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.12), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        switch activity {
        case .tileTactics:
            return "Patterns, chips, and careful placement."
        case .pathfinder:
            return "Trace clean routes between markers."
        case .strategicStacks:
            return "Stack values toward a precise sum."
        }
    }
}

private struct HomeActivityGlyph: View {
    let activity: BoardActivity

    var body: some View {
        Canvas { context, size in
            switch activity {
            case .tileTactics:
                let step = min(size.width, size.height) / 3.5
                for r in 0..<3 {
                    for c in 0..<3 {
                        let rect = CGRect(
                            x: 4 + CGFloat(c) * step,
                            y: 4 + CGFloat(r) * step,
                            width: step - 4,
                            height: step - 4
                        )
                        let p = Path(roundedRect: rect, cornerRadius: 4)
                        context.fill(p, with: .color(Color.appPrimary.opacity(0.35)))
                        context.stroke(p, with: .color(Color.appAccent.opacity(0.6)), lineWidth: 1)
                    }
                }
            case .pathfinder:
                var route = Path()
                route.move(to: CGPoint(x: 8, y: size.height - 8))
                route.addQuadCurve(
                    to: CGPoint(x: size.width - 8, y: 10),
                    control: CGPoint(x: size.width * 0.45, y: size.height * 0.55)
                )
                context.stroke(route, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                context.fill(Path(ellipseIn: CGRect(x: 4, y: 4, width: 8, height: 8)), with: .color(Color.appAccent))
                context.fill(Path(ellipseIn: CGRect(x: size.width - 12, y: size.height - 12, width: 8, height: 8)), with: .color(Color.appAccent))
            case .strategicStacks:
                var y = size.height - 8
                for w in stride(from: 0.85, through: 0.45, by: -0.2) {
                    let rect = CGRect(
                        x: (size.width - size.width * CGFloat(w)) / 2,
                        y: y - 10,
                        width: size.width * CGFloat(w),
                        height: 10
                    )
                    let p = Path(roundedRect: rect, cornerRadius: 3)
                    context.fill(p, with: .color(Color.appPrimary.opacity(0.45)))
                    context.stroke(p, with: .color(Color.appAccent), lineWidth: 1)
                    y -= 12
                }
            }
        }
    }
}

private struct HomeShortcutChevron: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 2, y: 2))
            path.addLine(to: CGPoint(x: size.width - 2, y: size.height / 2))
            path.addLine(to: CGPoint(x: 2, y: size.height - 2))
            context.stroke(path, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct HomeSparkGlyph: View {
    var body: some View {
        Canvas { context, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            for i in 0..<4 {
                let angle = CGFloat(i) * .pi / 2 - .pi / 4
                var p = Path()
                p.move(to: c)
                p.addLine(to: CGPoint(x: c.x + cos(angle) * size.width * 0.42, y: c.y + sin(angle) * size.height * 0.42))
                context.stroke(p, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            context.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(Color.appAccent))
        }
    }
}
