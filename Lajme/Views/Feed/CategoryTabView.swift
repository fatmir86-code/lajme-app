import SwiftUI

struct CategoryTabView: View {
    let categories: [Category]
    @Binding var selectedSlug: String
    let onSelect: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(categories) { category in
                        Button {
                            onSelect(category.slug)
                        } label: {
                            VStack(spacing: 6) {
                                Text(category.name)
                                    .font(.system(size: 18, weight: selectedSlug == category.slug ? .bold : .medium))
                                    .foregroundStyle(
                                        selectedSlug == category.slug
                                            ? Color.primary
                                            : Color(.tertiaryLabel)
                                    )

                                // Underline indicator
                                Rectangle()
                                    .fill(selectedSlug == category.slug ? Color.primary : Color.clear)
                                    .frame(height: 2)
                            }
                            .animation(.easeInOut(duration: 0.2), value: selectedSlug)
                        }
                        .id(category.slug)
                        .accessibilityValue(selectedSlug == category.slug ? "I zgjedhur" : "")
                        .accessibilityHint("Trokit për të filtruar lajmet")
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: selectedSlug) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }
}
