import SwiftUI

// MARK: - Icon Type

enum SupplementIconType {
    case pixelText(String)
    case sfSymbol(String)
}

// MARK: - Icon Config

struct SupplementIconConfig {
    let iconType: SupplementIconType
    let accentColor: Color
}

// MARK: - Icon Registry

enum SupplementIconRegistry {

    static func config(for supplementName: String) -> SupplementIconConfig {
        let key = supplementName.lowercased()

        // Pixel text icons
        if key.contains("magnesium") {
            return SupplementIconConfig(iconType: .pixelText("Mg"), accentColor: DesignTokens.accentSleep)
        }
        if key.contains("vitamin d") || key.contains("d3") {
            return SupplementIconConfig(iconType: .pixelText("D3"), accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("l-theanine") || key.contains("theanine") {
            return SupplementIconConfig(iconType: .pixelText("L-T"), accentColor: DesignTokens.accentClarity)
        }
        if key.contains("vitamin b") && key.contains("complex") {
            return SupplementIconConfig(iconType: .pixelText("B"), accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("zinc") {
            return SupplementIconConfig(iconType: .pixelText("Zn"), accentColor: DesignTokens.accentGut)
        }
        if key.contains("vitamin c") {
            return SupplementIconConfig(iconType: .pixelText("C"), accentColor: DesignTokens.accentMood)
        }
        if key.contains("coq10") {
            return SupplementIconConfig(iconType: .pixelText("Q10"), accentColor: DesignTokens.accentMood)
        }
        if key.contains("creatine") {
            return SupplementIconConfig(iconType: .pixelText("Cr"), accentColor: DesignTokens.positive)
        }
        if key.contains("biotin") {
            return SupplementIconConfig(iconType: .pixelText("B7"), accentColor: DesignTokens.negative)
        }
        if key.contains("iron") {
            return SupplementIconConfig(iconType: .pixelText("Fe"), accentColor: DesignTokens.accentMood)
        }
        if key == "nac" || key.contains("n-acetyl") {
            return SupplementIconConfig(iconType: .pixelText("NAC"), accentColor: DesignTokens.info)
        }
        if key.contains("berberine") {
            return SupplementIconConfig(iconType: .pixelText("BBR"), accentColor: DesignTokens.accentLongevity)
        }

        // SF Symbol icons
        if key.contains("omega") {
            return SupplementIconConfig(iconType: .sfSymbol("fish.fill"), accentColor: DesignTokens.accentClarity)
        }
        if key.contains("ashwagandha") {
            return SupplementIconConfig(iconType: .sfSymbol("leaf.fill"), accentColor: DesignTokens.accentGut)
        }
        if key.contains("probiotic") {
            return SupplementIconConfig(iconType: .sfSymbol("bubbles.and.sparkles.fill"), accentColor: DesignTokens.accentGut)
        }
        if key.contains("collagen") {
            return SupplementIconConfig(iconType: .sfSymbol("sparkles"), accentColor: DesignTokens.negative)
        }
        if key.contains("lion") && key.contains("mane") {
            return SupplementIconConfig(iconType: .sfSymbol("brain.head.profile"), accentColor: DesignTokens.accentClarity)
        }
        if key.contains("rhodiola") {
            return SupplementIconConfig(iconType: .sfSymbol("mountain.2.fill"), accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("melatonin") {
            return SupplementIconConfig(iconType: .sfSymbol("moon.stars.fill"), accentColor: DesignTokens.accentSleep)
        }
        if key.contains("tart cherry") || key.contains("cherry") {
            return SupplementIconConfig(iconType: .sfSymbol("drop.fill"), accentColor: DesignTokens.negative)
        }

        // Fallback
        return SupplementIconConfig(iconType: .sfSymbol("pill.fill"), accentColor: DesignTokens.info)
    }

    /// Abbreviated display name for compartment labels.
    static func shortName(for supplementName: String) -> String {
        let key = supplementName.lowercased()
        if key.contains("magnesium glycinate") { return "Magnesium" }
        if key.contains("ashwagandha") { return "Ashwagandha" }
        if key.contains("omega-3") || key.contains("omega 3") { return "Omega-3" }
        if key.contains("creatine monohydrate") { return "Creatine" }
        if key.contains("collagen peptides") { return "Collagen" }
        if key.contains("rhodiola rosea") { return "Rhodiola" }
        if key.contains("tart cherry") { return "Tart Cherry" }
        if key.contains("vitamin b") && key.contains("complex") { return "Vitamin B" }
        return supplementName
    }
}
