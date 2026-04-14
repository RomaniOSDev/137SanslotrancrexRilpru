import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject private var store: GameProgressStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Achievements")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)

                Text("Milestones unlock as you explore every activity.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                if store.achievements.allSatisfy({ !$0.isUnlocked }) {
                    Text("Play a few rounds to start unlocking badges.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.appAccent)
                        .padding(.vertical, 6)
                }

                VStack(spacing: 12) {
                    ForEach(store.achievements) { item in
                        AchievementRow(item: item)
                    }
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
    }
}

private struct AchievementRow: View {
    let item: AchievementItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            MedalGlyph(unlocked: item.isUnlocked)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(item.detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSurface.opacity(item.isUnlocked ? 1 : 0.68),
                                Color.appBackground.opacity(item.isUnlocked ? 0.35 : 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.appAccent.opacity(item.isUnlocked ? 0.45 : 0.15), lineWidth: 1)
            }
            .shadow(color: Color.appPrimary.opacity(item.isUnlocked ? 0.14 : 0.04), radius: item.isUnlocked ? 10 : 4, x: 0, y: 5)
        )
    }
}

private struct MedalGlyph: View {
    let unlocked: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4
            var circle = Path()
            circle.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.fill(circle, with: .color(unlocked ? Color.appPrimary.opacity(0.85) : Color.appSurface))
            context.stroke(circle, with: .color(Color.appAccent), lineWidth: 2)

            if unlocked {
                var ribbon = Path()
                ribbon.move(to: CGPoint(x: center.x - radius * 0.4, y: center.y + radius * 0.2))
                ribbon.addLine(to: CGPoint(x: center.x + radius * 0.4, y: center.y + radius * 0.2))
                ribbon.addLine(to: CGPoint(x: center.x, y: center.y + radius * 0.9))
                ribbon.closeSubpath()
                context.fill(ribbon, with: .color(Color.appAccent.opacity(0.85)))
            }
        }
    }
}
