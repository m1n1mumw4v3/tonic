import Foundation

enum KBDataSource: String {
    case hardcoded
    case cached
    case remote
}

@Observable
class KnowledgeBaseProvider {

    // MARK: - Published State

    private(set) var allSupplements: [Supplement] = []
    private(set) var goalSupplementMap: [String: [GoalSupplementEntry]] = [:]
    private(set) var knownDrugInteractions: [String: [String]] = [:]
    private(set) var onsetTimelines: [String: (min: Int, max: Int, description: String)] = [:]
    private(set) var dailyTips: [String] = []
    private(set) var isLoaded: Bool = false
    private(set) var dataSource: KBDataSource = .hardcoded

    // MARK: - Init (synchronous, hardcoded data)

    init() {
        loadHardcodedData()
    }

    // MARK: - Hardcoded Fallback

    private func loadHardcodedData() {
        allSupplements = SupplementKnowledgeBase.allSupplements
        goalSupplementMap = SupplementKnowledgeBase.goalSupplementMap
        knownDrugInteractions = SupplementKnowledgeBase.knownDrugInteractions
        onsetTimelines = SupplementKnowledgeBase.onsetTimelines
        dailyTips = SupplementKnowledgeBase.dailyTips
        dataSource = .hardcoded
        isLoaded = true
    }

    // MARK: - Apply Snapshot (from cache or network)

    func apply(snapshot: KnowledgeBaseSnapshot, source: KBDataSource) {
        let mapped = KnowledgeBaseMapper.map(snapshot)
        allSupplements = mapped.supplements
        goalSupplementMap = mapped.goalSupplementMap
        knownDrugInteractions = mapped.knownDrugInteractions
        onsetTimelines = mapped.onsetTimelines
        dailyTips = mapped.dailyTips
        dataSource = source
        isLoaded = true
    }

    // MARK: - Async Load (cache → network → fallback)

    func loadKnowledgeBase() async {
        let cache = KnowledgeBaseCacheService()

        // Try fresh cache first
        if cache.isFresh(), let snapshot = cache.load() {
            apply(snapshot: snapshot, source: .cached)
            return
        }

        // Fetch from Supabase
        do {
            let fetcher = SupabaseKBFetcher()
            let snapshot = try await fetcher.fetchAll()
            try? cache.save(snapshot)
            apply(snapshot: snapshot, source: .remote)
        } catch {
            // Fall back to stale cache
            if let stale = cache.loadIgnoringStaleness() {
                apply(snapshot: stale, source: .cached)
            }
            // Otherwise stay on hardcoded (already loaded in init)
        }
    }

    // MARK: - Computed Properties

    var allCategories: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for supplement in allSupplements {
            if seen.insert(supplement.category).inserted {
                ordered.append(supplement.category)
            }
        }
        return ordered
    }

    var supplementsByCategory: [(category: String, label: String, supplements: [Supplement])] {
        allCategories.map { cat in
            (category: cat,
             label: categoryLabel(for: cat),
             supplements: allSupplements.filter { $0.category == cat })
        }
    }

    // MARK: - Lookup Functions

    func supplement(named name: String) -> Supplement? {
        allSupplements.first { $0.name == name }
    }

    func supplements(for goalKey: String) -> [Supplement] {
        guard let entries = goalSupplementMap[goalKey] else { return [] }
        return entries.compactMap { supplement(named: $0.name) }
    }

    func weight(for supplementName: String, goal goalKey: String) -> Int {
        goalSupplementMap[goalKey]?.first { $0.name == supplementName }?.weight ?? 0
    }

    func hasInteraction(supplement: Supplement, medications: [String]) -> Bool {
        let medKeywords = medications.flatMap { med in
            med.lowercased().split(separator: " ").map(String.init)
        }
        return supplement.drugInteractions.contains { interaction in
            medKeywords.contains { keyword in
                interaction.lowercased().contains(keyword) || keyword.contains(interaction.lowercased())
            }
        }
    }

    func interactionsForMedication(_ medication: String) -> [String] {
        let keywords = medication.lowercased().split(separator: " ").map(String.init)
        var interactions: [String] = []
        for (drugKey, supplementNames) in knownDrugInteractions {
            if keywords.contains(where: { $0.contains(drugKey) || drugKey.contains($0) }) {
                interactions.append(contentsOf: supplementNames)
            }
        }
        return Array(Set(interactions))
    }

    func categoryLabel(for key: String) -> String {
        Self.categoryLabelStatic(for: key)
    }

    static func categoryLabelStatic(for key: String) -> String {
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
}
