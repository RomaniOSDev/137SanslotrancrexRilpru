import Foundation

enum AppShellTab: Int, CaseIterable, Identifiable, Hashable {
    case home = 0
    case play = 1
    case achievements = 2
    case profile = 3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .play: return "Play"
        case .achievements: return "Achievements"
        case .profile: return "Profile"
        }
    }
}
