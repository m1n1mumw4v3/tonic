import SwiftUI

// MARK: - Design Tokens
// All colors, typography, spacing, and corner radii from the Ample design system.

enum DesignTokens {

    // MARK: - Backgrounds
    static let bgDeepest    = Color(hex: "#FAF8F3")
    static let bgSurface    = Color(hex: "#F2EFE8")
    static let bgElevated   = Color(hex: "#EBE7DF")

    // MARK: - Text
    static let textPrimary   = Color(hex: "#1C1E17")
    static let textSecondary = Color(hex: "#6B6E63")
    static let textTertiary  = Color(hex: "#A3A69B")

    // MARK: - Borders
    static let borderDefault = Color(hex: "#D9D5CC")
    static let borderSubtle  = Color(hex: "#E5E1D9")

    // MARK: - Dimension Accents
    static let accentSleep   = Color(hex: "#7B2D8E")
    static let accentEnergy  = Color(hex: "#E8C94A")
    static let accentClarity = Color(hex: "#4A8FC2")
    static let accentMood    = Color(hex: "#D4A017")
    static let accentGut     = Color(hex: "#B8C234")
    static let accentLongevity = Color(hex: "#2E9E9E")
    static let accentSkin      = Color(hex: "#C94277")

    // MARK: - Goal Accents
    static let accentMuscle    = Color(hex: "#3B5E3B")
    static let accentHeart     = Color(hex: "#D94040")
    static let accentImmunity  = Color(hex: "#1A6B6A")
    static let accentTerracotta = Color(hex: "#B07156")
    static let warmStone        = Color(hex: "#8C7E6A")

    // MARK: - Gradients
    static let spectrumGradient = LinearGradient(
        colors: [accentSleep, accentEnergy, accentClarity, accentMood, accentGut],
        startPoint: .leading, endPoint: .trailing
    )

    static let spectrumColors: [Color] = [accentSleep, accentEnergy, accentClarity, accentMood, accentGut]

    // MARK: - Functional
    static let positive = Color(hex: "#2E9E9E")
    static let negative = Color(hex: "#D94040")
    static let info     = Color(hex: "#4A8FC2")

    // MARK: - Typography
    static let displayFont   = Font.custom("Geist-Light", size: 32)
    static let sectionHeader = Font.custom("Geist-SemiBold", size: 13)
    static let bodyFont      = Font.custom("Geist-Regular", size: 16)
    static let dataMono      = Font.custom("GeistMono-Medium", size: 16)
    static let labelMono     = Font.custom("GeistMono-Regular", size: 11)

    // Pixel icon fonts (GeistPixel-Grid)
    static let pixelIconFont  = Font.custom("GeistPixel-Grid", size: 18)
    static let pixelIconSmall = Font.custom("GeistPixel-Grid", size: 14)
    static let pixelIconLarge = Font.custom("GeistPixel-Grid", size: 22)

    // Additional type sizes
    static let headlineFont  = Font.custom("Geist-Light", size: 28)
    static let titleFont     = Font.custom("Geist-SemiBold", size: 20)
    static let ctaFont       = Font.custom("Geist-SemiBold", size: 16)
    static let captionFont   = Font.custom("Geist-Regular", size: 13)
    static let smallMono     = Font.custom("GeistMono-Regular", size: 10)

    // MARK: - Spacing
    static let screenMargin: CGFloat = 20
    static let spacing2:  CGFloat = 2
    static let spacing4:  CGFloat = 4
    static let spacing8:  CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40
    static let spacing48: CGFloat = 48

    // MARK: - Corner Radii
    static let radiusSmall:  CGFloat = 8
    static let radiusMedium: CGFloat = 12
    static let radiusLarge:  CGFloat = 16
    static let radiusFull:   CGFloat = 999
}
