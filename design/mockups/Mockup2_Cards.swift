// MOCKUP 2: "Soft Cards"
// Känsla: Moderna kort med subtil skugga, mjuka hörn, kategori-färgkodning.
// Inspiration: Apple News, Flipboard
// Färger: Systemgrå bakgrund, vita kort, kategorifärger

import SwiftUI

struct Mockup2_Cards: View {
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {

                        // ── Header ───────────────────────────────────
                        HStack {
                            // Signal-logga (enkel kod-version)
                            HStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "D62828"))
                                        .frame(width: 34, height: 34)
                                    Text("L")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundStyle(.white)
                                }
                                Text("Lajme")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                            Button { } label: {
                                Image(systemName: "bell")
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                        // ── Category scroll ──────────────────────────
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Array(categoryColors.keys.sorted()), id: \.self) { cat in
                                    let isSelected = cat == "Aktuale"
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(categoryColors[cat] ?? .gray)
                                            .frame(width: 7, height: 7)
                                        Text(cat)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(isSelected ? (categoryColors[cat] ?? .gray).opacity(0.15) : Color(.systemBackground))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(isSelected ? (categoryColors[cat] ?? .gray) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                        }

                        // ── Breaking banner ──────────────────────────
                        HStack(spacing: 8) {
                            Text("⚡")
                            Text("LAJM I FUNDIT")
                                .font(.caption)
                                .fontWeight(.black)
                                .foregroundStyle(Color(hex: "D62828"))
                            Text("Kuvendi miraton buxhetin e shtetit")
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "D62828").opacity(0.07))
                        .padding(.horizontal, 16)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.bottom, 12)

                        // ── Article cards ────────────────────────────
                        LazyVStack(spacing: 12) {
                            ForEach(previewArticles) { article in
                                VStack(alignment: .leading, spacing: 10) {
                                    // Category tag
                                    HStack {
                                        Text(article.category)
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(categoryColors[article.category] ?? .gray)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background((categoryColors[article.category] ?? .gray).opacity(0.1))
                                            .clipShape(Capsule())
                                        Spacer()
                                        Text(article.time)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(article.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .lineLimit(3)

                                    HStack {
                                        Text(article.source)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Image(systemName: "bookmark")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(16)
                                .background(Color(.systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    let categoryColors: [String: Color] = [
        "Aktuale": Color(hex: "D62828"),
        "Politikë": Color(hex: "1D3557"),
        "Sport": Color(hex: "2D6A4F"),
        "Ekonomi": Color(hex: "E76F51"),
        "Botë": Color(hex: "6B4EFF"),
    ]
}

#Preview {
    Mockup2_Cards()
}
