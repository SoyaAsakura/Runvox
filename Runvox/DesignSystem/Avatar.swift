import SwiftUI

/// 円形のユーザーアバター
///
/// 画像 URL があれば AsyncImage で表示、なければ initial を背景色で描画。
/// `rank` 指定でランクバッジを右下に重ねる。
struct Avatar: View {
    let initial: String
    var imageURL: URL?
    var size: CGFloat = 40
    var rank: Rank?

    private var initialChar: String {
        String(initial.prefix(1))
    }

    private var fontSize: CGFloat {
        max(11, size * 0.42)
    }

    private var badgeSize: CGFloat {
        max(16, size * 0.38)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarCircle
            if let rank {
                RankBadge(rank: rank, size: badgeSize)
                    .overlay(
                        Circle().stroke(.white, lineWidth: max(1.5, size * 0.04))
                    )
                    .offset(x: 2, y: 2)
            }
        }
        .frame(width: size + (rank != nil ? 4 : 0),
               height: size + (rank != nil ? 4 : 0),
               alignment: .topLeading)
    }

    @ViewBuilder
    private var avatarCircle: some View {
        ZStack {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure, .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .background(
            LinearGradient(
                colors: [RunvoxColors.bgTint, RunvoxColors.border],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Circle())
        .overlay(
            Circle().stroke(RunvoxColors.border, lineWidth: size > 60 ? 3 : 1)
        )
    }

    private var placeholder: some View {
        Text(initialChar)
            .font(.system(size: fontSize, weight: .bold))
            .foregroundStyle(RunvoxColors.primaryDark)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("Sizes").font(.caption).foregroundStyle(.secondary)
        HStack(alignment: .bottom, spacing: 12) {
            Avatar(initial: "タ", size: 22)
            Avatar(initial: "タ", size: 32)
            Avatar(initial: "タ", size: 40)
            Avatar(initial: "田", size: 56)
            Avatar(initial: "田", size: 84)
        }

        Text("With Rank Badge").font(.caption).foregroundStyle(.secondary)
        HStack(spacing: 16) {
            Avatar(initial: "田", size: 40, rank: .s)
            Avatar(initial: "佐", size: 40, rank: .a)
            Avatar(initial: "y", size: 40, rank: .b)
            Avatar(initial: "田", size: 84, rank: .s)
        }

        Text("With Image (URL)").font(.caption).foregroundStyle(.secondary)
        HStack(spacing: 16) {
            Avatar(
                initial: "田",
                imageURL: URL(string: "https://i.pravatar.cc/200"),
                size: 56,
                rank: .s
            )
        }
    }
    .padding()
    .background(RunvoxColors.bgPage)
}
