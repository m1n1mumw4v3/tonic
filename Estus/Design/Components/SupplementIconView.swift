import SwiftUI

struct SupplementIconView: View {
    let config: SupplementIconConfig
    let size: CGFloat
    var isTaken: Bool = false
    var useRoundedRect: Bool = false

    private var accent: Color { config.accentColor }

    private var foregroundColor: Color {
        if accent == DesignTokens.accentEnergy {
            return DesignTokens.iconFgEnergy
        } else if accent == DesignTokens.accentMood {
            return DesignTokens.iconFgMood
        } else if accent == DesignTokens.accentGut {
            return DesignTokens.iconFgGut
        }
        return accent
    }

    private var pixelFont: Font {
        let count = config.abbreviation.count
        switch size {
        case ...DesignTokens.iconSizeSmall:
            switch count {
            case 1:    return Font.custom("GeistPixel-Grid", size: 14)
            case 2:    return Font.custom("GeistPixel-Grid", size: 13)
            default:   return Font.custom("GeistPixel-Grid", size: 10)
            }
        case ...DesignTokens.iconSizeMedium:
            switch count {
            case 1:    return Font.custom("GeistPixel-Grid", size: 16)
            case 2:    return Font.custom("GeistPixel-Grid", size: 15)
            default:   return Font.custom("GeistPixel-Grid", size: 11)
            }
        default:
            switch count {
            case 1:    return Font.custom("GeistPixel-Grid", size: 18)
            case 2:    return Font.custom("GeistPixel-Grid", size: 17)
            default:   return Font.custom("GeistPixel-Grid", size: 13)
            }
        }
    }

    private var cornerRadius: CGFloat {
        useRoundedRect ? DesignTokens.radiusSmall : size / 2
    }

    var body: some View {
        Text(config.abbreviation)
            .font(pixelFont)
            .foregroundStyle(foregroundColor.opacity(isTaken ? 0.5 : 1.0))
            .frame(width: size, height: size)
            .background(accent.opacity(isTaken ? 0.1 : 0.18))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accent.opacity(isTaken ? 0.15 : 0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}
