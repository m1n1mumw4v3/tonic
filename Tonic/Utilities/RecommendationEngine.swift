import Foundation

struct RecommendationEngine {
    private let catalog: SupplementCatalog
    private let drugInteractions: [DBDrugInteraction]
    private let contraindications: [DBContraindication]
    private let medications: [DBMedication]

    init(catalog: SupplementCatalog,
         drugInteractions: [DBDrugInteraction] = [],
         contraindications: [DBContraindication] = [],
         medications: [DBMedication] = []) {
        self.catalog = catalog
        self.drugInteractions = drugInteractions
        self.contraindications = contraindications
        self.medications = medications
    }

    // MARK: - Interaction Filter Result

    struct InteractionFilterResult {
        let excluded: Set<String>
        let warnings: [UUID: [DBDrugInteraction]]
        let removedInteractions: [UUID: [DBDrugInteraction]]
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

        // Step 2: Interaction filter (key-based)
        let interactionKeys = collectInteractionKeys(from: profile)
        let filterResult = filterByInteractions(
            candidateNames: Array(candidateScores.keys),
            interactionKeys: interactionKeys,
            allergies: profile.allergies,
            profile: profile
        )

        let filteredCandidates = candidateScores.filter { !filterResult.excluded.contains($0.key) }

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
            addIfMissing("Vitamin B Complex", to: &selected, excluded: filterResult.excluded)
            addIfMissing("Vitamin D3 + K2", to: &selected, excluded: filterResult.excluded)
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

            // Build interaction warnings for this supplement
            let warnings = filterResult.warnings[supplement.id] ?? []
            let interactionWarnings: [InteractionWarning]? = warnings.isEmpty ? nil : warnings.map { interaction in
                InteractionWarning(
                    id: interaction.id,
                    drugOrClass: interaction.drugOrClass,
                    interactionType: interaction.interactionType.rawValue,
                    severity: interaction.severity.rawValue,
                    mechanism: interaction.mechanism,
                    action: interaction.action.rawValue
                )
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
                evidenceLevel: supplement.evidenceLevel,
                interactionWarnings: interactionWarnings
            )
        }

        // Assign tiers based on weighted evidence score
        assignTiers(to: &planSupplements)

        // Second pass: generate interaction notes (needs full supplement list)
        let planNames = Set(planSupplements.map(\.name))
        for i in planSupplements.indices {
            planSupplements[i].interactionNote = generateInteractionNote(
                supplement: planSupplements[i],
                planNames: planNames,
                interactionKeys: interactionKeys,
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

        var plan = SupplementPlan(supplements: planSupplements)
        plan.aiReasoning = generatePlanSummary(supplements: planSupplements, profile: profile)
        return plan
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
        let interactionKeys = collectInteractionKeys(from: profile)

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
            interactionNote: "",
            evidenceDisplay: supplement.evidenceLevel.displayText
        )

        // Generate interaction note
        planSupplement.interactionNote = generateInteractionNote(
            supplement: planSupplement,
            planNames: planNames,
            interactionKeys: interactionKeys,
            profile: profile
        )

        // Assign tier based on score
        var tempList = existingSupplements + [planSupplement]
        assignTiers(to: &tempList)
        if let assigned = tempList.last {
            planSupplement.tier = assigned.tier
        }

        return planSupplement
    }

    // MARK: - Shared Goal Descriptors

