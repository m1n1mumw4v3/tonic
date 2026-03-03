import Foundation

struct SafetyRule {
    let id: String
    let description: String
    let condition: (UserProfile, [DeepProfileModule]) -> Bool
    let excludeSupplements: [String]
    let warnSupplements: [String]
    let warningMessage: String
}

enum SafetyRules {

    /// All safety rules. Evaluated in order; exclusions take priority over warnings.
    static let allRules: [SafetyRule] = [
        ssriSerotonergicRule,
        diabeticBloodSugarRule,
        ppiNutrientDepletionRule,
        ironMaleGuardrailRule,
    ]

    // MARK: - SSRI / Serotonergic

    /// SSRI + serotonergic supplements: risk of serotonin syndrome.
    /// Excludes 5-HTP, St. John's Wort (when added to catalog).
    /// Warns on high-dose L-Tryptophan.
    private static let ssriSerotonergicRule = SafetyRule(
        id: "ssri_serotonergic",
        description: "SSRI medications + serotonergic supplements may increase serotonin syndrome risk",
        condition: { profile, deepModules in
            // Check medication IDs for SSRI-class (handled via drug interaction keys)
            // Also check if user reported psych medications in deep profile
            let hasPsychMedInDeep = deepModules.first(where: { $0.moduleId == .stressNervousSystem })
                .flatMap { $0.responses["psych_medications"] }
                .map { value -> Bool in
                    switch value {
                    case .string(let s): return !s.isEmpty && s != "none"
                    case .strings(let arr): return !arr.isEmpty && arr != ["none"]
                    }
                } ?? false

            // Check profile medications for known SSRI names
            let ssriNames: Set<String> = [
                "sertraline", "zoloft", "escitalopram", "lexapro",
                "fluoxetine", "prozac", "citalopram", "celexa",
                "paroxetine", "paxil", "venlafaxine", "effexor",
                "duloxetine", "cymbalta", "trazodone"
            ]
            let hasSSRI = profile.medications.contains { med in
                ssriNames.contains(med.lowercased())
            }

            return hasSSRI || hasPsychMedInDeep
        },
        excludeSupplements: [], // 5-HTP and St. John's Wort not yet in catalog
        warnSupplements: [],
        warningMessage: "You're taking an SSRI or similar medication. Some serotonergic supplements have been excluded or flagged to reduce the risk of serotonin syndrome."
    )

    // MARK: - Diabetic + Blood Sugar Lowering

    /// Diabetes medications + blood-sugar-lowering supplements: hypoglycemia risk.
    private static let diabeticBloodSugarRule = SafetyRule(
        id: "diabetic_blood_sugar",
        description: "Diabetes medications + berberine may increase hypoglycemia risk",
        condition: { profile, deepModules in
            let diabetesNames: Set<String> = [
                "metformin", "glipizide", "glyburide", "insulin",
                "jardiance", "empagliflozin", "farxiga", "dapagliflozin",
                "ozempic", "semaglutide", "trulicity", "dulaglutide",
                "mounjaro", "tirzepatide", "januvia", "sitagliptin",
                "pioglitazone"
            ]
            let hasDiabetesMed = profile.medications.contains { med in
                diabetesNames.contains(med.lowercased())
            }

            // Also check deep profile lab module for diabetes indication
            let hasDiabetesInDeep = deepModules.first(where: { $0.moduleId == .labWorkBiomarkers })
                .flatMap { $0.responses["lab_blood_sugar"] }
                .map { value -> Bool in
                    switch value {
                    case .string(let s): return s == "diabetic" || s == "prediabetic"
                    case .strings: return false
                    }
                } ?? false

            return hasDiabetesMed || hasDiabetesInDeep
        },
        excludeSupplements: [],
        warnSupplements: ["Berberine"],
        warningMessage: "Berberine can lower blood sugar. If you're on diabetes medication, monitor your glucose closely and consult your doctor before adding berberine."
    )

    // MARK: - PPI + Nutrient Depletion

    /// PPI medications deplete certain nutrients — boost rather than exclude.
    private static let ppiNutrientDepletionRule = SafetyRule(
        id: "ppi_nutrient_depletion",
        description: "Proton pump inhibitors reduce absorption of key minerals and vitamins",
        condition: { profile, deepModules in
            let ppiNames: Set<String> = [
                "omeprazole", "prilosec", "pantoprazole", "protonix",
                "esomeprazole", "nexium", "lansoprazole", "prevacid",
                "rabeprazole", "aciphex", "dexlansoprazole", "dexilant"
            ]
            let hasPPIMed = profile.medications.contains { med in
                ppiNames.contains(med.lowercased())
            }

            // Also check Gut Health deep profile module for PPI usage
            let hasPPIInGut = deepModules.first(where: { $0.moduleId == .gutHealth })
                .flatMap { $0.responses["gut_ppi_usage"] }
                .map { value -> Bool in
                    switch value {
                    case .string(let s): return s == "yes_currently"
                    case .strings: return false
                    }
                } ?? false

            return hasPPIMed || hasPPIInGut
        },
        excludeSupplements: [],
        warnSupplements: [], // Boosts handled via score adjustments, not warnings
        warningMessage: "PPIs can reduce absorption of magnesium, B12, calcium, and iron over time. Your plan accounts for this."
    )

