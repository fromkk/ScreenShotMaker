import Foundation

enum LayoutPreset: String, Codable, CaseIterable, Identifiable {
    case textTop
    case textOverlay
    case textBottom
    case textOnly
    case screenshotOnly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .textTop: "Text Top"
        case .textOverlay: "Overlay"
        case .textBottom: "Text Bottom"
        case .textOnly: "Text Only"
        case .screenshotOnly: "Screenshot Only"
        }
    }
}
