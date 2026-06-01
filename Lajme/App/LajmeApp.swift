import SwiftUI
import SwiftData

@main
struct LajmeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: BookmarkedArticle.self, ReadArticle.self)
        } catch {
            // If schema corrupted, delete store and recreate
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: url)
            do {
                container = try ModelContainer(for: BookmarkedArticle.self, ReadArticle.self)
            } catch {
                fatalError("Failed to init ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
