import Foundation

@Observable
class SupplementCatalog {
    // MARK: - Public State

    private(set) var allSupplements: [Supplement] = []
    private(set) var isLoaded: Bool = false
    var loadError: Error?

    // MARK: - Internal Indexes

    private var supplementsByName: [String: Supplement] = [:]
    private var supplementsById: [UUID: Supplement] = [:]
    private var dbSupplementsByName: [String: DBSupplement] = [:]
    private var dbSupplementsById: [UUID: DBSupplement] = [:]
    private var goalMap: [String: [GoalSupplementEntry]] = [:]
    private var categoryIndex: [String: [Supplement]] = [:]
    private(set) var synergies: [String: [(partner: String, mechanism: String)]] = [:]

    // MARK: - Populate from Supabase Data

    func populate(supplements: [DBSupplement], goalMaps: [DBSupplementGoalMap], synergyPairings: [DBSynergisticPairing]) {
        // Build goal map by supplement ID
        var goalsBySupplementId: [UUID: [String]] = [:]
        for gm in goalMaps {
            goalsBySupplementId[gm.supplementId, default: []].append(gm.healthGoal)
        }

        // Build goal → supplement entry map
        var newGoalMap: [String: [GoalSupplementEntry]] = [:]
        for gm in goalMaps {
            let name = supplements.first(where: { $0.id == gm.supplementId })?.name ?? ""
            guard !name.isEmpty else { continue }
            let entry = GoalSupplementEntry(name: name, weight: gm.evidenceWeight.intValue)
            newGoalMap[gm.healthGoal, default: []].append(entry)
        }

        // Convert DBSupplement → Supplement
        var newSupplements: [Supplement] = []
        var newByName: [String: Supplement] = [:]
        var newById: [UUID: Supplement] = [:]
        var newDbByName: [String: DBSupplement] = [:]
        var newDbById: [UUID: DBSupplement] = [:]
        var newCategoryIndex: [String: [Supplement]] = [:]

        for dbSupp in supplements {
            let benefits = goalsBySupplementId[dbSupp.id] ?? []
            let supplement = dbSupp.toSupplement(benefits: benefits)

            newSupplements.append(supplement)
            newByName[supplement.name] = supplement
            newById[supplement.id] = supplement
            newDbByName[dbSupp.name] = dbSupp
            newDbById[dbSupp.id] = dbSupp
            newCategoryIndex[supplement.category, default: []].append(supplement)
        }

        // Build synergy index
        var newSynergies: [String: [(partner: String, mechanism: String)]] = [:]
        for pairing in synergyPairings {
            let nameA = supplements.first(where: { $0.id == pairing.supplementAId })?.name
                ?? pairing.supplementAName ?? ""
            let nameB = supplements.first(where: { $0.id == pairing.supplementBId })?.name
                ?? pairing.supplementBName ?? ""

            guard !nameA.isEmpty && !nameB.isEmpty else { continue }

            newSynergies[nameA, default: []].append((partner: nameB, mechanism: pairing.mechanism))
            if pairing.directionality == .bidirectional {
                newSynergies[nameB, default: []].append((partner: nameA, mechanism: pairing.mechanism))
            }
        }

        // Commit all at once
        allSupplements = newSupplements
        supplementsByName = newByName
        supplementsById = newById
        dbSupplementsByName = newDbByName
        dbSupplementsById = newDbById
        goalMap = newGoalMap
        categoryIndex = newCategoryIndex
        synergies = newSynergies
        isLoaded = true
        loadError = nil
    }

    // MARK: - Populate from Static Fallback (demo mode)

    func populateFromStatic() {
        let staticSupplements = SupplementKnowledgeBase.allSupplements
        var newByName: [String: Supplement] = [:]
        var newById: [UUID: Supplement] = [:]
        var newCategoryIndex: [String: [Supplement]] = [:]

        for supplement in staticSupplements {
            newByName[supplement.name] = supplement
            newById[supplement.id] = supplement
            newCategoryIndex[supplement.category, default: []].append(supplement)
        }

        // Convert static goal map
        var newGoalMap: [String: [GoalSupplementEntry]] = [:]
        for (goal, entries) in SupplementKnowledgeBase.goalSupplementMap {
            newGoalMap[goal] = entries
        }

        // Convert static synergies from RecommendationEngine format
        let staticSynergies: [String: [(partner: String, reason: String)]] = [
            "L-Theanine": [("caffeine", "promotes calm, focused energy without jitters")],
            "Vitamin C": [
                ("Iron", "enhances iron absorption by up to 6x"),
                ("Collagen Peptides", "essential cofactor for collagen synthesis"),
                ("NAC", "supports glutathione production"),
            ],
            "Iron": [("Vitamin C", "enhances iron absorption by up to 6x")],
            "Vitamin D3 + K2": [("Magnesium Glycinate", "magnesium aids vitamin D metabolism and activation")],
            "Magnesium Glycinate": [("Vitamin D3 + K2", "aids vitamin D metabolism and activation")],
            "Collagen Peptides": [("Vitamin C", "essential cofactor for collagen synthesis")],
            "CoQ10": [("Omega-3 (EPA/DHA)", "complementary cardiovascular support")],
            "Omega-3 (EPA/DHA)": [
                ("CoQ10", "complementary cardiovascular support"),
                ("Creatine Monohydrate", "combined recovery and anti-inflammatory support"),
            ],
            "NAC": [("Vitamin C", "supports glutathione production")],
            "Creatine Monohydrate": [("Omega-3 (EPA/DHA)", "combined recovery and anti-inflammatory support")],
        ]

        var newSynergies: [String: [(partner: String, mechanism: String)]] = [:]
        for (name, partners) in staticSynergies {
            newSynergies[name] = partners.map { (partner: $0.partner, mechanism: $0.reason) }
        }

        // Build DB supplement equivalents for onset data
        for supplement in staticSupplements {
            if let onset = SupplementKnowledgeBase.onsetTimelines[supplement.name] {
                // Store onset data in dbSupplementsByName for lookup
                let dbSupp = DBSupplement(
                    id: supplement.id,
                    name: supplement.name,
                    slug: supplement.name.lowercased().replacingOccurrences(of: " ", with: "-"),
                    category: DBSupplementCategory(rawValue: supplement.category) ?? .botanical,
                    commonDosageRange: supplement.commonDosageRange,
                    recommendedDosageMg: supplement.recommendedDosageMg,
                    dosageUnit: "mg",
                    timingOfDay: .morning,
                    foodTiming: .either,
                    evidenceClassification: supplement.evidenceLevel == .strong ? .extensiveResearch :
                        supplement.evidenceLevel == .moderate ? .clinicalResearch : .emergingResearch,
                    formAndBioavailability: supplement.formAndBioavailability,
                    dosageRationale: supplement.dosageRationale,
                    expectedTimeline: supplement.expectedTimeline,
                    whatToLookFor: supplement.whatToLookFor,
                    notes: supplement.notes,
                    availabilityTier: nil,
                    costTier: nil,
                    onsetMinDays: onset.min,
                    onsetMaxDays: onset.max,
                    onsetDescription: onset.description,
                    createdAt: nil,
                    updatedAt: nil
                )
                dbSupplementsByName[supplement.name] = dbSupp
                dbSupplementsById[supplement.id] = dbSupp
            }
        }

        allSupplements = staticSupplements
        supplementsByName = newByName
        supplementsById = newById
        goalMap = newGoalMap
        categoryIndex = newCategoryIndex
        synergies = newSynergies
        isLoaded = true
        loadError = nil
    }

