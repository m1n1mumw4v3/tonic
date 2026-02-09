import SwiftUI

// MARK: - Design Tokens
// All colors, typography, spacing, and corner radii from the Tonic design system.

enum DesignTokens {

    // MARK: - Backgrounds
    static let bgDeepest    = Color(hex: "#0E1025")
    static let bgSurface    = Color(hex: "#141733")
    static let bgElevated   = Color(hex: "#1B1F42")

    // MARK: - Text
    static let textPrimary   = Color(hex: "#D6DEEB")
    static let textSecondary = Color(hex: "#7E8CA8")
    static let textTertiary  = Color(hex: "#4A5274")

    // MARK: - Borders
    static let borderDefault = Color(hex: "#1F2347")
    static let borderSubtle  = Color(hex: "#181C3A")

    // MARK: - Dimension Accents
    static let accentSleep   = Color(hex: "#C792EA")
    static let accentEnergy  = Color(hex: "#FFCB6B")
    static let accentClarity = Color(hex: "#82AAFF")
    static let accentMood    = Color(hex: "#F78C6C")
    static let accentGut     = Color(hex: "#C3E88D")
    static let accentLongevity = Color(hex: "#80CBC4")

    // MARK: - Functional
    static let positive = Color(hex: "#7FE0A0")
    static let negative = Color(hex: "#FF5572")
    static let info     = Color(hex: "#89DDFF")

    // MARK: - Typography
    static let displayFont   = Font.custom("Geist-Light", size: 32)
    static let sectionHeader = Font.custom("Geist-SemiBold", size: 13)
    static let bodyFont      = Font.custom("Geist-Regular", size: 16)
    static let dataMono      = Font.custom("GeistMono-Medium", size: 16)
    static let labelMono     = Font.custom("GeistMono-Regular", size: 11)

    // Additional type sizes
    static let headlineFont  = Font.custom("Geist-Light", size: 28)
    static let titleFont     = Font.custom("Geist-SemiBold", size: 20)
    static let ctaFont       = Font.custom("Geist-SemiBold", size: 16)
    static let captionFont   = Font.custom("Geist-Regular", size: 13)
    static let smallMono     = Font.custom("GeistMono-Regular", size: 10)

    // MARK: - Spacing
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
