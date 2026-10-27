import Foundation

struct UserProfile: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let email: String
    let name: String
}
