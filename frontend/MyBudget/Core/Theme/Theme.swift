import SwiftUI
import UIKit

enum Theme {

    static let background   = Color(hex: 0x000000)
    static let surface      = Color(hex: 0x161620)
    static let neutral900   = Color(hex: 0x101016)
    static let neutral800   = Color(hex: 0x20202A)
    static let neutral400   = Color(hex: 0x9A9AA8)

    static let text  = Color(hex: 0xF3F3F6)
    static let muted = Color.white.opacity(0.56)
    static let faint = Color.white.opacity(0.34)

    static let divider = Color.white.opacity(0.11)

    static let accent    = Color(hex: 0xA78BFA)
    static let accent900 = Color(hex: 0x2B2741)
    static let accent300 = Color(hex: 0xD2CEFD)
    static let accent200 = Color(hex: 0xE7E5FE)

    static let positive = Color(hex: 0x3ECF8E)
    static let negative = Color(hex: 0xFF5C72)

    static let glassCardFill  = Color.white.opacity(0.055)
    static let glassBarFill   = Color.white.opacity(0.07)
    static let glassInputFill = Color.white.opacity(0.05)

    static let glassCardBorder = Color.white.opacity(0.10)
    static let glassBarBorder  = Color.white.opacity(0.14)
    static let glassInputBorder = Color.white.opacity(0.13)

    static let specularCard = Color.white.opacity(0.14)
    static let specularBar  = Color.white.opacity(0.22)

    static let glowViolet = Color(hex: 0xA78BFA).opacity(0.22)
    static let glowBlue   = Color(hex: 0x4D9BFF).opacity(0.17)
    static let glowTeal   = Color(hex: 0x38D6D6).opacity(0.14)

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: scaled(size), weight: weight)
    }

    static func mono(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: scaled(size), weight: weight, design: .monospaced)
    }

    private static func scaled(_ size: CGFloat) -> CGFloat {
        let metrics = UIFontMetrics(forTextStyle: textStyle(for: size))
        return min(metrics.scaledValue(for: size), size * 1.4)
    }

    private static func textStyle(for size: CGFloat) -> UIFont.TextStyle {
        switch size {
        case ..<11: return .caption2
        case ..<13: return .caption1
        case ..<15: return .footnote
        case ..<17: return .body
        case ..<22: return .title3
        case ..<28: return .title1
        default: return .largeTitle
        }
    }

    static let screenPadding: CGFloat = 22
    static let heroRadius: CGFloat = 18
    static let cardRadius: CGFloat = 14
    static let statRadius: CGFloat = 12
    static let chipRadius: CGFloat = 12
    static let controlRadius: CGFloat = 10
    static let inputRadius: CGFloat = 8
    static let tileRadius: CGFloat = 9
    static let trackRadius: CGFloat = 3
    static let tabBarRadius: CGFloat = 28

    static let trackHeight: CGFloat = 6
    static let inputHeight: CGFloat = 36
    static let primaryButtonHeight: CGFloat = 48
    static let minHitTarget: CGFloat = 44

    static let tabBarClearance: CGFloat = 96
    static let tabBarHiddenOffset: CGFloat = 130
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
