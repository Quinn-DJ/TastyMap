import MapKit
import Observation

@MainActor
@Observable
final class PlaceLookupModel {
    var query = ""
    var results: [PlaceLookupResult] = []
    var isSearching = false
    var errorMessage: String?

    func search() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty, !isSearching else { return }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = trimmedQuery
        request.resultTypes = [.pointOfInterest, .address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            results = response.mapItems
                .filter { $0.placemark.title?.isEmpty == false }
                .prefix(8)
                .map(PlaceLookupResult.init)
        } catch {
            results = []
            errorMessage = error.localizedDescription
        }
    }
}

struct PlaceLookupResult: Identifiable {
    let id = UUID()
    let item: MKMapItem

    var name: String {
        item.name ?? item.placemark.title ?? "未命名地点"
    }

    var address: String {
        item.placemark.title ?? ""
    }

    var coordinate: CLLocationCoordinate2D {
        item.placemark.coordinate
    }

    var suggestedCategory: String {
        guard let category = item.pointOfInterestCategory else {
            return ""
        }

        switch category {
        case .restaurant:
            return "餐厅"
        case .cafe:
            return "咖啡"
        case .bakery:
            return "烘焙"
        case .nightlife:
            return "酒吧"
        case .foodMarket:
            return "美食市集"
        default:
            return ""
        }
    }
}
