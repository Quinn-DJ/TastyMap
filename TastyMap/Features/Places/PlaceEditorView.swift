import MapKit
import SwiftData
import SwiftUI

struct PlaceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSession.self) private var session

    private let place: FoodPlace?
    private let onSaved: () -> Void

    @State private var lookup = PlaceLookupModel()
    @State private var name: String
    @State private var address: String
    @State private var category: String
    @State private var tagsText: String
    @State private var note: String
    @State private var status: PlaceStatus
    @State private var ratingEnabled: Bool
    @State private var rating: Double
    @State private var latitude: Double
    @State private var longitude: Double
    @State private var hasCoordinate: Bool
    @State private var showingCoordinateFields = false
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case address
        case category
        case tags
        case note
    }

    init(place: FoodPlace?, onSaved: @escaping () -> Void) {
        self.place = place
        self.onSaved = onSaved
        _name = State(initialValue: place?.name ?? "")
        _address = State(initialValue: place?.address ?? "")
        _category = State(initialValue: place?.category ?? "")
        _tagsText = State(initialValue: place?.tags.joined(separator: ", ") ?? "")
        _note = State(initialValue: place?.note ?? "")
        _status = State(initialValue: place?.status ?? .wantToGo)
        _ratingEnabled = State(initialValue: (place?.rating ?? 0) > 0)
        _rating = State(initialValue: place?.rating ?? 4)
        _latitude = State(initialValue: place?.latitude ?? 0)
        _longitude = State(initialValue: place?.longitude ?? 0)
        _hasCoordinate = State(initialValue: place != nil)
    }

    var body: some View {
        ZStack {
            TastyTheme.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    lookupSection
                    detailsSection
                    locationSection
                    noteSection
                }
                .padding(24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
        }
        .safeAreaInset(edge: .bottom) {
            actionBar
        }
#if os(macOS)
        .frame(minWidth: 580, minHeight: 680)
#else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
        .presentationDetents([.large])
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(place == nil ? "记录一家店" : "编辑店铺")
                    .font(TastyTheme.title(31))
                    .foregroundStyle(TastyTheme.ink)
                Text(place == nil ? "先从 Apple 地图查找，再补上属于你的备注。" : "修改后会同步到你的其他设备。")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
            }

            Spacer()

            Button("取消") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(TastyTheme.secondaryInk)
        }
    }

    private var lookupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("从 Apple 地图查找", icon: "map")

            HStack(spacing: 9) {
                TextField("店名或地址", text: Bindable(lookup).query)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await lookup.search() }
                    }

                Button {
                    Task { await lookup.search() }
                } label: {
                    if lookup.isSearching {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(TastyTheme.actionFill)
                .accessibilityLabel("搜索 Apple 地图")
            }
            .padding(.horizontal, 13)
            .frame(height: 44)
            .background(TastyTheme.paper)
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(TastyTheme.hairline, lineWidth: 1)
            }

            if let error = lookup.errorMessage {
                Text(error)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(TastyTheme.danger)
            }

            if !lookup.results.isEmpty {
                VStack(spacing: 0) {
                    ForEach(lookup.results) { result in
                        Button {
                            choose(result)
                        } label: {
                            HStack(spacing: 11) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(TastyTheme.mapPoint)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .font(TastyTheme.label(13))
                                        .foregroundStyle(TastyTheme.ink)
                                        .lineLimit(1)
                                    Text(result.address)
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .foregroundStyle(TastyTheme.secondaryInk)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(TastyTheme.support)
                            }
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if result.id != lookup.results.last?.id {
                            Divider()
                                .overlay(TastyTheme.hairline)
                        }
                    }
                }
            }
        }
        .modifier(TastyCard(padding: 18))
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("店铺信息", icon: "fork.knife")

            editorField(
                title: "店名",
                text: $name,
                field: .name
            )
            editorField(
                title: "地址",
                text: $address,
                field: .address
            )
            editorField(
                title: "菜系或类别",
                text: $category,
                field: .category
            )
            editorField(
                title: "标签，用逗号分隔",
                text: $tagsText,
                field: .tags
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("状态")
                    .font(TastyTheme.label(12))
                    .foregroundStyle(TastyTheme.secondaryInk)
                Picker("状态", selection: $status) {
                    ForEach(PlaceStatus.allCases) { status in
                        Text(status.title).tag(status)
                    }
                }
                .pickerStyle(.segmented)
            }

            Toggle(isOn: $ratingEnabled) {
                Text("添加评分")
                    .font(TastyTheme.label(13))
                    .foregroundStyle(TastyTheme.ink)
            }
            .tint(TastyTheme.actionFill)

            if ratingEnabled {
                HStack {
                    Slider(value: $rating, in: 0...5, step: 0.5)
                        .tint(TastyTheme.ratingYellow)
                    Text(String(format: "%.1f", rating))
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(TastyTheme.secondaryInk)
                        .frame(width: 32)
                }
            }
        }
        .modifier(TastyCard(padding: 18))
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionTitle("地图位置", icon: "mappin.and.ellipse")
                Spacer()
                Button(showingCoordinateFields ? "收起坐标" : "手动输入坐标") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingCoordinateFields.toggle()
                    }
                }
                .buttonStyle(.plain)
                .font(TastyTheme.label(12))
                .foregroundStyle(TastyTheme.support)
            }

            if hasCoordinate {
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: latitude,
                                longitude: longitude
                            ),
                            span: MKCoordinateSpan(
                                latitudeDelta: 0.008,
                                longitudeDelta: 0.008
                            )
                        )
                    ),
                    interactionModes: [.pan, .zoom]
                ) {
                    Annotation(
                        name.isEmpty ? "新店铺" : name,
                        coordinate: CLLocationCoordinate2D(
                            latitude: latitude,
                            longitude: longitude
                        )
                    ) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 29))
                            .foregroundStyle(TastyTheme.mapPoint)
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted))
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            } else {
                Label("请先从 Apple 地图选择一个结果，或手动输入坐标。", systemImage: "location.slash")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(TastyTheme.secondaryInk)
            }

            if showingCoordinateFields {
                HStack(spacing: 12) {
                    coordinateField("纬度", value: $latitude)
                    coordinateField("经度", value: $longitude)
                }
            }
        }
        .modifier(TastyCard(padding: 18))
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("你的备注", icon: "text.quote")
            TextEditor(text: $note)
                .focused($focusedField, equals: .note)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 108)
                .padding(10)
                .background(TastyTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(TastyTheme.hairline, lineWidth: 1)
                }
        }
        .modifier(TastyCard(padding: 18))
    }

    private var actionBar: some View {
        VStack(spacing: 8) {
            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(TastyTheme.danger)
            }

            Button("保存店铺", action: save)
                .buttonStyle(PrimaryActionButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 13)
        .background(.ultraThinMaterial)
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(TastyTheme.title(17))
            .foregroundStyle(TastyTheme.ink)
    }

    private func editorField(
        title: String,
        text: Binding<String>,
        field: Field
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(TastyTheme.label(12))
                .foregroundStyle(TastyTheme.secondaryInk)
            TextField(title, text: text)
                .focused($focusedField, equals: field)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 41)
                .background(TastyTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TastyTheme.hairline, lineWidth: 1)
                }
        }
    }

    private func coordinateField(
        _ title: String,
        value: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(TastyTheme.label(12))
                .foregroundStyle(TastyTheme.secondaryInk)
            TextField(title, value: value, format: .number.precision(.fractionLength(6)))
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(height: 41)
                .background(TastyTheme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TastyTheme.hairline, lineWidth: 1)
                }
        }
    }

    private func choose(_ result: PlaceLookupResult) {
        name = result.name
        address = result.address
        if category.isEmpty {
            category = result.suggestedCategory
        }
        latitude = result.coordinate.latitude
        longitude = result.coordinate.longitude
        hasCoordinate = true
        lookup.results = []
        lookup.query = ""
        validationMessage = nil
    }

    private func save() {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else {
            validationMessage = "请填写店名。"
            return
        }
        guard
            (-90...90).contains(latitude),
            (-180...180).contains(longitude),
            latitude != 0 || longitude != 0
        else {
            validationMessage = "请从 Apple 地图选择位置，或输入有效坐标。"
            return
        }

        let tags = tagsText
            .replacingOccurrences(of: "，", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let place {
            place.name = cleanName
            place.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
            place.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
            place.latitude = latitude
            place.longitude = longitude
            place.tags = tags
            place.note = note
            place.status = status
            place.rating = ratingEnabled ? rating : nil
            place.touch()
        } else {
            guard let ownerID = session.currentUser?.id else {
                validationMessage = "登录状态已失效，请重新登录。"
                return
            }
            let newPlace = FoodPlace(
                ownerID: ownerID,
                name: cleanName,
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                latitude: latitude,
                longitude: longitude,
                category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                note: note,
                status: status,
                rating: ratingEnabled ? rating : nil
            )
            modelContext.insert(newPlace)
        }

        do {
            try modelContext.save()
            onSaved()
            dismiss()
        } catch {
            validationMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}
