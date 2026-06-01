// MOCKUP 3: "Magazine"
// Känsla: Tidningskänsla med featured story-hero i toppen, kompakt lista under.
// Inspiration: BBC News, Le Monde
// Färger: Rent vitt, stark typografi, röd accent

import SwiftUI

struct Mockup3_Magazine: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // ── Masthead ─────────────────────────────────────
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Text(Date().formatted(.dateTime.weekday(.wide).day().month().year()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.top, 10)

                        Text("LAJME")
                            .font(.system(size: 42, weight: .black))
                            .tracking(6)
                            .foregroundStyle(.primary)
                            .padding(.vertical, 4)

                        Rectangle()
                            .fill(.primary)
                            .frame(height: 2)
                            .padding(.horizontal, 20)

                        Rectangle()
                            .fill(Color(hex: "D62828"))
                            .frame(height: 4)
                            .padding(.horizontal, 20)
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 16)

                    // ── Featured story ───────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        // Placeholder image area
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color(.systemGray5))
                                .frame(height: 200)
                            LinearGradient(
                                colors: [.clear, .black.opacity(0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚡ LAJM I FUNDIT")
                                    .font(.caption2)
                                    .fontWeight(.black)
                                    .foregroundStyle(Color(hex: "D62828"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.white)
                                    .clipShape(Capsule())
                                Text("Kuvendi miraton buxhetin e shtetit për vitin 2026")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                HStack {
                                    Text("Gazeta Express")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("· 3 min")
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                            .padding(14)
                        }
                    }

                    // ── Section header ───────────────────────────────
                    HStack {
                        Text("LAJMET E FUNDIT")
                            .font(.caption)
                            .fontWeight(.black)
                            .foregroundStyle(Color(hex: "D62828"))
                            .tracking(1.5)
                        Spacer()
                        Text("Shiko të gjitha")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                    Rectangle()
                        .fill(Color(.separator))
                        .frame(height: 0.5)
                        .padding(.horizontal, 20)

                    // ── Article list (2-col on first 2, then single) ──
                    LazyVStack(spacing: 0) {
                        ForEach(Array(previewArticles.dropFirst().enumerated()), id: \.offset) { _, article in
                            HStack(alignment: .top, spacing: 12) {
                                // Color accent bar by category
                                Rectangle()
                                    .fill(Color(hex: "D62828").opacity(0.15))
                                    .frame(width: 3)
                                    .clipShape(RoundedRectangle(cornerRadius: 2))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(article.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .lineLimit(2)

                                    HStack(spacing: 4) {
                                        Text(article.source)
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundStyle(Color(hex: "D62828"))
                                        Text("·")
                                            .foregroundStyle(.tertiary)
                                            .font(.caption2)
                                        Text(article.time)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text(article.category)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)

                            Rectangle()
                                .fill(Color(.separator))
                                .frame(height: 0.5)
                                .padding(.horizontal, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    Mockup3_Magazine()
}
