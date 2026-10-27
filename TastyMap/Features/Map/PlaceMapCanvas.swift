import MapKit
import SwiftUI

struct PlaceMapCanvas: View {
    let places: [FoodPlace]
    @Binding var selectedClientID: UUID?
    @Binding var cameraPosition: MapCameraPosition

    var body: some View {
        Map(position: $cameraPosition, selection: $selectedClientID) {
            ForEach(validPlaces) { place in
                Annotation(
                    place.name,
                    coordinate: place.coordinate,
                    anchor: .bottom
                ) {
                    TastyPlaceMarker(
                        place: place,
                        isSelected: selectedClientID == place.clientID
                    )
                }
                .tag(place.clientID)
                .annotationTitles(.hidden)
            }

            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .flat, emphasis: .muted))
        .mapControls {
            MapCompass()
            MapUserLocationButton()
        }
        .overlay(alignment: .topTrailing) {
            if validPlaces.isEmpty {
                mapEmptyHint
                    .padding(18)
            }
        }
    }

    private var validPlaces: [FoodPlace] {
        places.filter(\.coordinateIsValid)
    }

    private var mapEmptyHint: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("地图还是空的")
                .font(TastyTheme.title(17))
                .foregroundStyle(TastyTheme.ink)
            Text("记录第一家想去的店")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(TastyTheme.secondaryInk)
        }
        .padding(13)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

private struct TastyPlaceMarker: View {
    let place: FoodPlace
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(TastyTheme.raisedPaper)
                    .frame(width: isSelected ? 48 : 40, height: isSelected ? 48 : 40)
                    .shadow(
                        color: TastyTheme.ink.opacity(0.20),
                        radius: 9,
                        x: 0,
                        y: 5
                    )

                Circle()
                    .fill(TastyTheme.mapPoint)
                    .frame(width: isSelected ? 39 : 31, height: isSelected ? 39 : 31)

                Image(systemName: markerIcon)
                    .font(.system(size: isSelected ? 16 : 13, weight: .bold))
                    .foregroundStyle(TastyTheme.mapPointForeground)
            }
            .overlay {
                if isSelected {
                    Circle()
                        .stroke(TastyTheme.mapPoint.opacity(0.30), lineWidth: 7)
                        .scaleEffect(1.20)
                }
            }

            if isSelected {
                Text(place.name)
                    .font(TastyTheme.label(12))
                    .foregroundStyle(TastyTheme.ink)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(TastyTheme.raisedPaper)
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.10), radius: 5, y: 3)
                    .transition(.scale(scale: 0.75).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.72), value: isSelected)
        .accessibilityLabel("\(place.name)，\(place.status.title)")
    }

    private var markerIcon: String {
        place.status == .wantToGo ? "fork.knife" : place.status.systemImage
    }
}