    // MARK: - Lookups (mirror SupplementKnowledgeBase API)

    func supplement(named name: String) -> Supplement? {
        supplementsByName[name]
    }

    func supplement(byId id: UUID) -> Supplement? {
        supplementsById[id]
    }

    func dbSupplement(named name: String) -> DBSupplement? {
        dbSupplementsByName[name]
    }

    func weight(for supplementName: String, goal goalKey: String) -> Int {
        goalMap[goalKey]?.first(where: { $0.name == supplementName })?.weight ?? 0
    }

    func goalMappings(for goalKey: String) -> [GoalSupplementEntry] {
        goalMap[goalKey] ?? []
    }

    func supplements(for goalKey: String) -> [Supplement] {
        guard let entries = goalMap[goalKey] else { return [] }
        return entries.compactMap { supplement(named: $0.name) }
    }

    var supplementsByCategory: [(category: String, label: String, supplements: [Supplement])] {
        let orderedCategories: [String] = {
            var seen = Set<String>()
            var ordered: [String] = []
            for supplement in allSupplements {
                if seen.insert(supplement.category).inserted {
                    ordered.append(supplement.category)
                }
            }
            return ordered
        }()

        return orderedCategories.map { cat in
            (category: cat,
             label: Self.categoryLabel(for: cat),
             supplements: categoryIndex[cat] ?? [])
        }
    }

    var goalSupplementMap: [String: [GoalSupplementEntry]] {
        goalMap
    }

    // MARK: - Category Labels

    static func categoryLabel(for key: String) -> String {
        switch key {
        case "mineral": return "Minerals"
        case "vitamin": return "Vitamins"
        case "fatty_acid": return "Fatty Acids"
        case "adaptogen": return "Adaptogens"
        case "amino_acid": return "Amino Acids"
        case "probiotic": return "Probiotics"
        case "coenzyme": return "Coenzymes"
        case "protein": return "Proteins"
        case "mushroom": return "Mushrooms"
        case "hormone": return "Hormones"
        case "plant_extract": return "Plant Extracts"
        case "fruit_extract": return "Fruit Extracts"
        default: return key.capitalized
        }
    }

    /// Check if a supplement has a drug interaction with any of the given medication keywords
    func hasInteraction(supplement: Supplement, medications: [String], drugInteractions: [DBDrugInteraction]) -> Bool {
        let medKeywords = medications.flatMap { med in
            med.lowercased().split(separator: " ").map(String.init)
        }

        for interaction in drugInteractions where interaction.supplementId == supplement.id {
            let drugNameLower = interaction.drugName.lowercased()
            let drugClassLower = interaction.drugClass?.lowercased() ?? ""

            if medKeywords.contains(where: { keyword in
                drugNameLower.contains(keyword) || keyword.contains(drugNameLower) ||
                drugClassLower.contains(keyword) || keyword.contains(drugClassLower)
            }) {
                return true
            }
        }

        return false
    }

    /// Find supplements to exclude based on drug interactions
    func interactionsForMedication(_ medication: String, drugInteractions: [DBDrugInteraction]) -> [String] {
        let keywords = medication.lowercased().split(separator: " ").map(String.init)
        var supplementNames: Set<String> = []

        for interaction in drugInteractions {
            let drugNameLower = interaction.drugName.lowercased()
            let drugClassLower = interaction.drugClass?.lowercased() ?? ""

            if keywords.contains(where: { keyword in
                drugNameLower.contains(keyword) || keyword.contains(drugNameLower) ||
                drugClassLower.contains(keyword) || keyword.contains(drugClassLower)
            }) {
                if let name = supplement(byId: interaction.supplementId)?.name ?? interaction.supplementName {
                    supplementNames.insert(name)
                }
            }
        }

        return Array(supplementNames)
    }
}