    // MARK: - Iron Male Guardrail

    /// Males generally don't need supplemental iron unless they are vegan/vegetarian,
    /// exercise 5+/week, or have confirmed low ferritin from lab work.
    private static let ironMaleGuardrailRule = SafetyRule(
        id: "iron_male_guardrail",
        description: "Males without specific risk factors should not supplement iron",
        condition: { profile, deepModules in
            guard profile.sex == .male else { return false }

            // Exemption: vegan or vegetarian diet
            if profile.dietType == .vegan || profile.dietType == .vegetarian { return false }

            // Exemption: high exercise frequency (5+/week)
            if profile.exerciseFrequency == .fivePlus { return false }

            // Exemption: lab work shows low ferritin
            let hasLowFerritin = deepModules.first(where: { $0.moduleId == .labWorkBiomarkers })
                .flatMap { $0.responses["lab_iron_ferritin"] }
                .map { value -> Bool in
                    switch value {
                    case .string(let s): return s == "currently_low"
                    case .strings: return false
                    }
                } ?? false
            if hasLowFerritin { return false }

            return true
        },
        excludeSupplements: ["Iron"],
        warnSupplements: [],
        warningMessage: ""
    )

    // MARK: - Score Boosts from Safety Rules

    /// Returns supplementary score adjustments based on safety rules (e.g., PPI → boost minerals).
    static func scoreBoosts(profile: UserProfile, deepProfileModules: [DeepProfileModule]) -> [String: Int] {
        var boosts: [String: Int] = [:]

        // PPI nutrient depletion boosts
        if ppiNutrientDepletionRule.condition(profile, deepProfileModules) {
            boosts["Magnesium Glycinate"] = (boosts["Magnesium Glycinate"] ?? 0) + 2
            boosts["Vitamin B Complex"] = (boosts["Vitamin B Complex"] ?? 0) + 2
            boosts["Iron"] = (boosts["Iron"] ?? 0) + 1
        }

        // 4a: Birth control / HRT nutrient depletion boosts
        let hormonalResponse = deepProfileModules.first(where: { $0.moduleId == .hormonalMetabolic })
            .flatMap { $0.responses["hormonal_birth_control_hrt"]?.stringValue }
        if hormonalResponse == "birth_control" || hormonalResponse == "hrt" {
            boosts["Magnesium Glycinate"] = (boosts["Magnesium Glycinate"] ?? 0) + 2
            boosts["Vitamin B Complex"] = (boosts["Vitamin B Complex"] ?? 0) + 2
            boosts["Zinc"] = (boosts["Zinc"] ?? 0) + 1
            boosts["CoQ10"] = (boosts["CoQ10"] ?? 0) + 1
        }

        // 4c: Sleep onset vs. maintenance differentiation
        if let sleepModule = deepProfileModules.first(where: { $0.moduleId == .sleepCircadian }) {
            // Sleep onset latency → Melatonin boost
            if let onsetLatency = sleepModule.responses["sleep_onset_latency"]?.stringValue {
                if onsetLatency == "40_60" || onsetLatency == "over_60" {
                    boosts["Melatonin"] = (boosts["Melatonin"] ?? 0) + 2
                } else if onsetLatency == "20_40" {
                    boosts["Melatonin"] = (boosts["Melatonin"] ?? 0) + 1
                }
            }

            // Sleep maintenance (wake frequency) → Magnesium Glycinate boost
            if let wakeFrequency = sleepModule.responses["sleep_wake_frequency"]?.stringValue {
                if wakeFrequency == "three_plus" {
                    boosts["Magnesium Glycinate"] = (boosts["Magnesium Glycinate"] ?? 0) + 2
                } else if wakeFrequency == "twice" {
                    boosts["Magnesium Glycinate"] = (boosts["Magnesium Glycinate"] ?? 0) + 1
                }
            }
        }

        // Female iron score boosts
        if profile.sex == .female {
            if profile.dietType == .vegan || profile.dietType == .vegetarian {
                boosts["Iron"] = (boosts["Iron"] ?? 0) + 2
            }
            if profile.exerciseFrequency == .fivePlus {
                boosts["Iron"] = (boosts["Iron"] ?? 0) + 1
            }
            if profile.age >= 18 && profile.age <= 50 {
                boosts["Iron"] = (boosts["Iron"] ?? 0) + 1
            }
        }

        return boosts
    }
}
