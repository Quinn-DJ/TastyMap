import SwiftData
import SwiftUI

@main
struct TastyMapApp: App {
    @State private var session = AppSession()
    private let modelContainer: ModelContainer

    init() {
        let schema = Schema([FoodPlace.self])
        let configuration = ModelConfiguration(
            "TastyMap",
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Unable to create TastyMap data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .tint(TastyTheme.actionFill)
        }
        .modelContainer(modelContainer)
#if os(macOS)
        .defaultSize(width: 1120, height: 760)
#endif
    }
}
