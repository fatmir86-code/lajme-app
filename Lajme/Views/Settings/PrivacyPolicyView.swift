import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Politika e Privatësisë")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .padding(.bottom, 4)

                Text("Përditësuar: Prill 2026")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))

                section("1. Të dhënat që mbledhim") {
                    """
                    Lajme nuk mbledh asnjë të dhënë personale. Nuk kemi llogari përdoruesi, nuk kërkojmë email, emër, apo informacion tjetër personal.

                    Aplikacioni ruan lokalisht në pajisjen tuaj:
                    • Lajmet e ruajtura (bookmarks)
                    • Historinë e leximit (cilat lajme keni hapur)
                    • Preferencat e pamjes (dark mode)

                    Këto të dhëna ruhen vetëm në telefonin tuaj dhe nuk dërgohen kurrë në serverët tanë.
                    """
                }

                section("2. Si i përdorim të dhënat") {
                    """
                    Të dhënat lokale përdoren vetëm për të përmirësuar përvojën tuaj në aplikacion — për të shfaqur lajmet e ruajtura, për të treguar cilat lajme i keni lexuar tashmë, dhe për të mbajtur preferencat tuaja.
                    """
                }

                section("3. Burimet e lajmeve") {
                    """
                    Lajme agregan titujt e lajmeve nga burime të ndryshme publike në internet. Ne nuk krijojmë përmbajtje origjinale. Kur trokitni një lajm, hapni faqen origjinale të burimit në shfletuesin e integruar.

                    Të gjitha të drejtat e përmbajtjes i përkasin botuesve origjinalë.
                    """
                }

                section("4. Shërbimet e palëve të treta") {
                    """
                    Aktualisht Lajme nuk përdor asnjë shërbim analitik, reklamash, apo gjurmimi nga palë të treta. Nëse kjo ndryshon në të ardhmen, do të përditësojmë këtë politikë.
                    """
                }

                section("5. Siguria") {
                    """
                    Meqenëse nuk mbledhim të dhëna personale, nuk ka rrezik të ekspozimit të tyre. Të dhënat lokale mbrohen nga mekanizmat e sigurisë së iOS.
                    """
                }

                section("6. Fëmijët") {
                    """
                    Lajme nuk mbledh të dhëna nga asnjë përdorues, përfshirë fëmijët. Aplikacioni shfaq vetëm tituj lajmesh nga burime publike.
                    """
                }

                section("7. Ndryshimet") {
                    """
                    Mund të përditësojmë këtë politikë herë pas here. Ndryshimet do të pasqyrohen në këtë faqe me datën e përditësimit.
                    """
                }

                section("8. Kontakti") {
                    """
                    Për pyetje rreth privatësisë, na kontaktoni:
                    fatmirmaloku1986@icloud.com
                    """
                }
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func section(_ title: String, content: () -> String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Text(content())
                .font(.system(size: 14))
                .foregroundStyle(Color(.secondaryLabel))
                .lineSpacing(4)
        }
    }
}
