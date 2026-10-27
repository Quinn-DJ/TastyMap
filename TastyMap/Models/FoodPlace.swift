import CoreLocation
import Foundation
import SwiftData

@Model
final class FoodPlace {
    @Attribute(.unique) var clientID: UUID
    var remoteID: String?
    var ownerID: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var category: String
    var tags: [String]
    var note: String
    var statusRawValue: String
    var rating: Double?
    var isDeleted: Bool
    var isDirty: Bool
    var createdAt: Date
    var updatedAt: Date
    var serverUpdatedAt: Date?

    init(
        clientID: UUID = UUID(),
        remoteID: String? = nil,
        ownerID: String,
        name: String,
        address: String = "",
        latitude: Double,
        longitude: Double,
        category: String = "",
        tags: [String] = [],
        note: String = "",
        status: PlaceStatus = .wantToGo,
        rating: Double? = nil,
        isDeleted: Bool = false,
        isDirty: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        serverUpdatedAt: Date? = nil
    ) {
        self.clientID = clientID
        self.remoteID = remoteID
        self.ownerID = ownerID
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.tags = tags
        self.note = note
        self.statusRawValue = status.rawValue
        self.rating = rating
        self.isDeleted = isDeleted
        self.isDirty = isDirty
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.serverUpdatedAt = serverUpdatedAt
    }

    var status: PlaceStatus {
        get { PlaceStatus(rawValue: statusRawValue) ?? .wantToGo }
        set { statusRawValue = newValue.rawValue }
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var coordinateIsValid: Bool {
        (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    var searchText: String {
        ([name, address, category, note] + tags).joined(separator: " ")
    }

    func matches(_ query: String) -> Bool {
        let terms = query
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard !terms.isEmpty else { return true }
        return terms.allSatisfy { searchText.localizedStandardContains($0) }
    }

    func touch() {
        updatedAt = .now
        isDirty = true
    }

    func markDeleted() {
        isDeleted = true
        touch()
    }
}
