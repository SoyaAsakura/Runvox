import SwiftUI

/// ★評価の表示用コンポーネント
struct StarRating: View {
    let rating: Int           // 0〜5
    var maxStars: Int = 5
    var size: CGFloat = 14
    var color: Color = RunvoxColors.accentLime
    var dimColor: Color = Color(hex: 0xDDE7E9)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxStars, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(i <= rating ? color : dimColor)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        StarRating(rating: 5)
        StarRating(rating: 4)
        StarRating(rating: 3)
        StarRating(rating: 2)
        StarRating(rating: 1)
        StarRating(rating: 0)
        StarRating(rating: 4, size: 28)
    }
    .padding()
}
