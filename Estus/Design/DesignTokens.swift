import SwiftUI

// MARK: - Design Tokens
// All colors, typography, spacing, and corner radii from the Estus design system.

enum DesignTokens {

    // MARK: - Backgrounds
    static let bgDeepest    = Color(hex: "#E3E3E3")
    static let bgSurface    = Color(hex: "#FFFFFF")
    static let bgElevated   = Color(hex: "#F0F0F0")

    // MARK: - Text
    static let textPrimary   = Color(hex: "#0C0D0D")
    static let textSecondary = Color(hex: "#6B6E63")
    static let textTertiary  = Color(hex: "#A3A69B")

    // MARK: - Borders
    static let borderDefault = Color(hex: "#EBEBEB")
    static let borderSubtle  = Color(hex: "#F2F2F2")

    // MARK: - Dimension Accents
    static let accentSleep   = Color(hex: "#8F3B43")
    static let accentEnergy  = Color(hex: "#C25D93")
    static let accentClarity = Color(hex: "#6A93DE")
    static let accentMood    = Color(hex: "#96953F")
    static let accentGut     = Color(hex: "#E0B23D")
    static let accentLongevity = Color(hex: "#42467A")
    static let accentSkin      = Color(hex: "#9462BF")

    // MARK: - Goal Accents
    static let accentMuscle    = Color(hex: "#F2A150")
    static let accentHeart     = Color(hex: "#E66363")
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

    // MARK: - Icon Sizes
    static let iconSizeSmall:  CGFloat = 30   // log row
    static let iconSizeMedium: CGFloat = 38   // recommendation card
    static let iconSizeLarge:  CGFloat = 44   // pillbox compartment

    // MARK: - Darkened Icon Foregrounds (for low-contrast accents on light bg)
    static let iconFgEnergy = Color(hex: "#C25D93")
    static let iconFgMood   = Color(hex: "#96953F")
    static let iconFgGut    = Color(hex: "#E0B23D")

    // MARK: - Typography
    static let displayFont   = Font.custom("Geist-Regular", size: 32)
    static let sectionHeader = Font.custom("Geist-SemiBold", size: 13)
    static let bodyFont      = Font.custom("Geist-Regular", size: 16)
    static let dataMono      = Font.custom("GeistMono-Medium", size: 16)
    static let labelMono     = Font.custom("GeistMono-Regular", size: 11)

    // Pixel icon fonts (GeistPixel-Grid)
    static let pixelIconFont  = Font.custom("GeistPixel-Grid", size: 18)
    static let pixelIconSmall = Font.custom("GeistPixel-Grid", size: 14)
    static let pixelIconLarge = Font.custom("GeistPixel-Grid", size: 22)

    // Additional type sizes
    static let headlineFont  = Font.custom("Geist-Regular", size: 28)
    static let titleFont     = Font.custom("Geist-SemiBold", size: 20)
    static let ctaFont       = Font.custom("Geist-SemiBold", size: 16)
    static let captionFont   = Font.custom("Geist-Regular", size: 13)
    static let smallMono     = Font.custom("GeistMono-Regular", size: 10)

    // MARK: - Spacing
    static let screenMargin: CGFloat = 18
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

    // MARK: - Shadows
    static let cardShadowColor   = Color.black.opacity(0.04)
    static let cardShadowRadius:  CGFloat = 8
    static let cardShadowY:       CGFloat = 3
}
