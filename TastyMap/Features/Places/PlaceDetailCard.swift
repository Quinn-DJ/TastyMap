import SwiftUI

struct PlaceDetailCard: View {
    let place: FoodPlace
    var compact: Bool = false
    let onClose: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 13 : 17) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Label(place.status.title, systemImage: place.status.systemImage)
                            .font(TastyTheme.label(11))
                            .foregroundStyle(TastyTheme.actionFill)

                        if !place.category.isEmpty {
                            Text(place.category)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(TastyTheme.support)
                        }
                    }

                    Text(place.name)
                        .font(TastyTheme.title(compact ? 23 : 27))
                        .foregroundStyle(TastyTheme.ink)
                        .lineLimit(2)
                }

                Spacer(minLength: 6)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(TastyTheme.secondaryInk)
                        .frame(width: 28, height: 28)
                        .background(TastyTheme.paper)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("关闭详情")
            }

            if !place.address.isEmpty {
                Label(place.address, systemImage: "mappin")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let rating = place.rating, rating > 0 {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(TastyTheme.ratingYellow)
                    Text(String(format: "%.1f", rating))
                }
                .font(TastyTheme.label(12))
                .foregroundStyle(TastyTheme.secondaryInk)
            }

            if !place.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(place.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(TastyTheme.secondaryInk)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(TastyTheme.paper)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            if !place.note.isEmpty {
                Text(place.note)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
                    .lineLimit(compact ? 3 : 5)
                    .lineSpacing(3)
            }

            HStack(spacing: 10) {
                Menu {
                    ForEach(TravelMode.allCases) { mode in
                        Button {
                            AppleMapsNavigator.open(place: place, mode: mode)
                        } label: {
                            Label(mode.title, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    Label("导航", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(TastyTheme.label(14))
                        .foregroundStyle(TastyTheme.actionForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(TastyTheme.actionFill)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TastyTheme.ink)
                        .frame(width: 42, height: 42)
                        .background(TastyTheme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑店铺")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TastyTheme.danger)
                        .frame(width: 42, height: 42)
                        .background(TastyTheme.danger.opacity(0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("删除店铺")
            }
        }
        .modifier(TastyCard(padding: compact ? 18 : 22))
    }
}
