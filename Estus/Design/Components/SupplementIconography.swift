import SwiftUI

// MARK: - Icon Config

struct SupplementIconConfig {
    let abbreviation: String
    let accentColor: Color
}

// MARK: - Icon Registry

enum SupplementIconRegistry {

    static func config(for supplementName: String) -> SupplementIconConfig {
        let key = supplementName.lowercased()

        if key.contains("magnesium") {
            return SupplementIconConfig(abbreviation: "Mg", accentColor: DesignTokens.accentSleep)
        }
        if key.contains("vitamin d") || key.contains("d3") {
            return SupplementIconConfig(abbreviation: "D3", accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("l-theanine") || key.contains("theanine") {
            return SupplementIconConfig(abbreviation: "LT", accentColor: DesignTokens.accentClarity)
        }
        if key.contains("vitamin b") && key.contains("complex") {
            return SupplementIconConfig(abbreviation: "B", accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("zinc") {
            return SupplementIconConfig(abbreviation: "Zn", accentColor: DesignTokens.accentGut)
        }
        if key.contains("vitamin c") {
            return SupplementIconConfig(abbreviation: "C", accentColor: DesignTokens.accentMood)
        }
        if key.contains("coq10") {
            return SupplementIconConfig(abbreviation: "Q10", accentColor: DesignTokens.accentMood)
        }
        if key.contains("whey protein") {
            return SupplementIconConfig(abbreviation: "WP", accentColor: DesignTokens.accentMuscle)
        }
        if key.contains("plant protein") {
            return SupplementIconConfig(abbreviation: "PP", accentColor: DesignTokens.accentMuscle)
        }
        if key.contains("creatine") {
            return SupplementIconConfig(abbreviation: "Cr", accentColor: DesignTokens.positive)
        }
        if key.contains("biotin") {
            return SupplementIconConfig(abbreviation: "B7", accentColor: DesignTokens.negative)
        }
        if key.contains("iron") {
            return SupplementIconConfig(abbreviation: "Fe", accentColor: DesignTokens.accentMood)
        }
        if key == "nac" || key.contains("n-acetyl") {
            return SupplementIconConfig(abbreviation: "NAC", accentColor: DesignTokens.info)
        }
        if key.contains("berberine") {
            return SupplementIconConfig(abbreviation: "BBR", accentColor: DesignTokens.accentLongevity)
        }
        if key.contains("omega") {
            return SupplementIconConfig(abbreviation: "O3", accentColor: DesignTokens.accentClarity)
        }
        if key.contains("ashwagandha") {
            return SupplementIconConfig(abbreviation: "Aw", accentColor: DesignTokens.accentGut)
        }
        if key.contains("probiotic") {
            return SupplementIconConfig(abbreviation: "Pb", accentColor: DesignTokens.accentGut)
        }
        if key.contains("collagen") {
            return SupplementIconConfig(abbreviation: "Cg", accentColor: DesignTokens.negative)
        }
        if key.contains("lion") && key.contains("mane") {
            return SupplementIconConfig(abbreviation: "LM", accentColor: DesignTokens.accentClarity)
        }
        if key.contains("rhodiola") {
            return SupplementIconConfig(abbreviation: "Rh", accentColor: DesignTokens.accentEnergy)
        }
        if key.contains("melatonin") {
            return SupplementIconConfig(abbreviation: "Mt", accentColor: DesignTokens.accentSleep)
        }
        if key.contains("tart cherry") || key.contains("cherry") {
            return SupplementIconConfig(abbreviation: "TC", accentColor: DesignTokens.negative)
        }

        // Fallback
        return SupplementIconConfig(abbreviation: "Rx", accentColor: DesignTokens.info)
    }

    /// Abbreviated display name for compartment labels.
    static func shortName(for supplementName: String) -> String {
        let key = supplementName.lowercased()
        if key.contains("magnesium glycinate") { return "Magnesium" }
        if key.contains("ashwagandha") { return "Ashwagandha" }
        if key.contains("omega-3") || key.contains("omega 3") { return "Omega-3" }
        if key.contains("whey protein") { return "Whey Protein" }
        if key.contains("plant protein") { return "Plant Protein" }
        if key.contains("creatine monohydrate") { return "Creatine" }
        if key.contains("collagen peptides") { return "Collagen" }
        if key.contains("rhodiola rosea") { return "Rhodiola" }
        if key.contains("tart cherry") { return "Tart Cherry" }
        if key.contains("vitamin b") && key.contains("complex") { return "Vitamin B" }
        if key.contains("vitamin d") || key.contains("d3") { return "Vitamin D3" }
        if key.contains("coenzyme") || key.contains("coq10") { return "CoQ10" }
        return supplementName
    }
}
