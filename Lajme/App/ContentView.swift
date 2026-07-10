import SwiftUI

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    var body: some View {
        ArticleFeedView()
            .preferredColorScheme(colorScheme)
            .task {
                // Pre-compile ad-blocker rules at launch so first article opens fast.
                // WebKit caches the compiled bytecode on disk, so this is a one-time cost.
                await ContentBlocker.shared.precompile()
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BookmarkedArticle.self, ReadArticle.self], inMemory: true)
}
