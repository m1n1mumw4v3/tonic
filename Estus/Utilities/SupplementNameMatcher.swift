import Foundation

struct SupplementNameMatcher {

    enum MatchType {
        case exact
        case commonName
        case formVariant
        case partial
    }

    struct MatchResult {
        let catalogName: String
        let matchType: MatchType
        let userInputName: String
    }

    /// Maps from base compound names to catalog supplement names for form-variant detection.
    /// e.g., "magnesium" → "Magnesium Glycinate" (user might take "magnesium oxide")
    private static let formVariantMap: [String: String] = [
        "magnesium": "Magnesium Glycinate",
        "vitamin d": "Vitamin D3 + K2",
        "vitamin d3": "Vitamin D3 + K2",
        "omega 3": "Omega-3 (EPA/DHA)",
        "omega-3": "Omega-3 (EPA/DHA)",
        "coq10": "CoQ10",
        "ubiquinol": "CoQ10",
        "ubiquinone": "CoQ10",
        "ashwagandha": "Ashwagandha KSM-66",
        "rhodiola": "Rhodiola Rosea",
        "iron": "Iron",
        "zinc": "Zinc",
        "vitamin c": "Vitamin C",
        "vitamin b": "Vitamin B Complex",
        "b complex": "Vitamin B Complex",
        "b12": "Vitamin B Complex",
        "b-12": "Vitamin B Complex",
        "biotin": "Biotin",
        "collagen": "Collagen Peptides",
        "creatine": "Creatine Monohydrate",
        "melatonin": "Melatonin",
        "nac": "NAC",
        "n-acetyl cysteine": "NAC",
        "berberine": "Berberine",
        "lion's mane": "Lion's Mane",
        "lions mane": "Lion's Mane",
        "tart cherry": "Tart Cherry Extract",
        "whey protein": "Whey Protein Isolate",
        "whey": "Whey Protein Isolate",
        "protein powder": "Whey Protein Isolate",
        "pea protein": "Plant Protein Blend",
        "plant protein": "Plant Protein Blend",
        "probiotics": "Probiotics",
        "probiotic": "Probiotics",
        "l-theanine": "L-Theanine",
        "theanine": "L-Theanine",
    ]

    /// Form upgrade messages for common form-variant switches.
    static let formUpgradeMessages: [String: String] = [
        "magnesium oxide": "You're currently taking magnesium oxide. We've recommended magnesium glycinate instead — it's better absorbed with fewer GI side effects.",
        "magnesium citrate": "You're currently taking magnesium citrate. We've recommended magnesium glycinate — it's gentler on digestion and well-suited for sleep support.",
        "vitamin d2": "You're currently taking vitamin D2. We've recommended D3 + K2 instead — D3 is 87% more effective at raising blood levels, and K2 directs calcium to bones.",
        "fish oil": "You're already taking fish oil. We've ensured Omega-3 dosing accounts for your current intake.",
        "ubiquinone": "You're taking ubiquinone (standard CoQ10). We've recommended ubiquinol — the active form that's 2-3x better absorbed.",
        "iron sulfate": "You're taking iron sulfate. We've recommended iron bisglycinate — it's 4x better absorbed with fewer GI side effects.",
        "ferrous sulfate": "You're taking ferrous sulfate. We've recommended iron bisglycinate — it's 4x better absorbed with fewer GI side effects.",
    ]

    /// Match the user's current supplements against the catalog.
    /// Returns matches in priority order: exact > commonName > formVariant > partial.
    static func match(userSupplements: [String], catalog: SupplementCatalog) -> [MatchResult] {
        var results: [MatchResult] = []
        var matchedCatalogNames: Set<String> = []

        for userSupplement in userSupplements {
            let input = userSupplement.trimmingCharacters(in: .whitespaces)
            guard !input.isEmpty else { continue }
            let lowered = input.lowercased()

            // 1. Exact match on supplement name
            if let supplement = catalog.allSupplements.first(where: { $0.name.lowercased() == lowered }) {
                guard !matchedCatalogNames.contains(supplement.name) else { continue }
                matchedCatalogNames.insert(supplement.name)
                results.append(MatchResult(catalogName: supplement.name, matchType: .exact, userInputName: input))
                continue
            }

            // 2. Common name match
            if let supplement = catalog.allSupplements.first(where: {
                $0.commonNames.contains(where: { $0.lowercased() == lowered })
            }) {
                guard !matchedCatalogNames.contains(supplement.name) else { continue }
                matchedCatalogNames.insert(supplement.name)
                results.append(MatchResult(catalogName: supplement.name, matchType: .commonName, userInputName: input))
                continue
            }

            // 3. Form variant match — check if input contains a base compound key
            var foundFormVariant = false
            for (baseCompound, catalogName) in formVariantMap {
                if lowered.contains(baseCompound) {
                    // Ensure this is a form variant, not an exact match
                    guard !matchedCatalogNames.contains(catalogName) else { break }
                    // If the input is exactly the catalog name, it's exact not variant
                    if catalog.supplement(named: catalogName)?.name.lowercased() == lowered { break }
                    matchedCatalogNames.insert(catalogName)
                    results.append(MatchResult(catalogName: catalogName, matchType: .formVariant, userInputName: input))
                    foundFormVariant = true
                    break
                }
            }
            if foundFormVariant { continue }

            // 4. Partial match — supplement name contains user input or vice versa
            if let supplement = catalog.allSupplements.first(where: {
                $0.name.lowercased().contains(lowered) || lowered.contains($0.name.lowercased())
            }) {
                guard !matchedCatalogNames.contains(supplement.name) else { continue }
                matchedCatalogNames.insert(supplement.name)
                results.append(MatchResult(catalogName: supplement.name, matchType: .partial, userInputName: input))
            }
        }

        return results
    }
}
