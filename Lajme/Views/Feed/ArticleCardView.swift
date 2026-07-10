import SwiftUI

struct ArticleCardView: View {
    let article: Article
    var isRead: Bool = false
    var isBookmarked: Bool = false
    let onShare: () -> Void
    var onToggleBookmark: (() -> Void)? = nil
    var onOpenRelated: ((RelatedSource) -> Void)? = nil

    /// Filter HTTP image URLs to avoid silent ATS failures.
    private var httpsImageURL: URL? {
        guard let s = article.imageUrl, s.hasPrefix("https://") else { return nil }
        return URL(string: s)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Source row: NAME · CATEGORY · TIME                        [share]
            HStack(spacing: 4) {
                if let sourceName = article.source?.name, !sourceName.isEmpty {
                    Text(sourceName.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .tracking(0.5)
                        .accessibilityLabel(sourceName + ", " + (article.source?.country.map(countryName) ?? ""))

                    if let slug = article.categorySlug {
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(Category.displayName(for: slug).uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(.secondaryLabel))
                            .tracking(0.5)
                    }

                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(.tertiaryLabel))
                }

                Text(article.publishedAt.timeAgoAlbanian)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(.tertiaryLabel))

                Spacer()

                if let onToggleBookmark {
                    Button {
                        HapticManager.light()
                        onToggleBookmark()
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 14))
                            .foregroundStyle(isBookmarked ? Color.primary : Color(.tertiaryLabel))
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isBookmarked ? "Hiq nga të ruajturat" : "Ruaj lajmin")
                }

                Button {
                    onShare()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ndaj lajmin")
            }
            .padding(.bottom, 6)

            // Headline + optional thumbnail (image on the right)
            HStack(alignment: .top, spacing: 12) {
                Text(article.title)
                    .font(.system(size: 17, weight: isRead ? .regular : .bold, design: .serif))
                    .foregroundStyle(Color.primary)
                    .lineLimit(4)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                if let imageUrl = httpsImageURL {
                    CachedAsyncImage(url: imageUrl)
                        .frame(width: 84, height: 84)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .accessibilityHidden(true)
                }
            }
            .padding(.bottom, 8)

            // Related sources with label "RAPORTUAR EDHE NGA"
            if let related = article.relatedSources, !related.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("RAPORTUAR EDHE NGA")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .tracking(0.8)

                    RelatedSourcesInlineView(sources: related, onTap: { source in
                        onOpenRelated?(source)
                    })
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
        .accessibilityElement(children: .contain)
        .accessibilityHint("Trokit për të lexuar lajmin")
    }

    private func countryName(_ code: String) -> String {
        switch code {
        case "XK": return "Kosovë"
        case "AL": return "Shqipëri"
        case "MK": return "Maqedoni"
        case "CH", "DE", "AT", "BE", "FR", "IT", "SE", "NO", "DK", "GB", "US": return "Diaspora"
        case "RS": return "Lugina e Preshevës"
        default: return code
        }
    }
}

// MARK: - Related sources — minimal inline format

struct RelatedSourcesInlineView: View {
    let sources: [RelatedSource]
    let onTap: (RelatedSource) -> Void

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                Button {
                    onTap(source)
                } label: {
                    // Include the separator as a prefix on all items except the first,
                    // so it wraps with the source name rather than hanging on its own line.
                    Text(index == 0 ? source.name : "· \(source.name)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Hap artikullin nga \(source.name)")
            }
        }
    }
}

// A simple flow layout that wraps children to next line when out of width.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                totalWidth = max(totalWidth, x - spacing)
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        totalWidth = max(totalWidth, x - spacing)
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Shared utilities

enum HapticManager {
    private static let lightGenerator: UIImpactFeedbackGenerator = {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.prepare()
        return g
    }()

    static func light() {
        lightGenerator.impactOccurred()
    }
}
