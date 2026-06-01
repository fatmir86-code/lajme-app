import SwiftUI
import StoreKit

struct ContentView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @AppStorage("sessionCount") private var sessionCount: Int = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview: Bool = false
    @Environment(\.requestReview) private var requestReview

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
            .onAppear {
                sessionCount += 1
                if sessionCount >= 5 && !hasRequestedReview {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        requestReview()
                        hasRequestedReview = true
                    }
                }
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [BookmarkedArticle.self, ReadArticle.self], inMemory: true)
}
