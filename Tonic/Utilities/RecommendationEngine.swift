import Foundation

struct RecommendationEngine {
    private let catalog: SupplementCatalog
    private let drugInteractions: [DBDrugInteraction]
    private let contraindications: [DBContraindication]

    init(catalog: SupplementCatalog,
         drugInteractions: [DBDrugInteraction] = [],
         contraindications: [DBContraindication] = []) {
        self.catalog = catalog
        self.drugInteractions = drugInteractions
        self.contraindications = contraindications
    }

    // MARK: - Generate Plan

    func generatePlan(for profile: UserProfile) -> SupplementPlan {
        // Step 1: Goal mapping → candidate supplements scored by evidence weight
        var candidateScores: [String: Int] = [:]
        let goalKeys = profile.healthGoals.map { $0.rawValue }

        for goal in goalKeys {
            let entries = catalog.goalMappings(for: goal)
            for entry in entries {
                candidateScores[entry.name, default: 0] += entry.weight
            }
        }

        // Step 2: Interaction filter
        let medicationKeywords = extractMedicationKeywords(from: profile)
        let excludedSupplements = findExcludedSupplements(medications: medicationKeywords, allergies: profile.allergies, profile: profile)

        let filteredCandidates = candidateScores.filter { !excludedSupplements.contains($0.key) }

        // Step 3: Sort by score (goal overlap), then apply diversity
        let ranked = filteredCandidates.sorted { a, b in
            if a.value != b.value { return a.value > b.value }
            return a.key < b.key
        }

        // Step 4: Select top 5-8 with category diversity
        var selected: [Supplement] = []
        var usedCategories: Set<String> = []
        let maxSupplements = 7

        for (name, _) in ranked {
            guard selected.count < maxSupplements else { break }
            guard let supplement = catalog.supplement(named: name) else { continue }

            // Allow max 2 per category for diversity
            let categoryCount = selected.filter { $0.category == supplement.category }.count
            if categoryCount >= 2 { continue }

            selected.append(supplement)
            usedCategories.insert(supplement.category)
        }

        // Ensure vegan/vegetarian get B12 and D3
        if profile.dietType == .vegan || profile.dietType == .vegetarian {
            addIfMissing("Vitamin B Complex", to: &selected, excluded: excludedSupplements)
            addIfMissing("Vitamin D3 + K2", to: &selected, excluded: excludedSupplements)
        }

        // Step 5: Build plan supplements with dosage adjustments, timing, tier data, and enriched info
        let userGoalKeys = Set(profile.healthGoals.map { $0.rawValue })

        var planSupplements = selected.enumerated().map { index, supplement -> PlanSupplement in
            var dosage = supplement.recommendedDosageMg
            var dosageText = supplement.commonDosageRange

            // Dosage adjustments
            dosage = adjustDosage(baseDosage: dosage, supplement: supplement, profile: profile)
            dosageText = formatDosage(dosage: dosage, supplement: supplement)

            // Timing — keep recommended, resolve conflicts
            let timing = resolveTiming(for: supplement, profile: profile)

            // Compute matched goals: which of the user's goals map to this supplement
            let matched = userGoalKeys.filter { goalKey in
                catalog.goalMappings(for: goalKey).contains { $0.name == supplement.name }
            }
            let weightedScore = matched.reduce(0) { sum, goalKey in
                sum + catalog.weight(for: supplement.name, goal: goalKey)
            }

            return PlanSupplement(
                supplementId: supplement.id,
                name: supplement.name,
                dosage: dosageText,
                dosageMg: dosage,
                timing: timing,
                category: supplement.category,
                sortOrder: index,
                matchedGoals: Array(matched).sorted(),
                tierScore: weightedScore,
                researchNote: supplement.notes,
                whyInYourPlan: generateWhyInYourPlan(supplement: supplement, matchedGoals: Array(matched), profile: profile),
                dosageRationale: generateDosageRationale(supplement: supplement, profile: profile),
                expectedTimeline: supplement.expectedTimeline,
                whatToLookFor: resolveWhatToLookFor(template: supplement.whatToLookFor, profile: profile),
                formAndBioavailability: supplement.formAndBioavailability,
                evidenceDisplay: supplement.evidenceLevel.displayText,
                evidenceLevel: supplement.evidenceLevel
            )
        }

        // Assign tiers based on weighted evidence score
        assignTiers(to: &planSupplements)

        // Second pass: generate interaction notes (needs full supplement list)
        let planNames = Set(planSupplements.map(\.name))
        for i in planSupplements.indices {
            planSupplements[i].interactionNote = generateInteractionNote(
                supplementName: planSupplements[i].name,
                planNames: planNames,
                profile: profile
            )
        }

        // Sort by tier first, then timing within tier
        planSupplements.sort { a, b in
            if a.tier.sortOrder != b.tier.sortOrder {
                return a.tier.sortOrder < b.tier.sortOrder
            }
            return a.timing.sortOrder < b.timing.sortOrder
        }

        // Update sort order to reflect final ordering
        for i in planSupplements.indices {
            planSupplements[i].sortOrder = i
        }

        return SupplementPlan(supplements: planSupplements)
    }

