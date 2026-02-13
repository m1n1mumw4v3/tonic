import Foundation

// MARK: - Supplement Definition

struct Supplement: Identifiable {
    let id: UUID
    let name: String
    let category: String
    let commonDosageRange: String
    let recommendedDosageMg: Double
    let recommendedTiming: SupplementTiming
    let benefits: [String]
    let contraindications: [String]
    let drugInteractions: [String]
    let notes: String
}

// MARK: - Goal–Supplement Entry

struct GoalSupplementEntry {
    let name: String
    let weight: Int  // 1 = complementary, 2 = moderate evidence, 3 = strong evidence / high impact
}

// MARK: - Knowledge Base

enum SupplementKnowledgeBase {

    // MARK: - Goal → Supplement Mapping (Evidence-Weighted)

    static let goalSupplementMap: [String: [GoalSupplementEntry]] = [
        "sleep": [
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 3),
            GoalSupplementEntry(name: "L-Theanine", weight: 2),
            GoalSupplementEntry(name: "Melatonin", weight: 2),
            GoalSupplementEntry(name: "Tart Cherry Extract", weight: 1),
        ],
        "energy": [
            GoalSupplementEntry(name: "Vitamin B Complex", weight: 3),
            GoalSupplementEntry(name: "CoQ10", weight: 2),
            GoalSupplementEntry(name: "Iron", weight: 2),
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 2),
            GoalSupplementEntry(name: "Rhodiola Rosea", weight: 2),
        ],
        "focus": [
            GoalSupplementEntry(name: "Omega-3 (EPA/DHA)", weight: 3),
            GoalSupplementEntry(name: "L-Theanine", weight: 2),
            GoalSupplementEntry(name: "Lion's Mane", weight: 2),
            GoalSupplementEntry(name: "Vitamin B Complex", weight: 1),
        ],
        "gut_health": [
            GoalSupplementEntry(name: "Probiotics", weight: 3),
            GoalSupplementEntry(name: "Berberine", weight: 2),
            GoalSupplementEntry(name: "Collagen Peptides", weight: 1),
            GoalSupplementEntry(name: "Zinc", weight: 1),
        ],
        "immunity": [
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 3),
            GoalSupplementEntry(name: "Vitamin C", weight: 2),
            GoalSupplementEntry(name: "Zinc", weight: 2),
            GoalSupplementEntry(name: "NAC", weight: 1),
        ],
        "stress_anxiety": [
            GoalSupplementEntry(name: "Ashwagandha KSM-66", weight: 3),
            GoalSupplementEntry(name: "L-Theanine", weight: 2),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Rhodiola Rosea", weight: 2),
        ],
        "fitness_recovery": [
            GoalSupplementEntry(name: "Creatine Monohydrate", weight: 3),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Omega-3 (EPA/DHA)", weight: 2),
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 2),
            GoalSupplementEntry(name: "Tart Cherry Extract", weight: 1),
        ],
        "skin_hair_nails": [
            GoalSupplementEntry(name: "Collagen Peptides", weight: 3),
            GoalSupplementEntry(name: "Biotin", weight: 2),
            GoalSupplementEntry(name: "Vitamin C", weight: 1),
            GoalSupplementEntry(name: "Zinc", weight: 1),
        ],
        "longevity": [
            GoalSupplementEntry(name: "Omega-3 (EPA/DHA)", weight: 3),
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 2),
            GoalSupplementEntry(name: "CoQ10", weight: 2),
            GoalSupplementEntry(name: "NAC", weight: 2),
        ],
        "heart_health": [
            GoalSupplementEntry(name: "CoQ10", weight: 3),
            GoalSupplementEntry(name: "Omega-3 (EPA/DHA)", weight: 3),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 2),
            GoalSupplementEntry(name: "Berberine", weight: 1),
        ],
    ]

    // MARK: - Known Drug Interactions

    static let knownDrugInteractions: [String: [String]] = [
        "warfarin": ["Omega-3 (EPA/DHA)"],
        "blood_thinner": ["Omega-3 (EPA/DHA)"],
        "coumadin": ["Omega-3 (EPA/DHA)"],
        "ssri": ["Omega-3 (EPA/DHA)"],
        "snri": ["Omega-3 (EPA/DHA)"],
        "sertraline": ["Omega-3 (EPA/DHA)"],
        "fluoxetine": ["Omega-3 (EPA/DHA)"],
        "escitalopram": ["Omega-3 (EPA/DHA)"],
        "blood_pressure": ["CoQ10", "Magnesium Glycinate"],
        "lisinopril": ["CoQ10", "Magnesium Glycinate"],
        "amlodipine": ["CoQ10", "Magnesium Glycinate"],
        "levothyroxine": ["Iron", "Magnesium Glycinate", "Zinc"],
        "synthroid": ["Iron", "Magnesium Glycinate", "Zinc"],
        "immunosuppressant": ["Vitamin C", "NAC"],
        "metformin": ["Berberine"],
        "diabetes": ["Berberine"],
        "statin": ["CoQ10"],
        "atorvastatin": ["CoQ10"],
        "rosuvastatin": ["CoQ10"]
    ]

    // MARK: - Seeded Supplements

    static let allSupplements: [Supplement] = [
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Magnesium Glycinate",
            category: "mineral",
            commonDosageRange: "200-400mg",
            recommendedDosageMg: 400,
            recommendedTiming: .evening,
            benefits: ["sleep", "stress_anxiety", "fitness_recovery", "heart_health"],
            contraindications: [],
            drugInteractions: ["blood_pressure", "levothyroxine"],
            notes: "Best absorbed form of magnesium. Take in the evening for sleep support."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "Vitamin D3 + K2",
            category: "vitamin",
            commonDosageRange: "2000-5000 IU",
            recommendedDosageMg: 2000,
            recommendedTiming: .morning,
            benefits: ["immunity", "energy", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: [],
            notes: "K2 ensures calcium goes to bones, not arteries. Take with fat-containing food."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
            name: "Omega-3 (EPA/DHA)",
            category: "fatty_acid",
            commonDosageRange: "1000-2000mg",
            recommendedDosageMg: 1000,
            recommendedTiming: .morning,
            benefits: ["focus", "longevity", "fitness_recovery", "heart_health"],
            contraindications: [],
            drugInteractions: ["warfarin", "blood_thinner", "ssri"],
            notes: "Look for high EPA+DHA content. Take with food to reduce fishy aftertaste."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!,
            name: "Ashwagandha KSM-66",
            category: "adaptogen",
            commonDosageRange: "300-600mg",
            recommendedDosageMg: 600,
            recommendedTiming: .evening,
            benefits: ["stress_anxiety", "energy", "sleep"],
            contraindications: ["thyroid_condition"],
            drugInteractions: [],
            notes: "KSM-66 is the most clinically studied extract. Effects build over 2-4 weeks."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000005")!,
            name: "L-Theanine",
            category: "amino_acid",
            commonDosageRange: "100-200mg",
            recommendedDosageMg: 200,
            recommendedTiming: .morning,
            benefits: ["focus", "sleep", "stress_anxiety"],
            contraindications: [],
            drugInteractions: [],
            notes: "Found naturally in green tea. Promotes calm focus without drowsiness."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000006")!,
            name: "Vitamin B Complex",
            category: "vitamin",
            commonDosageRange: "1x daily",
            recommendedDosageMg: 0,
            recommendedTiming: .morning,
            benefits: ["energy", "focus", "mood"],
            contraindications: [],
            drugInteractions: [],
            notes: "Essential for energy metabolism. Take in morning as it can be energizing."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000007")!,
            name: "Probiotics",
            category: "probiotic",
            commonDosageRange: "10-50B CFU",
            recommendedDosageMg: 0,
            recommendedTiming: .emptyStomach,
            benefits: ["gut_health", "immunity"],
            contraindications: [],
            drugInteractions: [],
            notes: "Take on empty stomach for best survival rate through digestive tract."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000008")!,
            name: "Zinc",
            category: "mineral",
            commonDosageRange: "15-30mg",
            recommendedDosageMg: 25,
            recommendedTiming: .evening,
            benefits: ["immunity", "skin_hair_nails", "gut_health"],
            contraindications: [],
            drugInteractions: ["levothyroxine"],
            notes: "Take with food to avoid nausea. Don't take with iron or calcium."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000009")!,
            name: "Vitamin C",
            category: "vitamin",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 1000,
            recommendedTiming: .morning,
            benefits: ["immunity", "skin_hair_nails"],
            contraindications: [],
            drugInteractions: ["immunosuppressant"],
            notes: "Enhances iron absorption. Split doses for better absorption."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000010")!,
            name: "CoQ10",
            category: "coenzyme",
            commonDosageRange: "100-200mg",
            recommendedDosageMg: 200,
            recommendedTiming: .morning,
            benefits: ["energy", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: ["blood_pressure", "statin"],
            notes: "Ubiquinol form is better absorbed. Recommended alongside statins."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000011")!,
            name: "Creatine Monohydrate",
            category: "amino_acid",
            commonDosageRange: "3-5g",
            recommendedDosageMg: 5000,
            recommendedTiming: .morning,
            benefits: ["fitness_recovery", "focus"],
            contraindications: [],
            drugInteractions: [],
            notes: "Most researched supplement. No loading phase needed at 5g/day."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000012")!,
            name: "Collagen Peptides",
            category: "protein",
            commonDosageRange: "10-15g",
            recommendedDosageMg: 10000,
            recommendedTiming: .morning,
            benefits: ["skin_hair_nails", "gut_health"],
            contraindications: [],
            drugInteractions: [],
            notes: "Types I and III for skin/hair. Can mix into coffee or smoothie."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000013")!,
            name: "Lion's Mane",
            category: "mushroom",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 1000,
            recommendedTiming: .morning,
            benefits: ["focus", "longevity"],
            contraindications: [],
            drugInteractions: [],
            notes: "Supports nerve growth factor. Effects build over several weeks."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000014")!,
            name: "Rhodiola Rosea",
            category: "adaptogen",
            commonDosageRange: "200-400mg",
            recommendedDosageMg: 400,
            recommendedTiming: .morning,
            benefits: ["energy", "stress_anxiety"],
            contraindications: [],
            drugInteractions: [],
            notes: "Best taken in the morning. Look for 3% rosavins / 1% salidroside."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000015")!,
            name: "Melatonin",
            category: "hormone",
            commonDosageRange: "0.5-3mg",
            recommendedDosageMg: 1,
            recommendedTiming: .bedtime,
            benefits: ["sleep"],
            contraindications: [],
            drugInteractions: [],
            notes: "Start low (0.5mg). Take 30 min before bed. Less is often more."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000016")!,
            name: "Biotin",
            category: "vitamin",
            commonDosageRange: "2500-5000mcg",
            recommendedDosageMg: 5,
            recommendedTiming: .morning,
            benefits: ["skin_hair_nails"],
            contraindications: [],
            drugInteractions: [],
            notes: "Can interfere with lab tests. Inform doctor before blood work."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000017")!,
            name: "Iron",
            category: "mineral",
            commonDosageRange: "18-27mg",
            recommendedDosageMg: 18,
            recommendedTiming: .emptyStomach,
            benefits: ["energy"],
            contraindications: ["hemochromatosis"],
            drugInteractions: ["levothyroxine"],
            notes: "Take with Vitamin C to enhance absorption. Can cause GI distress."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000018")!,
            name: "NAC",
            category: "amino_acid",
            commonDosageRange: "600-1200mg",
            recommendedDosageMg: 600,
            recommendedTiming: .morning,
            benefits: ["immunity", "longevity"],
            contraindications: [],
            drugInteractions: ["immunosuppressant"],
            notes: "Precursor to glutathione. Take on empty stomach for best absorption."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000019")!,
            name: "Berberine",
            category: "plant_extract",
            commonDosageRange: "500mg",
            recommendedDosageMg: 500,
            recommendedTiming: .withFood,
            benefits: ["gut_health", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: ["metformin", "diabetes"],
            notes: "Take with meals. May lower blood sugar — monitor if diabetic."
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000020")!,
            name: "Tart Cherry Extract",
            category: "fruit_extract",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 500,
            recommendedTiming: .evening,
            benefits: ["sleep", "fitness_recovery"],
            contraindications: [],
            drugInteractions: [],
            notes: "Natural source of melatonin and anti-inflammatory compounds."
        )
    ]

    // MARK: - Category Helpers

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

    static let allCategories: [String] = {
        var seen = Set<String>()
        var ordered: [String] = []
        for supplement in allSupplements {
            if seen.insert(supplement.category).inserted {
                ordered.append(supplement.category)
            }
        }
        return ordered
    }()

    static let supplementsByCategory: [(category: String, label: String, supplements: [Supplement])] = {
        allCategories.map { cat in
            (category: cat,
             label: categoryLabel(for: cat),
             supplements: allSupplements.filter { $0.category == cat })
        }
    }()

    // MARK: - Lookup Functions

    static func supplement(named name: String) -> Supplement? {
        allSupplements.first { $0.name == name }
    }

    static func supplements(for goalKey: String) -> [Supplement] {
        guard let entries = goalSupplementMap[goalKey] else { return [] }
        return entries.compactMap { supplement(named: $0.name) }
    }

    static func weight(for supplementName: String, goal goalKey: String) -> Int {
        goalSupplementMap[goalKey]?.first { $0.name == supplementName }?.weight ?? 0
    }

    static func hasInteraction(supplement: Supplement, medications: [String]) -> Bool {
        let medKeywords = medications.flatMap { med in
            med.lowercased().split(separator: " ").map(String.init)
        }
        return supplement.drugInteractions.contains { interaction in
            medKeywords.contains { keyword in
                interaction.lowercased().contains(keyword) || keyword.contains(interaction.lowercased())
            }
        }
    }

    static func interactionsForMedication(_ medication: String) -> [String] {
        let keywords = medication.lowercased().split(separator: " ").map(String.init)
        var interactions: [String] = []
        for (drugKey, supplementNames) in knownDrugInteractions {
            if keywords.contains(where: { $0.contains(drugKey) || drugKey.contains($0) }) {
                interactions.append(contentsOf: supplementNames)
            }
        }
        return Array(Set(interactions))
    }
}
