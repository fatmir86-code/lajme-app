import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Kushtet e Përdorimit")
                    .font(.system(size: 24, weight: .bold, design: .serif))
                    .padding(.bottom, 4)

                Text("Përditësuar: Prill 2026")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(.secondaryLabel))

                section("1. Pranimi i kushteve") {
                    """
                    Duke përdorur aplikacionin Lajme, ju pranoni këto kushte përdorimi. Nëse nuk pajtoheni, ju lutemi mos e përdorni aplikacionin.
                    """
                }

                section("2. Përshkrimi i shërbimit") {
                    """
                    Lajme është një agregator lajmesh që mbledh titujt e lajmeve nga burime të ndryshme publike shqipfolëse. Aplikacioni nuk krijon përmbajtje origjinale. Kur trokitni një lajm, do të ridrejtoheni tek faqja origjinale e burimit.
                    """
                }

                section("3. Përmbajtja") {
                    """
                    Ne nuk jemi përgjegjës për saktësinë, plotësinë, apo cilësinë e përmbajtjes nga burimet e lajmeve. Çdo përmbajtje i përket botuesit origjinal dhe mbulohet nga kushtet e tyre të përdorimit.
                    """
                }

                section("4. Përdorimi i lejuar") {
                    """
                    Ju mund të përdorni Lajme për qëllime personale dhe jokomerciale. Nuk lejohet:
                    • Kopjimi sistematik i të dhënave nga aplikacioni
                    • Përdorimi i aplikacionit për qëllime të paligjshme
                    • Tentimi për të ndërhyrë në funksionimin e aplikacionit
                    """
                }

                section("5. Disponueshmëria") {
                    """
                    Ne përpiqemi të mbajmë aplikacionin funksional në çdo kohë, por nuk garantojmë disponueshmëri të pandërprerë. Shërbimi mund të ndërpritet për mirëmbajtje apo arsye të tjera teknike.
                    """
                }

                section("6. Ndryshimet") {
                    """
                    Rezervojmë të drejtën të ndryshojmë këto kushte në çdo kohë. Vazhdimi i përdorimit pas ndryshimeve përbën pranim të kushteve të reja.
                    """
                }

                section("7. Kontakti") {
                    """
                    Për pyetje rreth kushteve të përdorimit:
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
