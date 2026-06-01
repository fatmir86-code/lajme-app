import SwiftUI

struct SettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var sourceCount: Int = 23 // 0=system, 1=light, 2=dark

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // PAMJA section — appearance mode
                    Text("PAMJA")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .tracking(0.8)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        appearanceRow(title: "Automatike", subtitle: "Ndjek cilësimet e sistemit", mode: 0, icon: "circle.lefthalf.filled")
                        Divider().padding(.leading, 56)
                        appearanceRow(title: "E ndritshme", subtitle: nil, mode: 1, icon: "sun.max")
                        Divider().padding(.leading, 56)
                        appearanceRow(title: "E errët", subtitle: nil, mode: 2, icon: "moon")
                    }
                    .padding(.horizontal, 20)

                    // TË TJERA section
                    Text("TË TJERA")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .tracking(0.8)
                        .padding(.horizontal, 20)
                        .padding(.top, 32)
                        .padding(.bottom, 12)

                    VStack(spacing: 0) {
                        // Contact us
                        Button {
                            if let url = URL(string: "mailto:fatmirmaloku1986@icloud.com?subject=Lajme%20App%20-%20Feedback") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            settingsRow(title: "Na kontaktoni", icon: "envelope")
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 20)

                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            settingsRow(title: "Politika e Privatësisë", icon: "chevron.right")
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 20)

                        NavigationLink {
                            TermsView()
                        } label: {
                            settingsRow(title: "Kushtet e Përdorimit", icon: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }

                    // Source count
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text("\(sourceCount) burime aktive")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(.secondaryLabel))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Footer
                    VStack(spacing: 4) {
                        Text("VERSIONI \(Bundle.main.marketingVersion) (BUILD \(Bundle.main.buildNumber))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(.quaternaryLabel))
                            .tracking(0.5)

                        Text("© 2026 Lajme Digital. Të gjitha të drejtat e rezervuara.")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(.quaternaryLabel))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Cilësimet")
                        .font(.system(size: 18, weight: .semibold, design: .serif))
                }
            }
        }
    }

    // MARK: - Appearance row

    @ViewBuilder
    private func appearanceRow(title: String, subtitle: String?, mode: Int, icon: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                appearanceMode = mode
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(appearanceMode == mode ? Color.primary : Color(.tertiaryLabel))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Spacer()

                Image(systemName: appearanceMode == mode ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(appearanceMode == mode ? Color.primary : Color(.tertiaryLabel))
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings rows

    @ViewBuilder
    private func settingsRow(title: String, icon: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

}

// MARK: - Bundle version helpers

extension Bundle {
    var marketingVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
