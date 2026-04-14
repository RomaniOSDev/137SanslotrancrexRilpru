import SwiftUI

struct OnboardingView: View {
    @Binding var page: Int
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            AppDepthChrome.screenBackdrop
                .ignoresSafeArea()

            OnboardingAmbientGlow()
                .allowsHitTesting(false)
                .ignoresSafeArea()

            TabView(selection: $page) {
                OnboardingStrategicPage()
                    .tag(0)
                OnboardingTouchPage()
                    .tag(1)
                OnboardingStarsPage(onBegin: onFinish)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Ambient layer

private struct OnboardingAmbientGlow: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appPrimary.opacity(0.18), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 140
                    )
                )
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -180)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.appAccent.opacity(0.14), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 120)
        }
    }
}

// MARK: - Shared chrome

private struct OnboardingPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.95), Color.appPrimary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 48, height: 5)

            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.appTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(Color.appTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OnboardingIllustrationCard<Content: View>: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(20)
            .background(AppDepthChrome.raisedPanel(cornerRadius: cornerRadius))
    }
}

// MARK: - Pages

private struct OnboardingStrategicPage: View {
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                OnboardingPageHeader(
                    title: "Plan each step",
                    subtitle: "Every layout rewards calm thinking and careful order."
                )

                OnboardingIllustrationCard(height: 268, cornerRadius: 24) {
                    BoardGridPreview(rows: 4, cols: 4, pulse: pulse)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulse.toggle()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingTouchPage: View {
    @State private var tilt = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                OnboardingPageHeader(
                    title: "Move pieces with intent",
                    subtitle: "Drag paths, place tiles, and stack cards using natural gestures."
                )

                OnboardingIllustrationCard(height: 268, cornerRadius: 24) {
                    TouchArcPreview(tilt: tilt)
                }
                .onAppear {
                    withAnimation(.spring(response: 0.9, dampingFraction: 0.65).repeatForever(autoreverses: true)) {
                        tilt.toggle()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingStarsPage: View {
    let onBegin: () -> Void
    @State private var wave = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                OnboardingPageHeader(
                    title: "Earn up to three stars",
                    subtitle: "Sharper play unlocks new boards and fresh challenges."
                )

                OnboardingIllustrationCard(height: 232, cornerRadius: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.appBackground.opacity(0.4),
                                        Color.appSurface.opacity(0.55)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.appAccent.opacity(0.2), lineWidth: 1)
                            )

                        HStack(spacing: 22) {
                            ForEach(0..<3, id: \.self) { index in
                                StarGlyphView(filled: true, glow: wave)
                                    .frame(width: 58, height: 58)
                                    .scaleEffect(wave ? 1.06 : 0.9)
                                    .shadow(color: Color.appPrimary.opacity(0.25), radius: wave ? 12 : 4, x: 0, y: 4)
                                    .animation(
                                        .spring(response: 0.45, dampingFraction: 0.78).delay(Double(index) * 0.08),
                                        value: wave
                                    )
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                        wave.toggle()
                    }
                }

                Button(action: onBegin) {
                    Text("Begin")
                }
                .boardPrimaryButton()
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
        }
        .scrollContentBackground(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

private struct BoardGridPreview: View {
    let rows: Int
    let cols: Int
    let pulse: Bool

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: cols)
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<rows, id: \.self) { r in
                ForEach(0..<cols, id: \.self) { c in
                    let active = (r + c).isMultiple(of: 2) == pulse
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: active
                                    ? [
                                        Color.appPrimary.opacity(0.48),
                                        Color.appPrimary.opacity(0.22)
                                    ]
                                    : [
                                        Color.appAccent.opacity(0.2),
                                        Color.appSurface.opacity(0.75)
                                    ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.appAccent.opacity(active ? 0.55 : 0.35), lineWidth: 1)
                        )
                        .shadow(color: Color.appTextPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
    }
}

private struct TouchArcPreview: View {
    let tilt: Bool

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 20, y: size.height * 0.65))
            path.addQuadCurve(
                to: CGPoint(x: size.width - 20, y: size.height * 0.35),
                control: CGPoint(x: size.width * 0.5, y: tilt ? size.height * 0.2 : size.height * 0.85)
            )

            context.stroke(
                path,
                with: .color(Color.appPrimary.opacity(0.22)),
                style: StrokeStyle(lineWidth: 14, lineCap: .round, lineJoin: .round)
            )
            context.stroke(
                path,
                with: .linearGradient(
                    Gradient(colors: [Color.appPrimary, Color.appAccent.opacity(0.9)]),
                    startPoint: CGPoint(x: 20, y: size.height * 0.65),
                    endPoint: CGPoint(x: size.width - 20, y: size.height * 0.35)
                ),
                style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
            )

            let knob = CGRect(x: size.width * 0.72 - 16, y: size.height * 0.42 - 16, width: 32, height: 32)
            let knobPath = Path(ellipseIn: knob)
            context.fill(
                knobPath,
                with: .radialGradient(
                    Gradient(colors: [Color.appAccent, Color.appPrimary.opacity(0.75)]),
                    center: CGPoint(x: knob.midX, y: knob.midY),
                    startRadius: 0,
                    endRadius: 18
                )
            )
            context.stroke(knobPath, with: .color(Color.appTextPrimary.opacity(0.35)), lineWidth: 2)
            context.stroke(knobPath, with: .color(Color.appPrimary.opacity(0.6)), lineWidth: 1)
        }
    }
}

struct OnboardingContainer: View {
    @ObservedObject var store: GameProgressStore
    @State private var page = 0

    var body: some View {
        OnboardingView(page: $page) {
            store.markOnboardingSeen()
        }
    }
}
