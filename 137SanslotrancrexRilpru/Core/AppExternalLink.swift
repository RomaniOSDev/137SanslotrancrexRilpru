import Foundation

enum AppExternalLink {
    case privacyPolicy
    case termsOfUse

    var url: URL? {
        switch self {
        case .privacyPolicy:
            URL(string: "https://sanslotrancrexrilpru137.site/privacy/103")
        case .termsOfUse:
            URL(string: "https://sanslotrancrexrilpru137.site/terms/103")
        }
    }
}
