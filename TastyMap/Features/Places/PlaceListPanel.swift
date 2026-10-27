import SwiftUI

struct PlaceListPanel: View {
    let places: [FoodPlace]
    @Binding var searchText: String
    @Binding var selectedClientID: UUID?
    let onAdd: () -> Void
    let onSelect: (FoodPlace) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 14)

            TastySearchField(text: $searchText)
                .padding(.horizontal, 16)
                .padding(.bottom, 13)

            Divider()
                .overlay(TastyTheme.hairline)

            if places.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(places) { place in
                            Button {
                                selectedClientID = place.clientID
                                onSelect(place)
                            } label: {
                                PlaceRow(
                                    place: place,
                                    isSelected: selectedClientID == place.clientID
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .background(TastyTheme.paper)
    }

    private var header: some View {
        HStack(spacing: 11) {
            TastyMark(size: 35)
            VStack(alignment: .leading, spacing: 1) {
                Text("TastyMap")
                    .font(TastyTheme.title(23))
                    .foregroundStyle(TastyTheme.ink)
                Text("\(places.count) 个收藏")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
            }

            Spacer()

            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(TastyTheme.actionForeground)
                    .frame(width: 32, height: 32)
                    .background(TastyTheme.actionFill)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("添加店铺")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "map" : "magnifyingglass")
                .font(.system(size: 31, weight: .light))
                .foregroundStyle(TastyTheme.actionFill)
            Text(searchText.isEmpty ? "还没有收藏" : "没有匹配的店")
                .font(TastyTheme.title(20))
                .foregroundStyle(TastyTheme.ink)
            Text(searchText.isEmpty ? "把第一家想去的店放上地图。" : "换个关键词，或清空搜索条件。")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(TastyTheme.secondaryInk)
                .multilineTextAlignment(.center)
            if searchText.isEmpty {
                Button("添加第一家店", action: onAdd)
                    .font(TastyTheme.label(13))
                    .foregroundStyle(TastyTheme.actionForeground)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 9)
                    .background(TastyTheme.actionFill)
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(26)
    }
}

private struct PlaceRow: View {
    let place: FoodPlace
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isSelected
                            ? TastyTheme.actionFill
                            : TastyTheme.subduedFill
                    )
                Image(systemName: place.status.systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? TastyTheme.actionForeground : TastyTheme.secondaryInk
                    )
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 3) {
                Text(place.name)
                    .font(TastyTheme.label(14))
                    .foregroundStyle(TastyTheme.ink)
                    .lineLimit(1)
                Text(place.address.isEmpty ? place.category : place.address)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            if let rating = place.rating, rating > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(TastyTheme.ratingYellow)
                    Text(String(format: "%.1f", rating))
                        .foregroundStyle(TastyTheme.secondaryInk)
                }
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
        }
        .padding(10)
        .background(
            isSelected
                ? TastyTheme.raisedPaper
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TastyTheme.actionFill.opacity(0.30), lineWidth: 1)
            }
        }
    }
}
