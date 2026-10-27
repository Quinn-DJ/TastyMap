import Foundation

enum PlaceStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case wantToGo = "want_to_go"
    case visited
    case favorite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .wantToGo:
            "想去"
        case .visited:
            "去过"
        case .favorite:
            "最爱"
        }
    }

    var systemImage: String {
        switch self {
        case .wantToGo:
            "bookmark"
        case .visited:
            "checkmark.seal"
        case .favorite:
            "heart.fill"
        }
    }
}
