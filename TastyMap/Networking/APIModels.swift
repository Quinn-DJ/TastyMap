import Foundation

struct UserRecord: Decodable, Sendable {
    let id: String
    let email: String
    let name: String?
    let verified: Bool?

    var profile: UserProfile {
        UserProfile(
            id: id,
            email: email,
            name: name.flatMap { $0.isEmpty ? nil : $0 } ?? email
        )
    }
}

struct AuthResponse: Decodable, Sendable {
    let token: String
    let record: UserRecord
}

struct PlaceListResponse: Decodable, Sendable {
    let page: Int
    let perPage: Int
    let totalItems: Int
    let totalPages: Int
    let items: [RemotePlace]
}

struct RemotePlace: Decodable, Identifiable, Sendable {
    let id: String
    let owner: String
    let clientId: String
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double
    let category: String?
    let tags: [String]?
    let note: String?
    let status: String
    let rating: Double?
    let clientUpdatedAt: String?
    let deleted: Bool?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case clientId = "client_id"
        case name
        case address
        case latitude
        case longitude
        case category
        case tags
        case note
        case status
        case rating
        case clientUpdatedAt = "client_updated_at"
        case deleted
        case createdAt = "created"
        case updatedAt = "updated"
    }
}

struct LoginRequest: Encodable {
    let identity: String
    let password: String
}

struct PlaceMutation: Encodable {
    let owner: String
    let clientId: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let category: String
    let tags: [String]
    let note: String
    let status: String
    let rating: Double?
    let clientUpdatedAt: String
    let deleted: Bool
    let lastDeviceId: String

    enum CodingKeys: String, CodingKey {
        case owner
        case clientId = "client_id"
        case name
        case address
        case latitude
        case longitude
        case category
        case tags
        case note
        case status
        case rating
        case clientUpdatedAt = "client_updated_at"
        case deleted
        case lastDeviceId = "last_device_id"
    }

    init(place: FoodPlace, deviceID: String) {
        owner = place.ownerID
        clientId = place.clientID.uuidString.lowercased()
        name = place.name
        address = place.address
        latitude = place.latitude
        longitude = place.longitude
        category = place.category
        tags = place.tags
        note = place.note
        status = place.status.rawValue
        rating = place.rating
        clientUpdatedAt = PocketBaseDate.string(from: place.updatedAt)
        deleted = place.isDeleted
        lastDeviceId = deviceID
    }
}

struct PocketBaseErrorEnvelope: Decodable {
    let code: Int?
    let message: String?
}

enum PocketBaseDate {
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    static func date(from string: String?) -> Date? {
        guard let string, !string.isEmpty else { return nil }
        return formatter.date(from: string) ?? fallbackFormatter.date(from: string)
    }
}
