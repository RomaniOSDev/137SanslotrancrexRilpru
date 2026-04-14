import SwiftUI

private struct BoardFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct TileTacticsView: View {
    @StateObject private var model: TileTacticsViewModel
    let onComplete: (ActivityOutcome) -> Void

    @State private var boardFrame: CGRect = .zero
    @State private var selectedChipId: UUID?
    @State private var draggingSymbol: Int?
    @State private var dragLocation: CGPoint = .zero
    @State private var isDraggingFromTray = false
    @State private var didReportWin = false

    init(address: LevelAddress, onComplete: @escaping (ActivityOutcome) -> Void) {
        _model = StateObject(wrappedValue: TileTacticsViewModel(address: address))
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if model.mirrorHint {
                    Text("Mirror symmetry shapes the goal layout.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }

                board
                    .appDepthBoardChrome(cornerRadius: 22, contentInset: 10)

                tray

                Button {
                    model.resetBoard()
                    selectedChipId = nil
                } label: {
                    Text("Reset board")
                }
                .boardSecondaryButton()
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .scrollDisabled(isDraggingFromTray)
        .appDepthScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .onPreferenceChange(BoardFrameKey.self) { boardFrame = $0 }
        .onChange(of: model.moves) { _ in
            finalizeIfNeeded()
        }
        .onChange(of: model.trayChips.count) { _ in
            finalizeIfNeeded()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tile Tactics")
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
            Text("Tap a chip in the tray, then tap a cell — or drag a chip onto the board. Long press a placed chip to return it.")
                .font(.subheadline)
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var board: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(model.cols)
            let cellH = geo.size.height / CGFloat(model.rows)

            ZStack {
                ForEach(0..<model.rows, id: \.self) { r in
                    ForEach(0..<model.cols, id: \.self) { c in
                        let cell = TileCell(row: r, col: c)
                        cellView(cell: cell, size: CGSize(width: cellW, height: cellH))
                            .position(
                                x: CGFloat(c) * cellW + cellW / 2,
                                y: CGFloat(r) * cellH + cellH / 2
                            )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: BoardFrameKey.self,
                        value: proxy.frame(in: .global)
                    )
                }
            )
        }
        .aspectRatio(CGFloat(model.cols) / CGFloat(model.rows), contentMode: .fit)
    }

    private func cellView(cell: TileCell, size: CGSize) -> some View {
        let blocked = model.isBlocked(cell)
        let expected = model.symbol(at: cell)

        return ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: blocked
                            ? [Color.appSurface.opacity(0.32), Color.appBackground.opacity(0.25)]
                            : [Color.appSurface.opacity(0.98), Color.appSurface.opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.appTextPrimary.opacity(blocked ? 0 : 0.04), radius: 2, x: 0, y: 1)

            if blocked {
                DiagonalStrike()
            } else if let sym = expected {
                TargetGlyph(symbol: sym, rotation: model.requiresRotation ? model.targetRotations[cell.row][cell.col] : 0, faint: true)
                    .padding(10)
            }

            if let placed = model.placements[cell] {
                TileGlyph(symbol: placed.symbol, rotation: placed.rotation)
                    .padding(8)
                    .overlay(alignment: .topTrailing) {
                        if model.requiresRotation {
                            Circle()
                                .strokeBorder(Color.appAccent.opacity(0.65), lineWidth: 2)
                                .frame(width: 18, height: 18)
                                .padding(4)
                        }
                    }
            }
        }
        .frame(width: size.width - 6, height: size.height - 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if let chipID = selectedChipId {
                model.placeChip(id: chipID, at: cell)
                selectedChipId = nil
                finalizeIfNeeded()
            } else if model.placements[cell] != nil, model.requiresRotation {
                model.rotatePlacedTile(at: cell)
                finalizeIfNeeded()
            }
        }
        .onLongPressGesture {
            model.removePlaced(at: cell)
        }
    }

    private var tray: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tray")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                if selectedChipId != nil {
                    Text("Selected — tap a cell")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 10)], spacing: 10) {
                ForEach(model.trayChips) { chip in
                    let isSelected = selectedChipId == chip.id
                    TileGlyph(symbol: chip.symbol, rotation: 0)
                        .frame(height: 64)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.appSurface.opacity(0.95), Color.appBackground.opacity(0.35)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(
                                    isSelected ? Color.appPrimary : Color.appPrimary.opacity(0.35),
                                    lineWidth: isSelected ? 3 : 1
                                )
                        )
                        .shadow(color: Color.appPrimary.opacity(isSelected ? 0.22 : 0.08), radius: isSelected ? 8 : 4, x: 0, y: 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedChipId = selectedChipId == chip.id ? nil : chip.id
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 10, coordinateSpace: .global)
                                .onChanged { value in
                                    if !isDraggingFromTray {
                                        isDraggingFromTray = true
                                    }
                                    draggingSymbol = chip.symbol
                                    dragLocation = value.location
                                }
                                .onEnded { value in
                                    isDraggingFromTray = false
                                    let point = value.location
                                    if let targetCell = cell(for: point) {
                                        model.placeChip(id: chip.id, at: targetCell)
                                        selectedChipId = nil
                                        finalizeIfNeeded()
                                    }
                                    draggingSymbol = nil
                                }
                        )
                }
            }
        }
        .overlay {
            if let symbol = draggingSymbol {
                TileGlyph(symbol: symbol, rotation: 0)
                    .frame(width: 72, height: 72)
                    .position(dragLocation)
                    .allowsHitTesting(false)
            }
        }
    }

    private func cell(for globalPoint: CGPoint) -> TileCell? {
        guard boardFrame.width > 1, boardFrame.height > 1 else { return nil }
        guard globalPoint.x >= boardFrame.minX,
              globalPoint.x <= boardFrame.maxX,
              globalPoint.y >= boardFrame.minY,
              globalPoint.y <= boardFrame.maxY else { return nil }

        let localX = globalPoint.x - boardFrame.minX
        let localY = globalPoint.y - boardFrame.minY
        let cellW = boardFrame.width / CGFloat(model.cols)
        let cellH = boardFrame.height / CGFloat(model.rows)
        let col = Int(localX / cellW)
        let row = Int(localY / cellH)
        guard row >= 0, row < model.rows, col >= 0, col < model.cols else { return nil }
        return TileCell(row: row, col: col)
    }

    private func finalizeIfNeeded() {
        guard !didReportWin else { return }
        guard let outcome = model.computeOutcomeIfSolved() else { return }
        didReportWin = true
        onComplete(outcome)
    }
}

