import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GameProgressStore
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Player insights")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Color.appTextPrimary)

                    Text("Track how much you play and clear data whenever you want a fresh board.")
                        .font(.body)
                        .foregroundStyle(Color.appTextSecondary)

                    VStack(spacing: 12) {
                        statCard(title: "Total stars", value: "\(store.totalStarsCollected)")
                        statCard(title: "Levels cleared", value: "\(store.completedLevelsCount)")
                        statCard(title: "Activities played", value: "\(store.totalActivitiesPlayed)")
                        statCard(title: "Total time", value: formattedDuration(store.totalPlaySeconds))
                        statCard(title: "Total moves", value: "\(store.totalMoves)")
                    }

                    NavigationLink {
                        SettingsView()
                    } label: {
                        profileNavigationRow(title: "Settings", subtitle: "Rate us, privacy, and terms")
                    }

                    Button(role: .destructive) {
                        confirmReset = true
                    } label: {
                        Text("Reset all progress")
                    }
                    .boardSecondaryButton()
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .scrollContentBackground(.hidden)
            .appDepthScreenBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Reset all progress?", isPresented: $confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                store.resetAllProgress()
            }
        } message: {
            Text("This clears stars, unlocks, and statistics on this device.")
        }
    }

    private func profileNavigationRow(title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }
            Spacer(minLength: 8)
            ProfileChevronGlyph()
                .frame(width: 12, height: 14)
        }
        .padding(16)
        .frame(minHeight: 44)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.96), Color.appBackground.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.appPrimary.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private func statCard(title: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.appSurface.opacity(0.98), Color.appSurface.opacity(0.78)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

private struct ProfileChevronGlyph: View {
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
