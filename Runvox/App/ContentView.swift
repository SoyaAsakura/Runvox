import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            RunvoxColors.bgPage.ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Logo
                HStack(spacing: 0) {
                    Text("Run")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(RunvoxColors.ink)
                    Text(".")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(RunvoxColors.primary)
                    Text("vox")
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(RunvoxColors.ink)
                }

                Text("走る人の知恵が、走る人を強くする")
                    .font(.system(size: 13))
                    .foregroundStyle(RunvoxColors.subtext)

                Spacer()

                // Demo: Rank badges
                HStack(spacing: 16) {
                    RankBadge(rank: .s, size: 56)
                    RankBadge(rank: .a, size: 56)
                    RankBadge(rank: .b, size: 56)
                }

                // Demo: Star rating
                StarRating(rating: 4, size: 24)

                // Demo: Point calculation
                Text("★4 × Sランク = \(PointCalculator.calculate(stars: 4, rank: .s))pt")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(RunvoxColors.primaryDeeper)
                    .padding(.top, 8)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