    // MARK: - Build Single Plan Supplement

    func buildPlanSupplement(from supplement: Supplement, for profile: UserProfile, existingSupplements: [PlanSupplement]) -> PlanSupplement {
        let userGoalKeys = Set(profile.healthGoals.map { $0.rawValue })

        var dosage = supplement.recommendedDosageMg
        dosage = adjustDosage(baseDosage: dosage, supplement: supplement, profile: profile)
        let dosageText = formatDosage(dosage: dosage, supplement: supplement)
        let timing = resolveTiming(for: supplement, profile: profile)

        let matched = userGoalKeys.filter { goalKey in
            catalog.goalMappings(for: goalKey).contains { $0.name == supplement.name }
        }
        let weightedScore = matched.reduce(0) { sum, goalKey in
            sum + catalog.weight(for: supplement.name, goal: goalKey)
        }

        let planNames = Set(existingSupplements.map(\.name) + [supplement.name])

        var planSupplement = PlanSupplement(
            supplementId: supplement.id,
            name: supplement.name,
            dosage: dosageText,
            dosageMg: dosage,
            timing: timing,
            category: supplement.category,
            sortOrder: existingSupplements.count,
            matchedGoals: Array(matched).sorted(),
            tierScore: weightedScore,
            researchNote: supplement.notes,
            whyInYourPlan: generateWhyInYourPlan(supplement: supplement, matchedGoals: Array(matched), profile: profile),
            dosageRationale: generateDosageRationale(supplement: supplement, profile: profile),
            expectedTimeline: supplement.expectedTimeline,
            whatToLookFor: resolveWhatToLookFor(template: supplement.whatToLookFor, profile: profile),
            formAndBioavailability: supplement.formAndBioavailability,
            interactionNote: generateInteractionNote(supplementName: supplement.name, planNames: planNames, profile: profile),
            evidenceDisplay: supplement.evidenceLevel.displayText
        )

        // Assign tier based on score
        var tempList = existingSupplements + [planSupplement]
        assignTiers(to: &tempList)
        if let assigned = tempList.last {
            planSupplement.tier = assigned.tier
        }

        return planSupplement
    }

    // MARK: - Enriched Text Generation