    private static let goalDescriptors: [String: String] = [
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

        let goalDescriptors = Self.goalDescriptors

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

    private func generateInteractionNote(supplement: PlanSupplement, planNames: Set<String>, interactionKeys: Set<String>, profile: UserProfile) -> String {
        var parts: [String] = []

        // Check synergies from catalog
        if let synergies = catalog.synergies[supplement.name] {
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

        // Medication safety using key-based interaction checking
        if !profile.medicationIds.isEmpty || !profile.medications.isEmpty {
            if let warnings = supplement.interactionWarnings, !warnings.isEmpty {
                for warning in warnings {
                    switch warning.action {
                    case DBInteractionAction.separateTiming.rawValue:
                        parts.append("Take separately from \(warning.drugOrClass) — \(warning.mechanism).")
                    case DBInteractionAction.monitor.rawValue:
                        parts.append("Monitor when taking with \(warning.drugOrClass) — \(warning.mechanism).")
                    case DBInteractionAction.adjustDose.rawValue:
                        parts.append("Dose may need adjustment due to \(warning.drugOrClass) — \(warning.mechanism).")
                    default:
                        parts.append("\(warning.mechanism).")
                    }
                }
            } else if let supplementId = supplement.supplementId {
                // Check via key-based lookup for supplements without pre-populated warnings
                let decision = catalog.checkInteractions(
                    supplementId: supplementId,
                    userInteractionKeys: interactionKeys,
                    allInteractions: drugInteractions
                )
                switch decision {
                case .clear:
                    parts.append("No conflicts with your current medications.")
                case .keepWithWarnings(let matches):
                    for match in matches {
                        parts.append("\(match.mechanism).")
                    }
                case .remove:
                    break // Should not happen for included supplements
                }
            } else {
                parts.append("No conflicts with your current medications.")
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

    // MARK: - Key-Based Interaction Helpers

    /// Collect interaction keys from the user's medication IDs
    func collectInteractionKeys(from profile: UserProfile) -> Set<String> {
        catalog.collectInteractionKeys(medicationIds: profile.medicationIds, medications: medications)
    }

    /// Filter candidate supplements by drug interactions, contraindications, allergies, and pregnancy
    func filterByInteractions(
        candidateNames: [String],
        interactionKeys: Set<String>,
        allergies: [String],
        profile: UserProfile
    ) -> InteractionFilterResult {
        var excluded: Set<String> = []
        var warnings: [UUID: [DBDrugInteraction]] = [:]
        var removedInteractions: [UUID: [DBDrugInteraction]] = [:]

        // Key-based drug interaction checking
        if !interactionKeys.isEmpty {
            for name in candidateNames {
                guard let supplement = catalog.supplement(named: name) else { continue }
                let decision = catalog.checkInteractions(
                    supplementId: supplement.id,
                    userInteractionKeys: interactionKeys,
                    allInteractions: drugInteractions
                )
                switch decision {
                case .remove(let matches):
                    excluded.insert(name)
                    removedInteractions[supplement.id] = matches
                case .keepWithWarnings(let matches):
                    warnings[supplement.id] = matches
                case .clear:
                    break
                }
            }
        }

        // Contraindications
        for contra in contraindications where contra.severity == .absolute {
            if let name = catalog.supplement(byId: contra.supplementId)?.name ?? contra.supplementName {
                excluded.insert(name)
            }
        }

        // Allergies
        let allergyKeywords = allergies.map { $0.lowercased() }
        if allergyKeywords.contains("fish") || allergyKeywords.contains("shellfish") {
            excluded.insert("Omega-3 (EPA/DHA)")
        }

        // Pregnancy / breastfeeding contraindications
        if profile.isPregnant || profile.isBreastfeeding {
            excluded.insert("Ashwagandha KSM-66")
            excluded.insert("Berberine")
        }

        return InteractionFilterResult(
            excluded: excluded,
            warnings: warnings,
            removedInteractions: removedInteractions
        )
    }

    // MARK: - Legacy Helpers (kept for AddSupplementSheet compatibility)

    /// Collect interaction keys for exclusion checking (replaces extractMedicationKeywords)
    func findExcludedSupplements(profile: UserProfile) -> Set<String> {
        let interactionKeys = collectInteractionKeys(from: profile)
        let result = filterByInteractions(
            candidateNames: catalog.allSupplements.map(\.name),
            interactionKeys: interactionKeys,
            allergies: profile.allergies,
            profile: profile
        )
        return result.excluded
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

    // MARK: - Plan Summary Generation

    func generatePlanSummary(supplements: [PlanSupplement], profile: UserProfile) -> String {
        var usedTopics: Set<String> = []

        let core = generateCoreSentence(supplements: supplements, profile: profile, usedTopics: &usedTopics)
        let lifestyle = generateLifestyleSentence(supplements: supplements, profile: profile, usedTopics: &usedTopics)
        let tip = generateTipSentence(supplements: supplements, profile: profile, usedTopics: &usedTopics)

        return [core, lifestyle, tip].compactMap { $0 }.joined(separator: " ")
    }

    private func generateCoreSentence(supplements: [PlanSupplement], profile: UserProfile, usedTopics: inout Set<String>) -> String {
        // Pick core-tier supplements, or fall back to top by score
        let coreSupplements = supplements.filter { $0.tier == .core }
        let topSupplements: [PlanSupplement]
        if !coreSupplements.isEmpty {
            topSupplements = Array(coreSupplements.prefix(2))
        } else {
            topSupplements = Array(supplements.sorted { $0.tierScore > $1.tierScore }.prefix(2))
        }

        guard !topSupplements.isEmpty else {
            return "Your personalized supplement plan is ready."
        }

        let names: String
        if topSupplements.count == 1 {
            names = topSupplements[0].name
        } else {
            names = "\(topSupplements[0].name) and \(topSupplements[1].name)"
        }

        // Gather top goal descriptors from user's goals
        let topGoalKeys = profile.healthGoals.prefix(2).map(\.rawValue)
        let goalPhrases = topGoalKeys.compactMap { Self.goalDescriptors[$0] }

        let goalPhrase: String
        if goalPhrases.count == 2 {
            goalPhrase = "\(goalPhrases[0]) and \(goalPhrases[1])"
        } else if goalPhrases.count == 1 {
            goalPhrase = goalPhrases[0]
        } else {
            goalPhrase = "your health goals"
        }

        return "Your plan is built around \(names) as your foundation for \(goalPhrase)."
    }

    private func generateLifestyleSentence(supplements: [PlanSupplement], profile: UserProfile, usedTopics: inout Set<String>) -> String? {
        let supplementNames = Set(supplements.map(\.name))
        let hasCaffeine = profile.coffeeCupsDaily > 0 || profile.teaCupsDaily > 0 || profile.energyDrinksDaily > 0
        let highStress = profile.stressLevel == .high || profile.stressLevel == .veryHigh
        let isActive = profile.exerciseFrequency == .threeToFour || profile.exerciseFrequency == .fivePlus
        let isVeganOrVegetarian = profile.dietType == .vegan || profile.dietType == .vegetarian
        let lowSleep = profile.baselineSleep <= 4

        // Priority 1: Caffeine + L-Theanine
        if hasCaffeine && supplementNames.contains("L-Theanine") {
            usedTopics.insert("caffeine")
            return "Since you drink coffee daily, we've included L-Theanine to smooth out the energy and keep your focus steady."
        }

        // Priority 2: High stress + Ashwagandha
        if highStress && supplementNames.contains("Ashwagandha KSM-66") {
            usedTopics.insert("stress")
            return "With your stress running high, Ashwagandha is here to help take the edge off and support your resilience over time."
        }

        // Priority 3: Active exercise + Creatine
        if isActive && supplementNames.contains("Creatine Monohydrate") {
            usedTopics.insert("exercise")
            return "With your active exercise routine, Creatine will support your recovery and help you get more out of each session."
        }

        // Priority 4: Vegan/vegetarian + B12/D3
        if isVeganOrVegetarian && (supplementNames.contains("Vitamin B Complex") || supplementNames.contains("Vitamin D3 + K2")) {
            usedTopics.insert("diet")
            return "As a \(profile.dietType.label.lowercased()), we've added key nutrients that are harder to get from diet alone."
        }

        // Priority 5: Low sleep baseline + Magnesium
        if lowSleep && supplementNames.contains("Magnesium Glycinate") {
            usedTopics.insert("sleep")
            return "With sleep being a challenge right now, Magnesium Glycinate will help you wind down and improve your sleep quality over time."
        }

        return nil
    }

    private func generateTipSentence(supplements: [PlanSupplement], profile: UserProfile, usedTopics: inout Set<String>) -> String? {
        let supplementNames = Set(supplements.map(\.name))

        // Magnesium timing tip (skip if sleep topic already used)
        if !usedTopics.contains("sleep") && supplementNames.contains("Magnesium Glycinate") {
            return "Take your Magnesium about 30 minutes before bed for the best results."
        }

        // Mag + D3 synergy (skip if diet topic already used)
        if !usedTopics.contains("diet") && supplementNames.contains("Magnesium Glycinate") && supplementNames.contains("Vitamin D3 + K2") {
            return "Your Magnesium and Vitamin D3 work together — Magnesium helps your body activate vitamin D."
        }

        // Ashwagandha consistency note (skip if stress topic already used)
        if !usedTopics.contains("stress") && supplementNames.contains("Ashwagandha KSM-66") {
            return "Most people start noticing changes within the first 2-4 weeks of consistent use."
        }

        // Omega-3 with food tip
        if supplementNames.contains("Omega-3 (EPA/DHA)") {
            return "Take your Omega-3 with a meal containing some fat for better absorption."
        }

        // Probiotics timing tip
        if supplementNames.contains("Probiotics") {
            return "Take your Probiotics on an empty stomach first thing in the morning for best results."
        }

        // General consistency tip
        return "Consistency is key — most supplements need 2-4 weeks of daily use before you'll notice changes."
    }
}
