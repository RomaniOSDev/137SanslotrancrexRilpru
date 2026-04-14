import SwiftUI

struct StrategicStacksView: View {
    @StateObject private var model: StrategicStacksViewModel
    let onComplete: (ActivityOutcome) -> Void

    @State private var selected: StackCard?

    init(address: LevelAddress, onComplete: @escaping (ActivityOutcome) -> Void) {
        _model = StateObject(wrappedValue: StrategicStacksViewModel(address: address))
        self.onComplete = onComplete
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Strategic Stacks")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Pick a value, then tap the stack to place it. Reach the target sum using every card.")
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)

                targetPanel

                stackPanel

                handPanel

                HStack(spacing: 12) {
                    Button {
                        model.undoLast()
                    } label: {
                        Text("Undo")
                    }
                    .boardSecondaryButton()

                    Button {
                        model.resetBoard()
                        selected = nil
                    } label: {
                        Text("Reset")
                    }
                    .boardSecondaryButton()

                    Button {
                        if let outcome = model.evaluateOutcome() {
                            onComplete(outcome)
                        }
                    } label: {
                        Text("Check stack")
                    }
                    .boardPrimaryButton()
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var targetPanel: some View {
        HStack {
            Text("Target sum")
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text("\(model.target)")
                .font(.title.weight(.bold))
                .foregroundStyle(Color.appPrimary)
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.98), Color.appPrimary.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(0.14), radius: 10, x: 0, y: 5)
        )
    }

    private var stackPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Active stack")
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                Spacer()
                Text("Current: \(model.currentSum)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appAccent)
            }

            Button {
                guard let card = selected else { return }
                model.place(card)
                selected = nil
                if let outcome = model.evaluateOutcome() {
                    onComplete(outcome)
                }
            } label: {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.appSurface.opacity(0.75),
                                            Color.appBackground.opacity(0.5)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .frame(minHeight: 160)
                        .shadow(color: Color.appPrimary.opacity(0.12), radius: 12, x: 0, y: 6)

                    VStack(spacing: 8) {
                        ForEach(model.stack) { card in
                            CardGlyph(value: card.value, tint: card.tint)
                                .frame(height: 44)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        if model.stack.isEmpty {
                            Text(selected == nil ? "Tap a card, then tap here" : "Drop selected card here")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.bottom, 12)
                        }
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: model.stack)
        }
    }

    private var handPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hand")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                ForEach(model.hand) { card in
                    Button {
                        selected = card
                    } label: {
                        CardGlyph(value: card.value, tint: card.tint)
                            .frame(height: 64)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        selected?.id == card.id ? Color.appPrimary : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Value \(card.value)")
                }
            }
        }
    }
}

private struct CardGlyph: View {
    let value: Int
    let tint: Int

    private var fill: Color {
        let palette: [Color] = [
            Color.appPrimary.opacity(0.9),
            Color.appAccent.opacity(0.9),
            Color.appTextPrimary.opacity(0.9),
            Color.appTextSecondary.opacity(0.9)
        ]
        return palette[tint % palette.count]
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [fill.opacity(1), fill.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.appAccent, lineWidth: 2)
                )
                .shadow(color: Color.appPrimary.opacity(0.2), radius: 6, x: 0, y: 3)
            Text("\(value)")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.appBackground)
        }
    }
}
