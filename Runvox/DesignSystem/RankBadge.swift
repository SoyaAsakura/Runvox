import SwiftUI

/// 回答者ランク S / A / B
enum Rank: String, CaseIterable, Codable {
    case s = "S"
    case a = "A"
    case b = "B"

    /// ポイント計算用の歩率
    var multiplier: Double {
        switch self {
        case .s: return 2.0
        case .a: return 1.5
        case .b: return 1.0
        }
    }

    /// バッジ用グラデーション
    var gradient: LinearGradient {
        switch self {
        case .s:
            return LinearGradient(
                colors: [
                    Color(hex: 0xF4D06F),
                    Color(hex: 0xD9A923),
                    Color(hex: 0xA37614),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .a:
            return LinearGradient(
                colors: [
                    Color(hex: 0xC8D2DA),
                    Color(hex: 0x8E9CA8),
                    Color(hex: 0x5F6B75),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .b:
            return LinearGradient(
                colors: [
                    Color(hex: 0xD49773),
                    Color(hex: 0xB57341),
                    Color(hex: 0x7F4E2A),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// 円形のランクバッジ表示
struct RankBadge: View {
    let rank: Rank
    var size: CGFloat = 28

    var body: some View {
        Text(rank.rawValue)
            .font(.system(size: size * 0.5, weight: .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(rank.gradient)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            RankBadge(rank: .s)
            RankBadge(rank: .a)
            RankBadge(rank: .b)
        }
        HStack(spacing: 16) {
            RankBadge(rank: .s, size: 56)
            RankBadge(rank: .a, size: 56)
            RankBadge(rank: .b, size: 56)
        }
    }
    .padding()
}
