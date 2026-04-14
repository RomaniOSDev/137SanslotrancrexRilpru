import StoreKit
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Tune links and feedback without leaving the board hub.")
                    .font(.body)
                    .foregroundStyle(Color.appTextSecondary)

                VStack(spacing: 12) {
                    settingsButton(title: "Rate us", subtitle: "Share feedback in the App Store") {
                        rateApp()
                    }

                    settingsButton(title: "Privacy Policy", subtitle: "How data is handled") {
                        openLegalLink(.privacyPolicy)
                    }

                    settingsButton(title: "Terms of Use", subtitle: "Conditions for using the app") {
                        openLegalLink(.termsOfUse)
                    }
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
        .appDepthScreenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func openLegalLink(_ link: AppExternalLink) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    private func settingsButton(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.appTextPrimary)
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                SettingsChevronGlyph()
                    .frame(width: 12, height: 14)
            }
            .padding(16)
            .frame(minHeight: 44)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.appSurface.opacity(0.96), Color.appBackground.opacity(0.38)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.appAccent.opacity(0.22), lineWidth: 1)
                }
                .shadow(color: Color.appPrimary.opacity(0.1), radius: 10, x: 0, y: 5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsChevronGlyph: View {
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