private struct TileGlyph: View {
    let symbol: Int
    let rotation: Int

    var body: some View {
        Canvas { context, size in
            let palette: [Color] = [
                Color.appPrimary,
                Color.appAccent,
                Color.appTextPrimary,
                Color.appTextSecondary
            ]
            let base = palette[symbol % palette.count]
            let rect = CGRect(x: 6, y: 6, width: size.width - 12, height: size.height - 12)
            let path = Path(roundedRect: rect, cornerRadius: 8)
            context.fill(path, with: .color(base.opacity(0.85)))
            context.stroke(path, with: .color(Color.appAccent), lineWidth: 2)

            var diamond = Path()
            diamond.move(to: CGPoint(x: size.width / 2, y: 10))
            diamond.addLine(to: CGPoint(x: size.width - 10, y: size.height / 2))
            diamond.addLine(to: CGPoint(x: size.width / 2, y: size.height - 10))
            diamond.addLine(to: CGPoint(x: 10, y: size.height / 2))
            diamond.closeSubpath()
            context.stroke(diamond, with: .color(Color.appBackground.opacity(0.35)), lineWidth: 1.5)
        }
        .rotationEffect(.degrees(Double(rotation) * 90))
    }
}

private struct TargetGlyph: View {
    let symbol: Int
    let rotation: Int
    let faint: Bool

    var body: some View {
        TileGlyph(symbol: symbol, rotation: rotation)
            .opacity(faint ? 0.22 : 1)
    }
}

private struct DiagonalStrike: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 6, y: 6))
            path.addLine(to: CGPoint(x: size.width - 6, y: size.height - 6))
            path.move(to: CGPoint(x: size.width - 6, y: 6))
            path.addLine(to: CGPoint(x: 6, y: size.height - 6))
            context.stroke(path, with: .color(Color.appTextSecondary.opacity(0.6)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
    }
}
