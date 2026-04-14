import SwiftUI

struct PathfinderView: View {
    @StateObject private var model: PathfinderViewModel
    let onComplete: (ActivityOutcome) -> Void

    @State private var isDrawingPath = false

    init(address: LevelAddress, onComplete: @escaping (ActivityOutcome) -> Void) {
        _model = StateObject(wrappedValue: PathfinderViewModel(address: address))
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pathfinder Puzzle")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Drag through adjacent cells, or tap cells one by one from the start marker. Tap the previous cell to undo a step.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                board
                    .appDepthBoardChrome(cornerRadius: 22, contentInset: 10)

                HStack(spacing: 12) {
                    Button {
                        model.resetPath()
                    } label: {
                        Text("Clear")
                    }
                    .boardSecondaryButton()

                    Button {
                        if let outcome = model.evaluateOutcome() {
                            onComplete(outcome)
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                model.isPathInvalid = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                model.clearIfInvalid()
                            }
                        }
                    } label: {
                        Text("Confirm route")
                    }
                    .boardPrimaryButton()
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(isDrawingPath)
        .appDepthScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var board: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(model.cols)
            let cellH = geo.size.height / CGFloat(model.rows)
            let boardSize = geo.size

            ZStack {
                ForEach(0..<model.rows, id: \.self) { r in
                    ForEach(0..<model.cols, id: \.self) { c in
                        let point = GridPoint(row: r, col: c)
                        cell(point: point, size: CGSize(width: cellW, height: cellH))
                            .position(x: CGFloat(c) * cellW + cellW / 2, y: CGFloat(r) * cellH + cellH / 2)
                    }
                }

                PathShape(path: model.path, cols: model.cols, rows: model.rows)
                    .stroke(
                        model.isPathInvalid ? Color.appTextSecondary : Color.appPrimary,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    )
                    .animation(.easeInOut(duration: 0.18), value: model.path)
                    .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        isDrawingPath = true
                        if let cell = cellFromLocalPoint(value.location, boardSize: boardSize) {
                            model.handleDrag(to: cell)
                        }
                    }
                    .onEnded { _ in
                        isDrawingPath = false
                    }
            )
        }
        .aspectRatio(CGFloat(model.cols) / CGFloat(model.rows), contentMode: .fit)
    }

    private func cellFromLocalPoint(_ point: CGPoint, boardSize: CGSize) -> GridPoint? {
        guard boardSize.width > 1, boardSize.height > 1 else { return nil }
        guard point.x >= 0, point.y >= 0, point.x <= boardSize.width, point.y <= boardSize.height else { return nil }

        let cellW = boardSize.width / CGFloat(model.cols)
        let cellH = boardSize.height / CGFloat(model.rows)
        let col = min(model.cols - 1, max(0, Int(point.x / cellW)))
        let row = min(model.rows - 1, max(0, Int(point.y / cellH)))
        return GridPoint(row: row, col: col)
    }

    private func cell(point: GridPoint, size: CGSize) -> some View {
        let isWall = model.walls.contains(point)
        let isStart = point == model.start
        let isEnd = point == model.end
        let onPath = model.path.contains(point)

        return ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isWall
                            ? [Color.appSurface.opacity(0.42), Color.appBackground.opacity(0.35)]
                            : [Color.appSurface.opacity(0.96), Color.appSurface.opacity(0.68)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(
                            onPath ? Color.appAccent.opacity(0.55) : Color.appAccent.opacity(0.2),
                            lineWidth: onPath ? 2 : 1
                        )
                )
                .shadow(color: Color.appTextPrimary.opacity(isWall ? 0 : 0.035), radius: 1, x: 0, y: 1)

            if isWall {
                WallGlyph()
            }

            if isStart || isEnd {
                Circle()
                    .fill(Color.appAccent.opacity(0.85))
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.appPrimary, lineWidth: 2)
                    )
            }
        }
        .frame(width: size.width - 4, height: size.height - 4)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isWall else { return }
            model.handleDrag(to: point)
        }
    }
}

private struct PathShape: Shape {
    let path: [GridPoint]
    let cols: Int
    let rows: Int

    func path(in rect: CGRect) -> Path {
        var result = Path()
        guard !path.isEmpty else { return result }
        let cellW = rect.width / CGFloat(cols)
        let cellH = rect.height / CGFloat(rows)

        func center(for point: GridPoint) -> CGPoint {
            CGPoint(
                x: CGFloat(point.col) * cellW + cellW / 2,
                y: CGFloat(point.row) * cellH + cellH / 2
            )
        }

        result.move(to: center(for: path[0]))
        for step in path.dropFirst() {
            result.addLine(to: center(for: step))
        }
        return result
    }
}

private struct WallGlyph: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 6, y: 6))
            path.addLine(to: CGPoint(x: size.width - 6, y: size.height - 6))
            context.stroke(path, with: .color(Color.appTextSecondary.opacity(0.7)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
