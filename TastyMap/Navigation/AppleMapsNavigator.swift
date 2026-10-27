import MapKit

enum TravelMode: String, CaseIterable, Identifiable {
    case walking
    case driving
    case transit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .walking:
            "步行"
        case .driving:
            "驾车"
        case .transit:
            "公共交通"
        }
    }

    var systemImage: String {
        switch self {
        case .walking:
            "figure.walk"
        case .driving:
            "car.fill"
        case .transit:
            "tram.fill"
        }
    }

    var launchMode: String {
        switch self {
        case .walking:
            MKLaunchOptionsDirectionsModeWalking
        case .driving:
            MKLaunchOptionsDirectionsModeDriving
        case .transit:
            MKLaunchOptionsDirectionsModeTransit
        }
    }
}

enum AppleMapsNavigator {
    @discardableResult
    static func open(place: FoodPlace, mode: TravelMode) -> Bool {
        let placemark = MKPlacemark(coordinate: place.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = place.name

        return item.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey: mode.launchMode
            ]
        )
    }
}
