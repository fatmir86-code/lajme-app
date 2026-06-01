// MOCKUP 1: "Nordic Minimal"
// Känsla: Ren, luftig, typografi i fokus. Ingen box-shadow, inga kort.
// Inspiration: Dagens Nyheter, Financial Times
// Färger: Vit bakgrund, #111 text, #D62828 accent

import SwiftUI

struct Mockup1_Minimal: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Header ──────────────────────────────────────
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(hex: "D62828"))
                                    .frame(width: 4, height: 28)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))
                                Text("LAJME")
                                    .font(.system(size: 26, weight: .black))
                                    .tracking(-0.5)
                                    .foregroundStyle(.primary)
                                    .padding(.leading, 8)
                            }
                            Text(Date().formatted(.dateTime.weekday(.wide).day().month()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title3)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Divider()

                    // ── Category pills ───────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(["Të gjitha", "Aktuale", "Politikë", "Sport", "Ekonomi", "Botë"], id: \.self) { cat in
                                let isSelected = cat == "Të gjitha"
                                Text(cat)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(isSelected ? Color(hex: "D62828") : Color(.systemGray6))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }

                    Divider()

                    // ── Article list ─────────────────────────────────
                    LazyVStack(spacing: 0) {
                        ForEach(previewArticles) { article in
                            VStack(alignment: .leading, spacing: 6) {
                                // Source + time
                                HStack {
                                    Text(article.source)
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color(hex: "D62828"))
                                    Text("·")
                                        .foregroundStyle(.tertiary)
                                    Text(article.time)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    if article.isBreaking {
                                        Text("LAJM I FUNDIT")
                                            .font(.caption2)
                                            .fontWeight(.black)
                                            .foregroundStyle(Color(hex: "D62828"))
                                    }
                                    Spacer()
                                }

                                Text(article.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(article.category)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)

                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// ── Preview data ─────────────────────────────────────────────────────────────
struct PreviewArticle: Identifiable {
    let id = UUID()
    let source, time, title, category: String
    var isBreaking = false
}

let previewArticles = [
    PreviewArticle(source: "Gazeta Express", time: "3 min", title: "Kuvendi miraton buxhetin e shtetit për vitin 2026 me votat e koalicionit qeverisës", category: "Politikë", isBreaking: true),
    PreviewArticle(source: "Indeksonline", time: "14 min", title: "Banka Qendrore e Kosovës rrit normën bazë të interesit për herë të tretë këtë vit", category: "Ekonomi"),
    PreviewArticle(source: "Lajmi.net", time: "28 min", title: "Kombëtarja shqiptare fiton ndeshjen miqësore ndaj Sllovakisë me rezultat 2-0", category: "Sport"),
    PreviewArticle(source: "Telegrafi", time: "45 min", title: "Bashkimi Evropian hap negociatat e reja me Shqipërinë dhe Kosovën", category: "Botë"),
    PreviewArticle(source: "Koha.net", time: "1 orë", title: "Qeveria miraton paketën e re të investimeve në infrastrukturë rrugore", category: "Aktuale"),
]

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    Mockup1_Minimal()
}
