import SwiftUI

struct MainTabView: View {
    @State private var tab: AppShellTab = .home

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch tab {
                case .home:
                    HomeView(selectedTab: $tab)
                case .play:
                    PlayRootView()
                case .achievements:
                    AchievementsView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
        .appDepthScreenBackground()
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AppShellTab.allCases) { item in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        tab = item
                    }
                } label: {
                    VStack(spacing: 6) {
                        TabGlyph(tab: item, isSelected: tab == item)
                            .frame(width: 28, height: 28)
                        Text(item.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(tab == item ? Color.appPrimary : Color.appTextSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .background(
            ZStack(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.appSurface.opacity(0.98),
                        Color.appSurface.opacity(0.88),
                        Color.appBackground.opacity(0.35)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)

                LinearGradient(
                    colors: [Color.appTextPrimary.opacity(0.12), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 14)
                .ignoresSafeArea(edges: .bottom)
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.appAccent.opacity(0.45), Color.appPrimary.opacity(0.25)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1.5)
        }
        .shadow(color: Color.appPrimary.opacity(0.18), radius: 12, x: 0, y: -4)
    }
}

private struct TabGlyph: View {
    let tab: AppShellTab
    let isSelected: Bool

    var body: some View {
        Canvas { context, size in
            let stroke = isSelected ? Color.appPrimary : Color.appTextSecondary
            let fill = isSelected ? Color.appAccent.opacity(0.35) : Color.appSurface

            switch tab {
            case .home:
                var roof = Path()
                roof.move(to: CGPoint(x: size.width / 2, y: 4))
                roof.addLine(to: CGPoint(x: size.width - 4, y: size.height * 0.38))
                roof.addLine(to: CGPoint(x: 4, y: size.height * 0.38))
                roof.closeSubpath()
                context.fill(roof, with: .color(fill))
                context.stroke(roof, with: .color(stroke), lineWidth: 2)
                let base = Path(roundedRect: CGRect(x: 6, y: size.height * 0.36, width: size.width - 12, height: size.height * 0.5), cornerRadius: 3)
                context.fill(base, with: .color(fill))
                context.stroke(base, with: .color(stroke), lineWidth: 2)
                let door = Path(roundedRect: CGRect(x: size.width / 2 - 4, y: size.height * 0.55, width: 8, height: size.height * 0.28), cornerRadius: 2)
                context.stroke(door, with: .color(stroke.opacity(0.85)), lineWidth: 1.5)
            case .play:
                let rect = CGRect(x: 4, y: 4, width: size.width - 8, height: size.height - 8)
                let path = Path(roundedRect: rect, cornerRadius: 6)
                context.fill(path, with: .color(fill))
                context.stroke(path, with: .color(stroke), lineWidth: 2)
                let dot = Path(ellipseIn: CGRect(x: size.width / 2 - 4, y: size.height / 2 - 4, width: 8, height: 8))
                context.fill(dot, with: .color(stroke))
            case .achievements:
                var star = Path()
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = min(size.width, size.height) / 2 - 4
                for i in 0..<10 {
                    let angle = CGFloat(i) * .pi / 5 - .pi / 2
                    let radius = i.isMultiple(of: 2) ? r : r * 0.45
                    let pt = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                    if i == 0 { star.move(to: pt) } else { star.addLine(to: pt) }
                }
                star.closeSubpath()
                context.fill(star, with: .color(fill))
                context.stroke(star, with: .color(stroke), lineWidth: 2)
            case .profile:
                let head = Path(ellipseIn: CGRect(x: size.width / 2 - 7, y: 6, width: 14, height: 14))
                context.fill(head, with: .color(fill))
                context.stroke(head, with: .color(stroke), lineWidth: 2)
                var body = Path()
                body.addEllipse(in: CGRect(x: 4, y: 16, width: size.width - 8, height: size.height - 20))
                context.stroke(body, with: .color(stroke), lineWidth: 2)
            }
        }
    }
}
