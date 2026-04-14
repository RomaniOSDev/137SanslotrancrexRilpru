import SwiftUI

struct ActivityResultView: View {
    @EnvironmentObject private var store: GameProgressStore
    @Binding var path: NavigationPath
    let outcome: ActivityOutcome

    @State private var visibleStars = 0
    @State private var showAchievementBanner = false

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("Results")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 18) {
                    ForEach(0..<3, id: \.self) { index in
                        ResultStarSlot(
                            index: index,
                            earnedCount: outcome.starsEarned,
                            visible: visibleStars
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    statRow(title: "Time", value: formattedDuration(outcome.durationSeconds))
                    statRow(title: "Moves", value: "\(outcome.moves)")
                    statRow(title: "Accuracy", value: "\(Int((outcome.accuracyRatio * 100).rounded()))%")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.appSurface.opacity(0.98), Color.appBackground.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                    }
                    .shadow(color: Color.appPrimary.opacity(0.12), radius: 12, x: 0, y: 6)
                )

                VStack(spacing: 12) {
                    Button {
                        goNext()
                    } label: {
                        Text("Next level")
                    }
                    .boardPrimaryButton()
                    .disabled(nextLevel == nil)

                    Button {
                        retry()
                    } label: {
                        Text("Retry")
                    }
                    .boardSecondaryButton()

                    Button {
                        backToLevels()
                    } label: {
                        Text("Back to levels")
                    }
                    .boardSecondaryButton()
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .top) {
            if showAchievementBanner {
                achievementBanner
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showAchievementBanner)
        .onAppear {
            animateStars()
            if !outcome.newAchievementIds.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                        showAchievementBanner = true
                    }
                }
            }
        }
    }

    private var nextLevel: LevelAddress? {
        guard let candidate = LevelAddress.next(after: outcome.level) else { return nil }
        if store.isUnlocked(candidate) {
            return candidate
        }
        return nil
    }

    private var achievementBanner: some View {
        let titles = outcome.newAchievementIds.compactMap { id in
            store.achievements.first { $0.id == id }?.title
        }
        return VStack(alignment: .leading, spacing: 6) {
            Text("New achievement")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)
            Text(titles.joined(separator: ", "))
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.98), Color.appPrimary.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.appAccent.opacity(0.35), radius: 14, y: 7)
            .shadow(color: Color.appPrimary.opacity(0.15), radius: 6, y: 3)
        )
        .padding(.horizontal, 16)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appTextSecondary)
            Spacer()
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.appTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func animateStars() {
        visibleStars = 0
        for index in 0..<outcome.starsEarned {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                    visibleStars = index + 1
                }
            }
        }
    }

    private func popSummary() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    private func goNext() {
        popSummary()
        if let next = nextLevel {
            path.append(PlayStack.game(next))
        }
    }

    private func retry() {
        popSummary()
        path.append(PlayStack.game(outcome.level))
    }

    private func backToLevels() {
        popSummary()
    }
}

private struct ResultStarSlot: View {
    let index: Int
    let earnedCount: Int
    let visible: Int

    private var earned: Bool {
        index < earnedCount
    }

    var body: some View {
        StarGlyphView(
            filled: earned,
            glow: earned && index < visible
        )
        .frame(width: 64, height: 64)
        .scaleEffect(earned ? (index < visible ? 1 : 0.78) : 0.65)
        .opacity(earned ? (index < visible ? 1 : 0.45) : 0.25)
        .animation(
            .spring(response: 0.45, dampingFraction: 0.78),
            value: visible
        )
    }
}
