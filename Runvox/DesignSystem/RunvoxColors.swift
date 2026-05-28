import SwiftUI

/// Runvox デザインフレームワーク準拠カラートークン
enum RunvoxColors {
    // Brand
    static let primary       = Color(hex: 0x00C2CC)
    static let primaryDark   = Color(hex: 0x009AA3)  // CTA / 強調用 (WCAG AA)
    static let primaryDeeper = Color(hex: 0x006D74)
    static let accentLime    = Color(hex: 0x7ED957)  // スター・成功
    static let accentLimeD   = Color(hex: 0x5CB83F)

    // Neutrals
    static let ink           = Color(hex: 0x0D1F22)
    static let inkSoft       = Color(hex: 0x2A4044)
    static let subtext       = Color(hex: 0x6B8A8E)
    static let border        = Color(hex: 0xD8ECEE)
    static let borderSoft    = Color(hex: 0xECF6F7)
    static let bgPage        = Color(hex: 0xF4FBFC)
    static let bgTint        = Color(hex: 0xE0F9FA)

    // Rank
    static let rankS         = Color(hex: 0xD9A923)
    static let rankA         = Color(hex: 0x8E9CA8)
    static let rankB         = Color(hex: 0xB57341)

    // Semantic
    static let success       = Color(hex: 0x00B85C)
    static let warning       = Color(hex: 0xE8A03B)
    static let danger        = Color(hex: 0xE63946)
}

extension Color {
    /// 0xRRGGBB 形式の 16 進数から Color を生成
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
