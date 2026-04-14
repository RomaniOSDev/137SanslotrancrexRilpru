import SwiftUI

struct PrimaryBoardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appBackground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appPrimary.opacity(configuration.isPressed ? 0.78 : 1),
                                    Color.appPrimary.opacity(configuration.isPressed ? 0.65 : 0.88),
                                    Color.appAccent.opacity(configuration.isPressed ? 0.55 : 0.75)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.appTextPrimary.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: Color.appPrimary.opacity(0.35), radius: configuration.isPressed ? 4 : 10, x: 0, y: configuration.isPressed ? 2 : 6)
                .shadow(color: Color.appAccent.opacity(0.15), radius: 2, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

struct SecondaryBoardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.appTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(configuration.isPressed ? 0.95 : 0.82),
                                    Color.appBackground.opacity(0.4)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appAccent.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
                .shadow(color: Color.appPrimary.opacity(0.12), radius: configuration.isPressed ? 3 : 8, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.45, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension View {
    func boardPrimaryButton() -> some View {
        buttonStyle(PrimaryBoardButtonStyle())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    func boardSecondaryButton() -> some View {
        buttonStyle(SecondaryBoardButtonStyle())
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}
