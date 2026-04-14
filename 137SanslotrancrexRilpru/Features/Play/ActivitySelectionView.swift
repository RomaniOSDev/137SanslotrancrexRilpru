import SwiftUI

struct ActivitySelectionView: View {
    let onSelect: (BoardActivity) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose an activity")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Each path offers its own rhythm of moves and goals.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                VStack(spacing: 16) {
                    ForEach(BoardActivity.allCases, id: \.self) { activity in
                        Button {
                            onSelect(activity)
                        } label: {
                            HStack(spacing: 16) {
                                ActivityGlyph(activity: activity)
                                    .frame(width: 56, height: 56)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.displayTitle)
                                        .font(.headline)
                                        .foregroundStyle(Color.appTextPrimary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                    Text(subtitle(for: activity))
                                        .font(.subheadline)
                                        .foregroundStyle(Color.appTextSecondary)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.7)
                                }
                                Spacer(minLength: 8)
                                ChevronGlyph()
                                    .frame(width: 18, height: 18)
                            }
                            .padding(16)
                            .frame(minHeight: 44)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.appSurface.opacity(0.98),
                                                    Color.appSurface.opacity(0.82),
                                                    Color.appBackground.opacity(0.4)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.appAccent.opacity(0.35), Color.appPrimary.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                                .shadow(color: Color.appPrimary.opacity(0.14), radius: 12, x: 0, y: 6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func subtitle(for activity: BoardActivity) -> String {
        switch activity {
        case .tileTactics:
            return "Slide pieces to match the pattern."
        case .pathfinder:
            return "Trace a clean route between markers."
        case .strategicStacks:
            return "Stack values to hit the target height."
        }
    }
}

private struct ChevronGlyph: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 4, y: 4))
            path.addLine(to: CGPoint(x: size.width - 4, y: size.height / 2))
            path.addLine(to: CGPoint(x: 4, y: size.height - 4))
            context.stroke(path, with: .color(Color.appAccent), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

private struct ActivityGlyph: View {
    let activity: BoardActivity

    var body: some View {
        Canvas { context, size in
            switch activity {
            case .tileTactics:
                let step = min(size.width, size.height) / 3
                for r in 0..<3 {
                    for c in 0..<3 {
                        let rect = CGRect(x: CGFloat(c) * step + 2, y: CGFloat(r) * step + 2, width: step - 4, height: step - 4)
                        let path = Path(roundedRect: rect, cornerRadius: 4)
                        context.fill(path, with: .color(Color.appPrimary.opacity(0.35)))
                        context.stroke(path, with: .color(Color.appAccent), lineWidth: 1.5)
                    }
                }
            case .pathfinder:
                var route = Path()
                route.move(to: CGPoint(x: 8, y: size.height - 10))
                route.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.55))
                route.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.35))
                route.addLine(to: CGPoint(x: size.width - 8, y: 10))
                context.stroke(route, with: .color(Color.appPrimary), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                context.fill(Path(ellipseIn: CGRect(x: 4, y: 4, width: 10, height: 10)), with: .color(Color.appAccent))
                context.fill(Path(ellipseIn: CGRect(x: size.width - 14, y: size.height - 14, width: 10, height: 10)), with: .color(Color.appAccent))
            case .strategicStacks:
                let widths: [CGFloat] = [0.75, 0.6, 0.45]
                var y = size.height - 10
                for w in widths {
                    let rect = CGRect(x: (size.width - size.width * w) / 2, y: y - 14, width: size.width * w, height: 14)
                    let path = Path(roundedRect: rect, cornerRadius: 3)
                    context.fill(path, with: .color(Color.appPrimary.opacity(0.45)))
                    context.stroke(path, with: .color(Color.appAccent), lineWidth: 1.2)
                    y -= 18
                }
            }
        }
    }
}
