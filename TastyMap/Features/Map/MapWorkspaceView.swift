import MapKit
import SwiftData
import SwiftUI

struct MapWorkspaceView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \FoodPlace.updatedAt, order: .reverse)
    private var allPlaces: [FoodPlace]

    @State private var searchText = ""
    @State private var selectedClientID: UUID?
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
            span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
        )
    )
    @State private var editorContext: PlaceEditorContext?
    @State private var pendingDelete: FoodPlace?

    var body: some View {
        NavigationStack {
            Group {
#if os(macOS)
                HSplitView {
                    PlaceListPanel(
                        places: filteredPlaces,
                        searchText: $searchText,
                        selectedClientID: $selectedClientID,
                        onAdd: presentNewPlace,
                        onSelect: focus
                    )
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 390)

                    mapArea
                        .frame(minWidth: 520)
                }
#else
                mapArea
                    .safeAreaInset(edge: .top, spacing: 0) {
                        TastySearchField(text: $searchText)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 8)
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if let selectedPlace {
                            PlaceDetailCard(
                                place: selectedPlace,
                                compact: true,
                                onClose: { selectedClientID = nil },
                                onEdit: { presentEditor(for: selectedPlace) },
                                onDelete: { pendingDelete = selectedPlace }
                            )
                            .padding(.horizontal, 12)
                            .padding(.bottom, 8)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
#endif
            }
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    syncButton
                    addButton
                    accountMenu
                }
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
        .task(id: session.currentUser?.id) {
            await session.synchronize(context: modelContext)
            focusInitialPlacesIfNeeded()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, session.isAuthenticated else { return }
            Task {
                await session.synchronize(context: modelContext)
            }
        }
        .onChange(of: searchText) { _, _ in
            if let selectedClientID,
               !filteredPlaces.contains(where: { $0.clientID == selectedClientID }) {
                self.selectedClientID = nil
            }
        }
        .sheet(item: $editorContext) { context in
            PlaceEditorView(place: context.place) {
                Task {
                    await session.synchronize(context: modelContext)
                }
            }
            .environment(session)
        }
        .confirmationDialog(
            "从地图中删除这家店？",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let pendingDelete {
                    remove(pendingDelete)
                }
            }
            Button("取消", role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text("删除会同步到其他设备，但本地历史仍会保留墓碑记录。")
        }
    }

    private var mapArea: some View {
        ZStack(alignment: .bottomTrailing) {
            PlaceMapCanvas(
                places: filteredPlaces,
                selectedClientID: $selectedClientID,
                cameraPosition: $cameraPosition
            )
            .ignoresSafeArea(edges: [.bottom])

#if os(macOS)
            if let selectedPlace {
                PlaceDetailCard(
                    place: selectedPlace,
                    compact: false,
                    onClose: { selectedClientID = nil },
                    onEdit: { presentEditor(for: selectedPlace) },
                    onDelete: { pendingDelete = selectedPlace }
                )
                .frame(width: 350)
                .padding(20)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
#endif

            Button {
                focusResults()
            } label: {
                Image(systemName: "scope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TastyTheme.ink)
                    .frame(width: 38, height: 38)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(16)
            .accessibilityLabel("显示全部搜索结果")
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: selectedClientID)
    }

    private var filteredPlaces: [FoodPlace] {
        guard let userID = session.currentUser?.id else { return [] }
        return allPlaces.filter {
            $0.ownerID == userID
                && !$0.isDeleted
                && $0.matches(searchText)
        }
    }

    private var selectedPlace: FoodPlace? {
        guard let selectedClientID else { return nil }
        return filteredPlaces.first { $0.clientID == selectedClientID }
    }

    private var addButton: some View {
        Button(action: presentNewPlace) {
            Label("添加店铺", systemImage: "plus")
        }
        .keyboardShortcut("n", modifiers: .command)
    }

    private var syncButton: some View {
        Button {
            Task {
                await session.synchronize(context: modelContext)
            }
        } label: {
            if session.isSyncing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Label("同步", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .disabled(session.isSyncing)
        .help(syncHelpText)
    }

    private var accountMenu: some View {
        Menu {
            if let user = session.currentUser {
                Section(user.email) {
                    Button("退出登录", role: .destructive) {
                        session.logout()
                    }
                }
            }
        } label: {
            Text(String(session.currentUser?.name.prefix(1) ?? "T"))
                .font(TastyTheme.label(13))
                .foregroundStyle(TastyTheme.ink)
                .frame(width: 30, height: 30)
                .background(TastyTheme.support.opacity(0.18))
                .clipShape(Circle())
        }
        .accessibilityLabel("账号")
    }

    private var syncHelpText: String {
        if let error = session.syncError {
            return error
        }
        if let date = session.lastSyncedAt {
            return "上次同步：\(date.formatted(date: .omitted, time: .shortened))"
        }
        return "同步店铺"
    }

    private func presentNewPlace() {
        editorContext = PlaceEditorContext(place: nil)
    }

    private func presentEditor(for place: FoodPlace) {
        editorContext = PlaceEditorContext(place: place)
    }

    private func remove(_ place: FoodPlace) {
        place.markDeleted()
        try? modelContext.save()
        pendingDelete = nil
        selectedClientID = nil
        Task {
            await session.synchronize(context: modelContext)
        }
    }

    private func focus(_ place: FoodPlace) {
        selectedClientID = place.clientID
        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: place.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                )
            )
        }
    }

    private func focusResults() {
        guard !filteredPlaces.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region(for: filteredPlaces))
        }
    }

    private func focusInitialPlacesIfNeeded() {
        guard !filteredPlaces.isEmpty else { return }
        cameraPosition = .region(region(for: filteredPlaces))
    }

    private func region(for places: [FoodPlace]) -> MKCoordinateRegion {
        let coordinates = places.filter(\.coordinateIsValid).map(\.coordinate)
        guard
            let minLatitude = coordinates.map(\.latitude).min(),
            let maxLatitude = coordinates.map(\.latitude).max(),
            let minLongitude = coordinates.map(\.longitude).min(),
            let maxLongitude = coordinates.map(\.longitude).max()
        else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 30.2741, longitude: 120.1551),
                span: MKCoordinateSpan(latitudeDelta: 0.16, longitudeDelta: 0.16)
            )
        }

        let latitudeDelta = max((maxLatitude - minLatitude) * 1.7, 0.015)
        let longitudeDelta = max((maxLongitude - minLongitude) * 1.7, 0.015)

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: latitudeDelta,
                longitudeDelta: longitudeDelta
            )
        )
    }
}

private struct PlaceEditorContext: Identifiable {
    let id = UUID()
    let place: FoodPlace?
}
