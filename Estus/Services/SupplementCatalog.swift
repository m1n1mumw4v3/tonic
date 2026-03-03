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
    private var exclusionGroupIndex: [String: [(supplementName: String, priority: Int)]] = [:]
    private var signalsBySupplementId: [UUID: [SupabasePersonalizationSignal]] = [:]
    private var signalsByField: [String: [SupabasePersonalizationSignal]] = [:]
    private(set) var allPersonalizationSignals: [SupabasePersonalizationSignal] = []

    // MARK: - Populate from Supabase Data

    func populate(supplements: [DBSupplement], goalMaps: [DBSupplementGoalMap], synergyPairings: [DBSynergisticPairing], personalizationSignals: [SupabasePersonalizationSignal] = []) {
        // Build goal map by supplement ID
        var goalsBySupplementId: [UUID: [String]] = [:]
        for gm in goalMaps {
            goalsBySupplementId[gm.supplementId, default: []].append(gm.goal)
        }

        // Build goal → supplement entry map
        var newGoalMap: [String: [GoalSupplementEntry]] = [:]
        for gm in goalMaps {
            let name = supplements.first(where: { $0.id == gm.supplementId })?.name ?? ""
            guard !name.isEmpty else { continue }
            let entry = GoalSupplementEntry(name: name, weight: gm.weightInt)
            newGoalMap[gm.goal, default: []].append(entry)
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
            let nameA = supplements.first(where: { $0.id == pairing.supplementId })?.name ?? ""
            let nameB = pairing.partnerName

            guard !nameA.isEmpty && !nameB.isEmpty else { continue }
            let mech = pairing.mechanism ?? ""

            newSynergies[nameA, default: []].append((partner: nameB, mechanism: mech))
            if pairing.directionality == "bidirectional" {
                newSynergies[nameB, default: []].append((partner: nameA, mechanism: mech))
            }
        }

        // Build exclusion group index from static data (will be replaced by Supabase table later)
        var newExclusionGroups: [String: [(supplementName: String, priority: Int)]] = [:]
        for entry in SupplementKnowledgeBase.exclusionGroups {
            newExclusionGroups[entry.groupKey, default: []].append((supplementName: entry.supplementName, priority: entry.priority))
        }
        for key in newExclusionGroups.keys {
            newExclusionGroups[key]?.sort { $0.priority < $1.priority }
        }

        // Build personalization signal indexes
        var newSignalsBySuppId: [UUID: [SupabasePersonalizationSignal]] = [:]
        var newSignalsByField: [String: [SupabasePersonalizationSignal]] = [:]
        for signal in personalizationSignals {
            newSignalsBySuppId[signal.supplementId, default: []].append(signal)
            newSignalsByField[signal.profileField, default: []].append(signal)
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
        exclusionGroupIndex = newExclusionGroups
        allPersonalizationSignals = personalizationSignals
        signalsBySupplementId = newSignalsBySuppId
        signalsByField = newSignalsByField
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
            "Creatine Monohydrate": [
                ("Omega-3 (EPA/DHA)", "combined recovery and anti-inflammatory support"),
                ("Whey Protein Isolate", "creatine plus protein maximizes post-workout muscle protein synthesis"),
                ("Plant Protein Blend", "creatine plus protein maximizes post-workout muscle protein synthesis"),
            ],
            "Whey Protein Isolate": [("Creatine Monohydrate", "protein plus creatine maximizes post-workout muscle protein synthesis")],
            "Plant Protein Blend": [("Creatine Monohydrate", "protein plus creatine maximizes post-workout muscle protein synthesis")],
        ]

        var newSynergies: [String: [(partner: String, mechanism: String)]] = [:]
        for (name, partners) in staticSynergies {
            newSynergies[name] = partners.map { (partner: $0.partner, mechanism: $0.reason) }
        }

        // Build DB supplement equivalents for onset data
        for supplement in staticSupplements {
            if let onset = SupplementKnowledgeBase.onsetTimelines[supplement.name] {
                let confidence: String = {
                    switch supplement.evidenceLevel {
                    case .strong: return "high"
                    case .moderate: return "moderate"
                    case .emerging: return "low"
                    }
                }()
                let dbSupp = DBSupplement(
                    id: supplement.id,
                    name: supplement.name,
                    category: supplement.category,
                    commonNames: nil,
                    primaryAction: supplement.notes,
                    defaultForm: supplement.formAndBioavailability,
                    defaultDose: supplement.commonDosageRange,
                    displayDose: nil,
                    doseRangeLow: nil,
                    doseRangeHigh: nil,
                    upperTolerableLimit: nil,
                    toxicityThreshold: nil,
                    timingOfDay: "morning",
                    withFood: "either",
                    timingRationale: supplement.dosageRationale,
                    timingRelativeNotes: nil,
                    synthesisConfidence: confidence,
                    conflictingEvidenceNotes: nil,
                    lastReviewed: nil,
                    reviewTrigger: nil,
                    createdAt: nil,
                    updatedAt: nil,
                    onsetRangeLow: nil,
                    onsetRangeHigh: nil,
                    onsetMinDays: onset.min,
                    onsetMaxDays: onset.max,
                    onsetDescription: onset.description
                )
                dbSupplementsByName[supplement.name] = dbSupp
                dbSupplementsById[supplement.id] = dbSupp
            }
        }

        // Build exclusion group index
        var newExclusionGroups: [String: [(supplementName: String, priority: Int)]] = [:]
        for entry in SupplementKnowledgeBase.exclusionGroups {
            newExclusionGroups[entry.groupKey, default: []].append((supplementName: entry.supplementName, priority: entry.priority))
        }
        for key in newExclusionGroups.keys {
            newExclusionGroups[key]?.sort { $0.priority < $1.priority }
        }

        // Build personalization signal indexes from static data
        let staticSignals = SupplementKnowledgeBase.personalizationSignals
        var newSignalsBySuppId: [UUID: [SupabasePersonalizationSignal]] = [:]
        var newSignalsByField: [String: [SupabasePersonalizationSignal]] = [:]
        for signal in staticSignals {
            newSignalsBySuppId[signal.supplementId, default: []].append(signal)
            newSignalsByField[signal.profileField, default: []].append(signal)
        }

        allSupplements = staticSupplements
        supplementsByName = newByName
        supplementsById = newById
        goalMap = newGoalMap
        categoryIndex = newCategoryIndex
        synergies = newSynergies
        exclusionGroupIndex = newExclusionGroups
        allPersonalizationSignals = staticSignals
        signalsBySupplementId = newSignalsBySuppId
        signalsByField = newSignalsByField
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

    /// All exclusion groups keyed by group name, sorted by priority
    var exclusionGroups: [String: [(supplementName: String, priority: Int)]] {
        exclusionGroupIndex
    }

    /// Returns the exclusion group peers for a given supplement name (excluding itself)
    func exclusionGroupPeers(for supplementName: String) -> [String] {
        for (_, members) in exclusionGroupIndex {
            if members.contains(where: { $0.supplementName == supplementName }) {
                return members.filter { $0.supplementName != supplementName }.map(\.supplementName)
            }
        }
        return []
    }

    // MARK: - Personalization Signal Lookups

    func personalizationSignals(for supplementId: UUID) -> [SupabasePersonalizationSignal] {
        signalsBySupplementId[supplementId] ?? []
    }

    func personalizationSignals(forField field: String) -> [SupabasePersonalizationSignal] {
        signalsByField[field] ?? []
    }

    // MARK: - Dose Range Lookup

    func doseRange(for supplementName: String) -> (low: Double, high: Double, limit: Double?)? {
        // Try DB supplement first
        if let db = dbSupplementsByName[supplementName] {
            if let lowStr = db.doseRangeLow, let highStr = db.doseRangeHigh {
                let low = Self.parseDoseString(lowStr)
                let high = Self.parseDoseString(highStr)
                if low > 0 || high > 0 {
                    let limit = db.upperTolerableLimit.flatMap { Self.parseDoseString($0) }
                    return (low: low, high: high, limit: limit != nil && limit! > 0 ? limit : nil)
                }
            }
        }
        // Fall back to static
        return SupplementKnowledgeBase.doseRanges[supplementName]
    }

    /// Parse dose strings like "400mg", "5000 IU", "2.5g" into a Double in mg
    static func parseDoseString(_ str: String) -> Double {
        let lowered = str.lowercased().trimmingCharacters(in: .whitespaces)
        let numericStr = lowered.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".")).inverted).joined()
        guard let value = Double(numericStr), value > 0 else { return 0 }

        if lowered.contains("g") && !lowered.contains("mg") && !lowered.contains("mcg") && !lowered.contains("ug") {
            return value * 1000 // grams → mg
        }
        if lowered.contains("mcg") || lowered.contains("ug") {
            return value / 1000 // mcg → mg
        }
        // mg, IU, or plain number: return as-is
        return value
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

    // MARK: - Key-Based Interaction Checking

    /// Collect all interaction keys from the user's selected medications
    func collectInteractionKeys(medicationIds: [UUID], medications: [DBMedication]) -> Set<String> {
        let selected = medications.filter { medicationIds.contains($0.id) }
        return Set(selected.flatMap { $0.interactionKeys })
    }

    /// Check a specific supplement against the user's interaction keys
    func checkInteractions(
        supplementId: UUID,
        userInteractionKeys: Set<String>,
        allInteractions: [DBDrugInteraction]
    ) -> InteractionDecision {
        let matches = allInteractions.filter {
            $0.supplementId == supplementId &&
            userInteractionKeys.contains($0.drugOrClass)
        }
        if matches.isEmpty { return .clear }
        if matches.contains(where: { $0.action == .avoid }) { return .remove(matches) }
        return .keepWithWarnings(matches)
    }
}

// MARK: - Interaction Decision

enum InteractionDecision {
    case remove([DBDrugInteraction])
    case keepWithWarnings([DBDrugInteraction])
    case clear
}
