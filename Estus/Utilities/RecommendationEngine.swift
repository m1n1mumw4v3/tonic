import Foundation

struct RecommendationEngine {
    private let catalog: SupplementCatalog
    private let drugInteractions: [DBDrugInteraction]
    private let contraindications: [DBContraindication]
    private let medications: [DBMedication]
    private let deepProfileModules: [DeepProfileModule]

    init(catalog: SupplementCatalog,
         drugInteractions: [DBDrugInteraction] = [],
         contraindications: [DBContraindication] = [],
         medications: [DBMedication] = [],
         deepProfileModules: [DeepProfileModule] = []) {
        self.catalog = catalog
        self.drugInteractions = drugInteractions
        self.contraindications = contraindications
        self.medications = medications
        self.deepProfileModules = deepProfileModules
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
        var candidateGoalScores: [String: Int] = [:]  // Goal-only weights (no personalization/safety boosts)
        let goalKeys = profile.healthGoals.map { $0.rawValue }

        for goal in goalKeys {
            let entries = catalog.goalMappings(for: goal)
            for entry in entries {
                candidateScores[entry.name, default: 0] += entry.weight
                candidateGoalScores[entry.name, default: 0] += entry.weight
            }
        }

        // Step 1b: Apply personalization signal adjustments
        let adjustments = PersonalizationScorer.evaluate(
            profile: profile,
            signals: catalog.allPersonalizationSignals,
            catalog: catalog
        )
        for adj in adjustments {
            candidateScores[adj.supplementName, default: 0] += adj.delta
        }

        // Step 1b2: Apply safety rule score boosts (e.g., PPI → boost minerals)
        let safetyBoosts = SafetyRules.scoreBoosts(profile: profile, deepProfileModules: deepProfileModules)
        for (name, boost) in safetyBoosts {
            candidateScores[name, default: 0] += boost
        }

        // Step 1c: Dedup against current supplements
        let dedupMatches = SupplementNameMatcher.match(
            userSupplements: profile.currentSupplements, catalog: catalog
        )
        var formVariantMatches: [String: SupplementNameMatcher.MatchResult] = [:]
        for match in dedupMatches {
            switch match.matchType {
            case .exact, .commonName:
                candidateScores.removeValue(forKey: match.catalogName)
            case .formVariant:
                formVariantMatches[match.catalogName] = match
            case .partial:
                break // keep in plan, flag for user review
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

        var filteredCandidates = candidateScores.filter { !filterResult.excluded.contains($0.key) }

        // Step 2b: Exclusion group filtering — keep highest-scored per group, tiebreak by priority
        for (_, members) in catalog.exclusionGroups {
            let groupNames = Set(members.map(\.supplementName))
            let present = filteredCandidates.filter { groupNames.contains($0.key) }
            guard present.count > 1 else { continue }

            // Build priority lookup
            let priorityMap = Dictionary(uniqueKeysWithValues: members.map { ($0.supplementName, $0.priority) })

            // Pick the winner: highest score, then lowest priority number as tiebreak
            let winner = present.max { a, b in
                if a.value != b.value { return a.value < b.value }
                return (priorityMap[a.key] ?? Int.max) > (priorityMap[b.key] ?? Int.max)
            }

            // Remove losers
            for name in present.keys where name != winner?.key {
                filteredCandidates.removeValue(forKey: name)
            }
        }

        // Step 3: Filter out supplements with zero goal overlap (boost-only filler)
        // Force-adds (vegan, birth control, PPI) happen after selectTierAware via addIfMissing
        let goalFiltered = filteredCandidates.filter { candidateGoalScores[$0.key, default: 0] > 0 }

        // Sort by score (goal overlap), then apply diversity
        let ranked = goalFiltered.sorted { a, b in
            if a.value != b.value { return a.value > b.value }
            return a.key < b.key
        }

        // Step 4: Tier-aware selection (no category cap)
        var selected = selectTierAware(from: ranked, excluded: filterResult.excluded)

        // Ensure vegan/vegetarian get B12 and D3
        if profile.dietType == .vegan || profile.dietType == .vegetarian {
            addIfMissing("Vitamin B Complex", to: &selected, excluded: filterResult.excluded)
            addIfMissing("Vitamin D3 + K2", to: &selected, excluded: filterResult.excluded)
        }

        // Birth control / HRT → force B Complex
        let hormonalResponse = deepProfileModules.first(where: { $0.moduleId == .hormonalMetabolic })
            .flatMap { $0.responses["hormonal_birth_control_hrt"]?.stringValue }
        if hormonalResponse == "birth_control" || hormonalResponse == "hrt" {
            addIfMissing("Vitamin B Complex", to: &selected, excluded: filterResult.excluded)
        }

        // PPI → force B Complex
        let ppiNames: Set<String> = ["omeprazole", "prilosec", "pantoprazole", "protonix", "esomeprazole", "nexium", "lansoprazole", "prevacid", "rabeprazole", "aciphex", "dexlansoprazole", "dexilant"]
        let hasPPIMed = profile.medications.contains { ppiNames.contains($0.lowercased()) }
        let hasPPIGut = deepProfileModules.first(where: { $0.moduleId == .gutHealth })
            .flatMap { $0.responses["gut_ppi_usage"]?.stringValue } == "yes_currently"
        if hasPPIMed || hasPPIGut {
            addIfMissing("Vitamin B Complex", to: &selected, excluded: filterResult.excluded)
        }

        // Step 5: Build plan supplements with dosage adjustments, timing, tier data, and enriched info
        let userGoalKeys = Set(profile.healthGoals.map { $0.rawValue })

        // Collect fired signals for whatToLookFor personalization
        let firedSignals = collectFiredSignals(profile: profile, candidateNames: Set(selected.map(\.name)))

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

            // Check for form-variant upgrade note
            let upgradeNote: String? = {
                guard let match = formVariantMatches[supplement.name] else { return nil }
                let inputLowered = match.userInputName.lowercased()
                return SupplementNameMatcher.formUpgradeMessages[inputLowered]
                    ?? "You're currently taking \(match.userInputName). We've recommended \(supplement.name) — a more bioavailable form."
            }()

            // Prepend upgrade note to whyInYourPlan if present
            let baseWhy = generateWhyInYourPlan(supplement: supplement, matchedGoals: Array(matched), profile: profile, firedSignals: firedSignals)
            let whyText = upgradeNote != nil ? "\(upgradeNote!) \(baseWhy)" : baseWhy

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
                whyInYourPlan: whyText,
                dosageRationale: generateDosageRationale(supplement: supplement, profile: profile),
                expectedTimeline: supplement.expectedTimeline,
                whatToLookFor: resolveWhatToLookFor(template: supplement.whatToLookFor, profile: profile, supplementName: supplement.name, firedSignals: firedSignals),
                formAndBioavailability: supplement.formAndBioavailability,
                evidenceDisplay: supplement.evidenceLevel.displayText,
                evidenceLevel: supplement.evidenceLevel,
                interactionWarnings: interactionWarnings,
                formUpgradeNote: upgradeNote
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

            // Append safety rule warnings
            for rule in SafetyRules.allRules {
                if rule.condition(profile, deepProfileModules) &&
                   rule.warnSupplements.contains(planSupplements[i].name) {
                    let existing = planSupplements[i].interactionNote ?? ""
                    let separator = existing.isEmpty ? "" : " "
                    planSupplements[i].interactionNote = existing + separator + rule.warningMessage
                }
            }

            // Multivitamin iron overlap detection
            if planSupplements[i].name == "Iron" {
                let multiVitaminKeywords = ["multivitamin", "multi-vitamin", "multi vitamin", "centrum", "one a day"]
                let hasMultivitamin = profile.currentSupplements.contains { supp in
                    let lowered = supp.lowercased()
                    return multiVitaminKeywords.contains { lowered.contains($0) }
                }
                if hasMultivitamin {
                    let existing = planSupplements[i].interactionNote ?? ""
                    let separator = existing.isEmpty ? "" : " "
                    planSupplements[i].interactionNote = existing + separator + "Your multivitamin likely contains some iron. Consider checking the label before adding a standalone supplement."
                }
            }
        }

        // Resolve timing conflicts between mineral pairs
        resolveTimingConflicts(planSupplements: &planSupplements)

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
        var weightedScore = matched.reduce(0) { sum, goalKey in
            sum + catalog.weight(for: supplement.name, goal: goalKey)
        }

        // Apply personalization signal adjustments to score
        let adjustments = PersonalizationScorer.evaluate(
            profile: profile,
            signals: catalog.allPersonalizationSignals,
            catalog: catalog
        )
        for adj in adjustments where adj.supplementName == supplement.name {
            weightedScore += adj.delta
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
            whyInYourPlan: generateWhyInYourPlan(supplement: supplement, matchedGoals: Array(matched), profile: profile, firedSignals: collectFiredSignals(profile: profile, candidateNames: Set(existingSupplements.map(\.name) + [supplement.name]))),
            dosageRationale: generateDosageRationale(supplement: supplement, profile: profile),
            expectedTimeline: supplement.expectedTimeline,
            whatToLookFor: resolveWhatToLookFor(template: supplement.whatToLookFor, profile: profile, supplementName: supplement.name, firedSignals: collectFiredSignals(profile: profile, candidateNames: Set(existingSupplements.map(\.name) + [supplement.name]))),
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

    /// Maps signal types → supplement names → "why in your plan" sentence for boost-only supplements.
    private static let boostWhyTemplates: [String: [String: String]] = [
        "birth_control": [
            "Vitamin B Complex": "Hormonal birth control can deplete B6, B12, and folate — B Complex helps replenish these essential nutrients.",
            "Magnesium Glycinate": "Hormonal birth control increases magnesium excretion, making supplementation especially important.",
        ],
        "hrt": [
            "Vitamin B Complex": "Hormone replacement therapy increases demand for B vitamins, supporting energy and cognitive clarity.",
            "Magnesium Glycinate": "HRT can affect mineral balance — magnesium supports both sleep and cardiovascular health.",
        ],
        "ppi": [
            "Magnesium Glycinate": "Long-term PPI use reduces magnesium absorption — supplementation helps prevent deficiency.",
            "Vitamin B Complex": "PPIs impair B12 absorption over time — B Complex helps maintain healthy levels and energy.",
            "Iron": "PPIs reduce stomach acid needed for iron absorption — supplementation supports healthy iron stores.",
        ],
        "high_stress": [
            "Magnesium Glycinate": "High stress increases magnesium demand — supplementation supports calm and recovery.",
            "Ashwagandha KSM-66": "Given your elevated stress levels, Ashwagandha helps support stress resilience and balance.",
            "L-Theanine": "With elevated stress, L-Theanine promotes calm alertness without drowsiness.",
        ],
        "heavy_alcohol": [
            "Vitamin B Complex": "Alcohol depletes B vitamins, especially B1 and folate — B Complex helps replenish stores.",
            "NAC": "NAC supports glutathione production, which is heavily taxed by alcohol metabolism.",
            "Magnesium Glycinate": "Alcohol increases urinary magnesium excretion — supplementation supports recovery.",
            "Zinc": "Regular alcohol intake depletes zinc stores — supplementation supports immune function.",
        ],
        "vegan_diet": [
            "Iron": "Plant-based iron is less bioavailable — supplementation helps maintain healthy iron levels on a vegan diet.",
        ],
        "sleep_onset": [
            "Melatonin": "Based on your difficulty falling asleep, low-dose melatonin helps reset your sleep onset timing.",
        ],
        "sleep_maintenance": [
            "Magnesium Glycinate": "Based on your nighttime waking pattern, magnesium glycinate supports sleep continuity.",
        ],
        "low_sleep_baseline": [
            "Magnesium Glycinate": "With sleep being a challenge, magnesium glycinate supports better sleep onset and continuity.",
            "Melatonin": "With sleep quality below your potential, melatonin helps regulate your circadian rhythm.",
        ],
        "low_energy_baseline": [
            "Vitamin B Complex": "With your current energy levels, B vitamins support the energy metabolism your body needs.",
            "CoQ10": "Low baseline energy suggests your cells may benefit from CoQ10's mitochondrial support.",
        ],
        "age_50_plus": [
            "CoQ10": "Natural CoQ10 production declines with age — supplementation supports sustained energy.",
            "Collagen Peptides": "Collagen production decreases significantly after 50 — supplementation supports skin and joint health.",
        ],
    ]

    private func generateWhyInYourPlan(supplement: Supplement, matchedGoals: [String], profile: UserProfile, firedSignals: [FiredSignal] = []) -> String {
        // Diet-driven additions when no goal overlap
        if matchedGoals.isEmpty {
            if (profile.dietType == .vegan || profile.dietType == .vegetarian) &&
                (supplement.name == "Vitamin B Complex" || supplement.name == "Vitamin D3 + K2") {
                return "\(supplement.name) helps cover nutritional gaps common in a \(profile.dietType.label.lowercased()) diet, supporting overall energy and immune health."
            }

            // Look up fired signals for boost-only supplements
            let matching = firedSignals
                .filter { $0.supplementName == supplement.name }
                .sorted { $0.magnitude > $1.magnitude }
            for signal in matching {
                if let template = Self.boostWhyTemplates[signal.signalType]?[supplement.name] {
                    return template
                }
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
            "Tart Cherry Extract": "Tart cherry provides natural melatonin and anti-inflammatory compounds, supporting",
            "Whey Protein Isolate": "Whey protein isolate is a fast-absorbing complete protein with the highest leucine content, supporting",
            "Plant Protein Blend": "This pea and rice protein blend provides a complete amino acid profile without dairy, supporting"
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

        // Append legacy adjustment context
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

        // Append signal-based rationale
        let signals = catalog.personalizationSignals(for: supplement.id)
        for signal in signals {
            guard let profileValue = PersonalizationScorer.profileValue(field: signal.profileField, profile: profile) else { continue }
            guard profileValue.lowercased() == signal.condition.lowercased() else { continue }
            guard signal.effect?.lowercased() == "increase" || signal.effect?.lowercased() == "decrease" else { continue }

            if let signalRationale = signal.rationale, !signalRationale.isEmpty {
                let direction = signal.effect?.lowercased() == "increase" ? "upper" : "lower"
                rationale += " Adjusted to \(direction) range: \(signalRationale.prefix(1).lowercased())\(signalRationale.dropFirst())"
                break // Only append one signal rationale to avoid verbosity
            }
        }

        return rationale
    }

    // MARK: - Signal-to-Copy Mapping

    /// Maps signal types → supplement names → personalized guidance sentence.
    private static let signalCopyMap: [String: [String: String]] = [
        "vegan_diet": [
            "Vitamin B Complex": "On a plant-based diet, methylated B12 is especially important since it's not found in plant foods.",
            "Vitamin D3 + K2": "Plant-based diets lack dietary D3, making supplementation more important for maintaining optimal levels.",
            "Iron": "Plant-based iron (non-heme) is less bioavailable — taking with Vitamin C can significantly improve absorption.",
        ],
        "heavy_alcohol": [
            "Vitamin B Complex": "Alcohol depletes B vitamins, especially B1 and folate — consistent supplementation helps replenish stores.",
            "NAC": "NAC supports glutathione production, which is heavily taxed by alcohol metabolism.",
            "Magnesium Glycinate": "Alcohol increases urinary magnesium excretion — you may notice improved sleep and recovery.",
            "Zinc": "Regular alcohol intake depletes zinc stores, which impacts immune function and recovery.",
        ],
        "birth_control": [
            "Vitamin B Complex": "Hormonal birth control can deplete B6, B12, and folate — watch for improved energy and mood stability.",
            "Magnesium Glycinate": "Hormonal contraceptives increase magnesium excretion, making supplementation more impactful.",
        ],
        "hrt": [
            "Vitamin B Complex": "HRT can increase demand for B vitamins — watch for improvements in energy and cognitive clarity.",
            "Magnesium Glycinate": "Hormone therapy can affect mineral balance — magnesium supports both sleep and cardiovascular health.",
        ],
        "ppi": [
            "Magnesium Glycinate": "PPIs reduce magnesium absorption over time — supplementation helps prevent deficiency.",
            "Vitamin B Complex": "Long-term PPI use impairs B12 absorption — watch for improved energy as stores replenish.",
            "Iron": "PPIs reduce stomach acid needed for iron absorption — consider taking iron away from PPI timing.",
        ],
        "sleep_onset": [
            "Melatonin": "Based on your reported difficulty falling asleep, low-dose melatonin may help reset your sleep onset timing.",
        ],
        "sleep_maintenance": [
            "Magnesium Glycinate": "Based on your nighttime waking pattern, magnesium glycinate may help improve sleep continuity.",
        ],
        "age_50_plus": [
            "CoQ10": "Natural CoQ10 production declines with age — you may notice improved sustained energy.",
            "Collagen Peptides": "Collagen production decreases significantly after 50 — consistent supplementation supports skin elasticity and joint health.",
        ],
        "low_sleep_baseline": [
            "Magnesium Glycinate": "Given your current sleep quality, improvements in sleep onset and continuity may be especially noticeable.",
            "Melatonin": "With sleep being a challenge, even small improvements in sleep onset timing can have a big impact.",
        ],
        "low_energy_baseline": [
            "Vitamin B Complex": "With your current energy levels, B vitamin support for energy metabolism may be especially noticeable.",
            "CoQ10": "Low baseline energy suggests your mitochondrial support may benefit most from CoQ10.",
        ],
        "high_stress": [
            "Ashwagandha KSM-66": "Given your high stress levels, you may notice reduced anxiety and improved stress resilience within 2-4 weeks.",
            "L-Theanine": "With elevated stress, L-Theanine's calming effect may be especially noticeable during high-pressure moments.",
            "Magnesium Glycinate": "High stress increases magnesium demand — you may notice a calming effect, especially in the evening.",
        ],
    ]

    /// Fired signal: (supplement name, signal type, magnitude weight for sorting)
    typealias FiredSignal = (supplementName: String, signalType: String, magnitude: Int)

    /// Collect which signals fired for which supplements based on profile and deep profile data.
    private func collectFiredSignals(profile: UserProfile, candidateNames: Set<String>) -> [FiredSignal] {
        var signals: [FiredSignal] = []

        let isVegan = profile.dietType == .vegan
        let isVegetarian = profile.dietType == .vegetarian
        let heavyAlcohol = profile.alcoholWeekly == .eightPlus
        let highStress = profile.stressLevel == .high || profile.stressLevel == .veryHigh
        let lowSleepBaseline = profile.baselineSleep <= 4
        let lowEnergyBaseline = profile.baselineEnergy <= 4
        let age50Plus = profile.age >= 50

        if isVegan || isVegetarian {
            for name in ["Vitamin B Complex", "Vitamin D3 + K2", "Iron"] where candidateNames.contains(name) {
                signals.append((name, "vegan_diet", 3))
            }
        }

        if heavyAlcohol {
            for name in ["Vitamin B Complex", "NAC", "Magnesium Glycinate", "Zinc"] where candidateNames.contains(name) {
                signals.append((name, "heavy_alcohol", 2))
            }
        }

        // Birth control / HRT from deep profile
        let hormonalResponse = deepProfileModules.first(where: { $0.moduleId == .hormonalMetabolic })
            .flatMap { $0.responses["hormonal_birth_control_hrt"]?.stringValue }
        if hormonalResponse == "birth_control" {
            for name in ["Vitamin B Complex", "Magnesium Glycinate"] where candidateNames.contains(name) {
                signals.append((name, "birth_control", 3))
            }
        } else if hormonalResponse == "hrt" {
            for name in ["Vitamin B Complex", "Magnesium Glycinate"] where candidateNames.contains(name) {
                signals.append((name, "hrt", 3))
            }
        }

        // PPI (from medications or gut module)
        let ppiNames: Set<String> = ["omeprazole", "prilosec", "pantoprazole", "protonix", "esomeprazole", "nexium", "lansoprazole", "prevacid", "rabeprazole", "aciphex", "dexlansoprazole", "dexilant"]
        let hasPPI = profile.medications.contains { ppiNames.contains($0.lowercased()) }
        let hasPPIGut = deepProfileModules.first(where: { $0.moduleId == .gutHealth })
            .flatMap { $0.responses["gut_ppi_usage"]?.stringValue } == "yes_currently"
        if hasPPI || hasPPIGut {
            for name in ["Magnesium Glycinate", "Vitamin B Complex", "Iron"] where candidateNames.contains(name) {
                signals.append((name, "ppi", 3))
            }
        }

        // Sleep signals from deep profile
        if let sleepModule = deepProfileModules.first(where: { $0.moduleId == .sleepCircadian }) {
            if let onset = sleepModule.responses["sleep_onset_latency"]?.stringValue,
               onset == "40_60" || onset == "over_60" || onset == "20_40" {
                if candidateNames.contains("Melatonin") {
                    signals.append(("Melatonin", "sleep_onset", onset == "20_40" ? 2 : 3))
                }
            }
            if let wakes = sleepModule.responses["sleep_wake_frequency"]?.stringValue,
               wakes == "three_plus" || wakes == "twice" {
                if candidateNames.contains("Magnesium Glycinate") {
                    signals.append(("Magnesium Glycinate", "sleep_maintenance", wakes == "twice" ? 2 : 3))
                }
            }
        }

        if age50Plus {
            for name in ["CoQ10", "Collagen Peptides"] where candidateNames.contains(name) {
                signals.append((name, "age_50_plus", 2))
            }
        }

        if lowSleepBaseline {
            for name in ["Magnesium Glycinate", "Melatonin"] where candidateNames.contains(name) {
                signals.append((name, "low_sleep_baseline", 2))
            }
        }

        if lowEnergyBaseline {
            for name in ["Vitamin B Complex", "CoQ10"] where candidateNames.contains(name) {
                signals.append((name, "low_energy_baseline", 2))
            }
        }

        if highStress {
            for name in ["Ashwagandha KSM-66", "L-Theanine", "Magnesium Glycinate"] where candidateNames.contains(name) {
                signals.append((name, "high_stress", 2))
            }
        }

        return signals
    }

    private func resolveWhatToLookFor(template: String, profile: UserProfile, supplementName: String = "", firedSignals: [FiredSignal] = []) -> String {
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

        // Append signal-based personalized copy (top 2 by magnitude)
        if !supplementName.isEmpty {
            let matching = firedSignals
                .filter { $0.supplementName == supplementName }
                .sorted { $0.magnitude > $1.magnitude }

            var appended = 0
            for signal in matching {
                guard appended < 2 else { break }
                if let copy = Self.signalCopyMap[signal.signalType]?[supplementName] {
                    text += " " + copy
                    appended += 1
                }
            }
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

    // MARK: - Tier-Aware Selection

    private func selectTierAware(from ranked: [(key: String, value: Int)], excluded: Set<String>) -> [Supplement] {
        // Assign provisional tiers: Core ≥5, Targeted ≥3, Supporting <3
        var core: [(Supplement, Int)] = []
        var targeted: [(Supplement, Int)] = []
        var supporting: [(Supplement, Int)] = []

        for (name, score) in ranked {
            guard let supplement = catalog.supplement(named: name) else { continue }
            if score >= 5 {
                core.append((supplement, score))
            } else if score >= 3 {
                targeted.append((supplement, score))
            } else {
                supporting.append((supplement, score))
            }
        }

        let maxSupplements = 7
        var selected: [Supplement] = []

        // 1. Select all Core candidates (up to max)
        for (supplement, _) in core {
            guard selected.count < maxSupplements else { break }
            selected.append(supplement)
        }

        // 2. Fill remaining slots with Targeted
        for (supplement, _) in targeted {
            guard selected.count < maxSupplements else { break }
            selected.append(supplement)
        }

        // 3. Add Supporting: if Core+Targeted < 5, fill up; otherwise allow at most 1
        let highTierCount = selected.count
        if highTierCount < 5 {
            for (supplement, _) in supporting {
                guard selected.count < maxSupplements else { break }
                selected.append(supplement)
            }
        } else {
            // Allow at most 1 Supporting when Core+Targeted ≥ 5
            if let first = supporting.first, selected.count < maxSupplements {
                selected.append(first.0)
            }
        }

        return selected
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

        // Minimum quality guarantee: ensure at least 2 Core+Targeted supplements
        let highTierCount = supplements.filter { $0.tier == .core || $0.tier == .targeted }.count
        if highTierCount < 2 {
            let promotionsNeeded = 2 - highTierCount
            // Promote top-scoring Supporting supplements to Targeted
            let supportingIndices = supplements.indices
                .filter { supplements[$0].tier == .supporting }
                .sorted { supplements[$0].tierScore > supplements[$1].tierScore }

            for i in supportingIndices.prefix(promotionsNeeded) {
                supplements[i].tier = .targeted
            }
        }
    }

    // MARK: - Timing Conflict Detection

    /// Mineral absorption conflict pairs
    private static let timingConflicts: [(a: String, b: String, reason: String)] = [
        ("Iron", "Zinc", "Iron and zinc compete for the DMT-1 transporter"),
        ("Iron", "Calcium", "Calcium inhibits iron absorption"),
        ("Zinc", "Calcium", "Zinc and calcium compete for absorption"),
        ("Magnesium Glycinate", "Iron", "Magnesium reduces iron absorption"),
    ]

    /// Resolve timing conflicts between mineral pairs in the plan.
    /// Adjusts timing or adds spacing notes for conflicting supplements.
    private func resolveTimingConflicts(planSupplements: inout [PlanSupplement]) {
        let nameToIndex: [String: Int] = Dictionary(
            planSupplements.enumerated().map { ($1.name, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        for conflict in Self.timingConflicts {
            guard let idxA = nameToIndex[conflict.a],
                  let idxB = nameToIndex[conflict.b] else { continue }

            // Skip if they already have different timings
            if planSupplements[idxA].timing != planSupplements[idxB].timing { continue }

            // Identify the lower-scored supplement as the one to move
            let moveIdx: Int
            let partnerIdx: Int
            if planSupplements[idxA].tierScore <= planSupplements[idxB].tierScore {
                moveIdx = idxA
                partnerIdx = idxB
            } else {
                moveIdx = idxB
                partnerIdx = idxA
            }

            let partnerName = planSupplements[partnerIdx].name

            // If the supplement to move has emptyStomach timing (e.g., Iron), don't change timing — just add spacing note
            if planSupplements[moveIdx].timing == .emptyStomach {
                let existing = planSupplements[moveIdx].interactionNote ?? ""
                let separator = existing.isEmpty ? "" : " "
                planSupplements[moveIdx].interactionNote = existing + separator + "\(conflict.reason). Take at least 2 hours apart from \(partnerName)."
                continue
            }

            // Shift to opposite time of day
            let newTiming: SupplementTiming
            switch planSupplements[moveIdx].timing {
            case .morning, .emptyStomach, .withFood:
                newTiming = .evening
            case .evening, .bedtime:
                newTiming = .morning
            case .afternoon:
                newTiming = .evening
            }

            planSupplements[moveIdx].timing = newTiming
            let existing = planSupplements[moveIdx].interactionNote ?? ""
            let separator = existing.isEmpty ? "" : " "
            planSupplements[moveIdx].interactionNote = existing + separator + "Timing adjusted to \(newTiming.label.lowercased()) to avoid absorption conflict with \(partnerName). \(conflict.reason). Take at least 2 hours apart."
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
        if allergyKeywords.contains("dairy") || allergyKeywords.contains("milk") || allergyKeywords.contains("lactose") {
            excluded.insert("Whey Protein Isolate")
        }

        // Diet-based exclusions
        if profile.dietType == .vegan || profile.dietType == .vegetarian {
            excluded.insert("Whey Protein Isolate")
        }

        // Pregnancy / breastfeeding contraindications
        if profile.isPregnant || profile.isBreastfeeding {
            excluded.insert("Ashwagandha KSM-66")
            excluded.insert("Berberine")
        }

        // Safety-critical deep profile rules
        for rule in SafetyRules.allRules {
            if rule.condition(profile, deepProfileModules) {
                for name in rule.excludeSupplements {
                    excluded.insert(name)
                }
            }
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

        // 1. Apply personalization signal dose adjustments
        let signals = catalog.personalizationSignals(for: supplement.id)
        for signal in signals {
            guard let profileValue = PersonalizationScorer.profileValue(field: signal.profileField, profile: profile) else { continue }
            guard profileValue.lowercased() == signal.condition.lowercased() else { continue }

            let multiplier: Double
            switch signal.magnitude?.lowercased() {
            case "minor": multiplier = 1.15
            case "moderate": multiplier = 1.25
            case "major": multiplier = 1.5
            default: multiplier = 1.0
            }

            if signal.effect?.lowercased() == "decrease" {
                dosage *= (1.0 / multiplier)
            } else if signal.effect?.lowercased() == "increase" {
                dosage *= multiplier
            }
        }

        // 2. Apply legacy hardcoded rules as safety net
        dosage = applyLegacyDosageRules(dosage, supplement: supplement, profile: profile)

        // 3. Clamp to safe range from KB
        if let range = catalog.doseRange(for: supplement.name) {
            if range.low > 0 && range.high > 0 {
                dosage = max(range.low, min(dosage, range.high))
            }
            if let limit = range.limit {
                dosage = min(dosage, limit)
            }
        }

        return dosage
    }

    /// Legacy hardcoded dosage rules — kept as fallback until all rules are expressed as personalization signals.
    private func applyLegacyDosageRules(_ dosage: Double, supplement: Supplement, profile: UserProfile) -> Double {
        var result = dosage

        // Age adjustments
        if profile.age > 65 {
            if ["Rhodiola Rosea", "CoQ10"].contains(supplement.name) {
                result *= 0.75
            }
        }

        // Sex-based adjustments
        if profile.sex == .female && supplement.name == "Iron" {
            result = 27
        } else if profile.sex == .male && supplement.name == "Iron" {
            result = 8
        }

        // Weight-based adjustments for fat-soluble vitamins
        if let weight = profile.weightLbs, weight > 200 {
            if supplement.name == "Vitamin D3 + K2" {
                result = 4000
            }
        }

        return result
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

        // Priority 3b: Active exercise + Protein (without Creatine)
        if isActive && !supplementNames.contains("Creatine Monohydrate") {
            if supplementNames.contains("Whey Protein Isolate") {
                usedTopics.insert("exercise")
                return "With your active exercise routine, Whey Protein will help maximize your recovery and muscle protein synthesis."
            }
            if supplementNames.contains("Plant Protein Blend") {
                usedTopics.insert("exercise")
                return "With your active exercise routine, Plant Protein will support your recovery with a complete amino acid profile."
            }
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
