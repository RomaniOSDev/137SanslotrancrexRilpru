import SwiftUI

/// Shared depth: gradients, soft highlights, and layered shadows using asset palette only.
enum AppDepthChrome {
    static var screenBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.appBackground,
                    Color.appSurface.opacity(0.28),
                    Color.appBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            LinearGradient(
                colors: [
                    Color.appPrimary.opacity(0.07),
                    Color.clear,
                    Color.appAccent.opacity(0.05)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
        }
    }

    static func raisedPanel(cornerRadius: CGFloat = 20) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.appSurface.opacity(0.98),
                            Color.appSurface.opacity(0.78),
                            Color.appBackground.opacity(0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.appTextPrimary.opacity(0.14),
                            Color.appAccent.opacity(0.28),
                            Color.appPrimary.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: Color.appPrimary.opacity(0.14), radius: 14, x: 0, y: 8)
        .shadow(color: Color.appTextPrimary.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    static func softInsetWell(cornerRadius: CGFloat = 18) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.appBackground.opacity(0.55),
                        Color.appSurface.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.appTextSecondary.opacity(0.22),
                                Color.appAccent.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.appTextPrimary.opacity(0.04), radius: 0, x: 0, y: 1)
    }
}

extension View {
    /// Full-screen atmospheric gradient behind content.
    func appDepthScreenBackground() -> some View {
        background(
            AppDepthChrome.screenBackdrop
                .ignoresSafeArea()
        )
    }

    /// Floating game board / large control cluster.
    func appDepthBoardChrome(cornerRadius: CGFloat = 22, contentInset: CGFloat = 10) -> some View {
        self.padding(contentInset)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurface.opacity(0.9),
                                    Color.appBackground.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: Color.appPrimary.opacity(0.18), radius: 16, x: 0, y: 10)
                .shadow(color: Color.appTextPrimary.opacity(0.05), radius: 2, x: 0, y: 1)
            )
    }
}