    private func generateWhyInYourPlan(supplement: Supplement, matchedGoals: [String], profile: UserProfile) -> String {
        // Diet-driven additions when no goal overlap
        if matchedGoals.isEmpty {
            if (profile.dietType == .vegan || profile.dietType == .vegetarian) &&
                (supplement.name == "Vitamin B Complex" || supplement.name == "Vitamin D3 + K2") {
                return "\(supplement.name) helps cover nutritional gaps common in a \(profile.dietType.label.lowercased()) diet, supporting overall energy and immune health."
            }
            return "\(supplement.name) was included based on your overall health profile."
        }

        let goalDescriptors: [String: String] = [
            "sleep": "sleep quality",
            "energy": "daily energy",
            "focus": "mental clarity and focus",
            "stress_anxiety": "stress management",
            "gut_health": "digestive health",
            "immune_support": "immune function",
            "muscle_recovery": "exercise recovery",
            "skin_hair_nails": "skin, hair, and nail health",
            "longevity": "long-term health",
            "heart_health": "cardiovascular health"
        ]

        let narrativeOpeners: [String: String] = [
            "Magnesium Glycinate": "Magnesium glycinate is one of the most effective natural supports for",
            "Vitamin D3 + K2": "Vitamin D3 paired with K2 plays a foundational role in",
            "Omega-3 (EPA/DHA)": "Omega-3 fatty acids are among the most well-researched supplements for",
            "Ashwagandha KSM-66": "Ashwagandha (KSM-66 extract) is a clinically studied adaptogen that supports",
            "L-Theanine": "L-theanine promotes calm alertness without drowsiness, making it a natural fit for",
            "Vitamin B Complex": "B vitamins are essential cofactors in energy metabolism, directly supporting",
            "Probiotics": "A quality probiotic supports the gut-immune axis, benefiting",
            "Zinc": "Zinc is a key mineral for immune defense and tissue repair, supporting",
            "Vitamin C": "Vitamin C is a well-established antioxidant that supports",
            "CoQ10": "CoQ10 fuels cellular energy production, making it especially relevant for",
            "Creatine Monohydrate": "Creatine is one of the most extensively studied performance supplements, supporting",
            "Collagen Peptides": "Hydrolyzed collagen provides the building blocks your body needs for",
            "Lion's Mane": "Lion's mane is a functional mushroom with promising research supporting",
            "Rhodiola Rosea": "Rhodiola is an adaptogen traditionally used for fatigue resistance, supporting",
            "Melatonin": "Melatonin helps regulate your circadian rhythm, directly supporting",
            "Biotin": "Biotin is a B vitamin closely associated with",
            "Iron": "Iron is essential for oxygen transport and energy production, supporting",
            "NAC": "NAC is a precursor to glutathione — your body's master antioxidant — supporting",
            "Berberine": "Berberine is a plant compound with metabolic benefits, supporting",
            "Tart Cherry Extract": "Tart cherry provides natural melatonin and anti-inflammatory compounds, supporting"
        ]

        // Sort goals by weight so the strongest benefit leads the sentence
        let sorted = matchedGoals.sorted { a, b in
            catalog.weight(for: supplement.name, goal: a) >
            catalog.weight(for: supplement.name, goal: b)
        }

        let phrases = sorted.compactMap { goalDescriptors[$0] }
        guard !phrases.isEmpty else {
            return "\(supplement.name) was included based on your overall health profile."
        }

        let goalPhrase: String
        if phrases.count == 1 {
            goalPhrase = phrases[0]
        } else if phrases.count == 2 {
            goalPhrase = "both \(phrases[0]) and \(phrases[1])"
        } else {
            let allButLast = phrases.dropLast().joined(separator: ", ")
            goalPhrase = "\(allButLast), and \(phrases.last!)"
        }

        let connector: String
        switch phrases.count {
        case 1: connector = "one of your top goals"
        case 2: connector = "two of your top goals"
        case 3: connector = "three of your top goals"
        default: connector = "several of your top goals"
        }

        let opener = narrativeOpeners[supplement.name] ?? "\(supplement.name) supports"
        return "\(opener) \(goalPhrase) — \(connector)."
    }

    private func generateDosageRationale(supplement: Supplement, profile: UserProfile) -> String {
        var rationale = supplement.dosageRationale

        // Append adjustment context
        if let weight = profile.weightLbs, weight > 200, supplement.name == "Vitamin D3 + K2" {
            rationale += " Adjusted to 4000 IU based on your body weight."
        }
        if profile.sex == .female && supplement.name == "Iron" {
            rationale += " Set to 27mg as recommended for women of reproductive age."
        } else if profile.sex == .male && supplement.name == "Iron" {
            rationale += " Adjusted to 8mg, the recommended daily amount for men."
        }
        if profile.age > 65 && ["Rhodiola Rosea", "CoQ10"].contains(supplement.name) {
            rationale += " Dose reduced by 25% as a precaution for adults over 65."
        }

        return rationale
    }

    private func resolveWhatToLookFor(template: String, profile: UserProfile) -> String {
        var text = template

        // Caffeine note
        let hasCaffeine = profile.coffeeCupsDaily > 0 || profile.teaCupsDaily > 0 || profile.energyDrinksDaily > 0
        if hasCaffeine {
            text = text.replacingOccurrences(of: "{caffeine_note}", with: ", especially if you pair it with your morning caffeine")
        } else {
            text = text.replacingOccurrences(of: "{caffeine_note}", with: "")
        }

        // Stress note
        let highStress = profile.stressLevel == .high || profile.stressLevel == .veryHigh
        if highStress {
            text = text.replacingOccurrences(of: "{stress_note}", with: ". Given your reported stress level, this may be especially beneficial")
        } else {
            text = text.replacingOccurrences(of: "{stress_note}", with: "")
        }

        // Exercise note
        let isActive = profile.exerciseFrequency == .threeToFour || profile.exerciseFrequency == .fivePlus
        if isActive {
            text = text.replacingOccurrences(of: "{exercise_note}", with: ", particularly given your active exercise routine")
        } else {
            text = text.replacingOccurrences(of: "{exercise_note}", with: "")
        }

        return text
    }

