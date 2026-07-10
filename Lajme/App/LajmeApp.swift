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
                // Last resort: run on an in-memory store so the app still works
                // (bookmarks/read-state won't persist this session, but no crash).
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                container = try! ModelContainer(
                    for: BookmarkedArticle.self, ReadArticle.self,
                    configurations: config
                )
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
