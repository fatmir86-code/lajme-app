import SwiftUI

/// Thumbnail cache. AsyncImage keeps no decoded-image cache and re-fetches on
/// every cell reuse; article image URLs are immutable, so cache aggressively.
enum ImageCache {
    static let memory: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 300
        return cache
    }()

    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 200 * 1024 * 1024
        )
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()
}

/// Drop-in replacement for the AsyncImage usage in article cards:
/// gray placeholder while loading or on failure, cached image on success.
struct CachedAsyncImage: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray6))
            }
        }
        .task(id: url) {
            await load()
        }
    }

    private func load() async {
        if let cached = ImageCache.memory.object(forKey: url as NSURL) {
            image = cached
            return
        }
        guard let (data, _) = try? await ImageCache.session.data(from: url),
              let downloaded = UIImage(data: data) else { return }
        ImageCache.memory.setObject(downloaded, forKey: url as NSURL)
        withAnimation(.easeIn(duration: 0.2)) {
            image = downloaded
        }
    }
}
