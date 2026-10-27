import Foundation
import SwiftData

@MainActor
struct PlaceSyncService {
    let apiClient: TastyAPIClient

    func synchronize(
        context: ModelContext,
        token: String,
        ownerID: String
    ) async throws {
        let remotePlaces = try await apiClient.fetchAllPlaces(token: token)
        let allLocalPlaces = try context.fetch(FetchDescriptor<FoodPlace>())
        var localByClientID = Dictionary(
            uniqueKeysWithValues: allLocalPlaces.map {
                ($0.clientID.uuidString.lowercased(), $0)
            }
        )

        for remote in remotePlaces where remote.owner == ownerID {
            guard let clientID = UUID(uuidString: remote.clientId) else {
                continue
            }

            if let local = localByClientID[clientID.uuidString.lowercased()] {
                guard !local.isDirty else { continue }
                apply(remote, to: local)
            } else {
                let place = makeLocalPlace(from: remote, clientID: clientID)
                context.insert(place)
                localByClientID[clientID.uuidString.lowercased()] = place
            }
        }

        try context.save()

        let refreshedLocalPlaces = try context.fetch(FetchDescriptor<FoodPlace>())
        let dirtyPlaces = refreshedLocalPlaces.filter {
            $0.ownerID == ownerID && $0.isDirty
        }

        for place in dirtyPlaces {
            if place.isDeleted && place.remoteID == nil {
                context.delete(place)
                continue
            }

            let mutation = PlaceMutation(
                place: place,
                deviceID: DeviceIdentity.id
            )

            let remote: RemotePlace
            if let remoteID = place.remoteID {
                remote = try await apiClient.updatePlace(
                    remoteID: remoteID,
                    mutation: mutation,
                    token: token
                )
            } else {
                remote = try await apiClient.createPlace(
                    mutation,
                    token: token
                )
            }

            place.remoteID = remote.id
            place.serverUpdatedAt = PocketBaseDate.date(from: remote.updatedAt) ?? .now
            place.isDirty = false
        }

        try context.save()
    }

    private func apply(_ remote: RemotePlace, to place: FoodPlace) {
        if let localUpdated = place.serverUpdatedAt,
           let remoteUpdated = PocketBaseDate.date(from: remote.updatedAt),
           remoteUpdated < localUpdated {
            return
        }

        place.remoteID = remote.id
        place.ownerID = remote.owner
        place.name = remote.name
        place.address = remote.address ?? ""
        place.latitude = remote.latitude
        place.longitude = remote.longitude
        place.category = remote.category ?? ""
        place.tags = remote.tags ?? []
        place.note = remote.note ?? ""
        place.status = PlaceStatus(rawValue: remote.status) ?? .wantToGo
        place.rating = remote.rating.flatMap { $0 > 0 ? $0 : nil }
        place.isDeleted = remote.deleted ?? false
        place.updatedAt = PocketBaseDate.date(from: remote.clientUpdatedAt)
            ?? PocketBaseDate.date(from: remote.updatedAt)
            ?? .now
        place.serverUpdatedAt = PocketBaseDate.date(from: remote.updatedAt)
        place.isDirty = false
    }

    private func makeLocalPlace(
        from remote: RemotePlace,
        clientID: UUID
    ) -> FoodPlace {
        FoodPlace(
            clientID: clientID,
            remoteID: remote.id,
            ownerID: remote.owner,
            name: remote.name,
            address: remote.address ?? "",
            latitude: remote.latitude,
            longitude: remote.longitude,
            category: remote.category ?? "",
            tags: remote.tags ?? [],
            note: remote.note ?? "",
            status: PlaceStatus(rawValue: remote.status) ?? .wantToGo,
            rating: remote.rating.flatMap { $0 > 0 ? $0 : nil },
            isDeleted: remote.deleted ?? false,
            isDirty: false,
            createdAt: PocketBaseDate.date(from: remote.createdAt) ?? .now,
            updatedAt: PocketBaseDate.date(from: remote.clientUpdatedAt)
                ?? PocketBaseDate.date(from: remote.updatedAt)
                ?? .now,
            serverUpdatedAt: PocketBaseDate.date(from: remote.updatedAt)
        )
    }
}

enum DeviceIdentity {
    private static let key = "tastymap.device.id"

    static var id: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }

        let identifier = UUID().uuidString.lowercased()
        UserDefaults.standard.set(identifier, forKey: key)
        return identifier
    }
}