    private func generateInteractionNote(supplementName: String, planNames: Set<String>, profile: UserProfile) -> String {
        var parts: [String] = []

        // Check synergies from catalog
        if let synergies = catalog.synergies[supplementName] {
            for synergy in synergies {
                // Check if partner is caffeine (from profile, not plan)
                if synergy.partner == "caffeine" {
                    let hasCaffeine = profile.coffeeCupsDaily > 0 || profile.teaCupsDaily > 0 || profile.energyDrinksDaily > 0
                    if hasCaffeine {
                        parts.append("Pairs well with your daily caffeine — \(synergy.mechanism).")
                    }
                } else if planNames.contains(synergy.partner) {
                    parts.append("Pairs well with \(synergy.partner) in your plan — \(synergy.mechanism).")
                }
            }
        }

        // Medication safety using injected drug interactions
        if !profile.medications.isEmpty {
            if let supplement = catalog.supplement(named: supplementName) {
                let hasConflict = catalog.hasInteraction(supplement: supplement, medications: profile.medications, drugInteractions: drugInteractions)
                if !hasConflict {
                    parts.append("No conflicts with your current medications.")
                }
            }
        } else {
            parts.append("No medication interactions to flag.")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Tier Assignment

    func assignTiers(to supplements: inout [PlanSupplement]) {
        for i in supplements.indices {
            let score = supplements[i].tierScore
            if score >= 5 {
                supplements[i].tier = .core
            } else if score >= 3 {
                supplements[i].tier = .targeted
            } else {
                supplements[i].tier = .supporting
            }
        }
    }

    // MARK: - Helpers

    func extractMedicationKeywords(from profile: UserProfile) -> [String] {
        let meds = profile.medications
        return meds.flatMap { med in
            med.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }
    }

    func findExcludedSupplements(medications: [String], allergies: [String], profile: UserProfile) -> Set<String> {
        var excluded: Set<String> = []

        // Check medication interactions using injected drug interactions
        for keyword in medications {
            let interactions = catalog.interactionsForMedication(keyword, drugInteractions: drugInteractions)
            excluded.formUnion(interactions)
        }

        // Also check contraindications
        for contra in contraindications where contra.severity == .absolute {
            if let name = catalog.supplement(byId: contra.supplementId)?.name ?? contra.supplementName {
                excluded.insert(name)
            }
        }

        // Check allergies
        let allergyKeywords = allergies.map { $0.lowercased() }
        if allergyKeywords.contains("fish") || allergyKeywords.contains("shellfish") {
            excluded.insert("Omega-3 (EPA/DHA)")
        }

        // Pregnancy / breastfeeding contraindications
        if profile.isPregnant || profile.isBreastfeeding {
            excluded.insert("Ashwagandha KSM-66")
            excluded.insert("Berberine")
        }

        return excluded
    }

    private func addIfMissing(_ name: String, to list: inout [Supplement], excluded: Set<String>) {
        guard !excluded.contains(name) else { return }
        guard !list.contains(where: { $0.name == name }) else { return }
        if let supplement = catalog.supplement(named: name) {
            list.append(supplement)
        }
    }

    func adjustDosage(baseDosage: Double, supplement: Supplement, profile: UserProfile) -> Double {
        var dosage = baseDosage

        // Age adjustments
        if profile.age > 65 {
            if ["Rhodiola Rosea", "CoQ10"].contains(supplement.name) {
                dosage *= 0.75
            }
        }

        // Sex-based adjustments
        if profile.sex == .female && supplement.name == "Iron" {
            dosage = 27
        } else if profile.sex == .male && supplement.name == "Iron" {
            dosage = 8
        }

        // Weight-based adjustments for fat-soluble vitamins
        if let weight = profile.weightLbs, weight > 200 {
            if supplement.name == "Vitamin D3 + K2" {
                dosage = 4000
            }
        }

        return dosage
    }

    func formatDosage(dosage: Double, supplement: Supplement) -> String {
        if supplement.name == "Vitamin D3 + K2" {
            return "\(Int(dosage)) IU"
        }
        if supplement.name == "Probiotics" {
            return supplement.commonDosageRange
        }
        if supplement.name == "Vitamin B Complex" {
            return "1x daily"
        }
        if supplement.name == "Biotin" {
            return "\(Int(dosage * 1000))mcg"
        }

        if dosage >= 1000 {
            let grams = dosage / 1000
            if grams == round(grams) {
                return "\(Int(grams))g"
            }
            return String(format: "%.1fg", grams)
        }
        return "\(Int(dosage))mg"
    }

    func resolveTiming(for supplement: Supplement, profile: UserProfile) -> SupplementTiming {
        return supplement.recommendedTiming
    }
}
