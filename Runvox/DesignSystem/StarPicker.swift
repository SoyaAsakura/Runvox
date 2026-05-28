import SwiftUI

/// インタラクティブな★評価ピッカー
///
/// 表示専用の `StarRating` と異なり、タップで値を変更できる。
struct StarPicker: View {
    @Binding var rating: Int
    var maxStars: Int = 5
    var size: CGFloat = 40
    var spacing: CGFloat = 10
    var color: Color = RunvoxColors.accentLime
    var dimColor: Color = Color(hex: 0xDDE7E9)

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxStars, id: \.self) { i in
                star(at: i)
            }
        }
    }

    private func star(at index: Int) -> some View {
        Button {
            rating = (rating == index) ? 0 : index
        } label: {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(index <= rating ? color : dimColor)
                .scaleEffect(scale(for: index))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(index) 段階目")
    }

    private func scale(for index: Int) -> CGFloat {
        if index == rating { return 1.18 }
        if index < rating { return 1.05 }
        return 1.0
    }
}

#Preview {
    StarPickerPreviewHost()
        .padding()
        .background(RunvoxColors.bgPage)
}

private struct StarPickerPreviewHost: View {
    @State private var rating: Int = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Selected: \(rating)").font(.headline)
            StarPicker(rating: $rating)
            StarPicker(rating: $rating, size: 24, spacing: 4)
        }
    }
}
