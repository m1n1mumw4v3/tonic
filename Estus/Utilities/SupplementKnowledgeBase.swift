import Foundation

// MARK: - Evidence Level

enum EvidenceLevel: String, Codable {
    case strong, moderate, emerging

    var displayText: String {
        switch self {
        case .strong: return "Extensive Research"
        case .moderate: return "Clinical Research"
        case .emerging: return "Emerging Research"
        }
    }

    var icon: String {
        switch self {
        case .strong: return "checkmark.seal.fill"
        case .moderate: return "chart.bar.doc.horizontal"
        case .emerging: return "sparkles"
        }
    }

    var description: String {
        switch self {
        case .strong:
            return "This supplement is backed by a large body of high-quality evidence, including multiple randomized controlled trials and systematic reviews. Benefits are well-established and consistently replicated across diverse populations."
        case .moderate:
            return "This supplement is supported by human clinical trials demonstrating clear benefits. The evidence is strong, though it may not yet span the breadth of populations, dosages, or long-term outcomes needed to be considered fully established. Confidence is high — the research just hasn't reached textbook status yet."
        case .emerging:
            return "This supplement shows promise based on preliminary studies, animal models, or early-phase human trials. The mechanism of action is plausible and initial findings are encouraging, but large-scale human trials are still needed to confirm efficacy."
        }
    }
}

// MARK: - Supplement Definition

struct Supplement: Identifiable {
    let id: UUID
    let name: String
    var commonNames: [String] = []
    let category: String
    let commonDosageRange: String
    let recommendedDosageMg: Double
    var displayDose: String? = nil
    let recommendedTiming: SupplementTiming
    let benefits: [String]
    let contraindications: [String]
    let drugInteractions: [String]
    let notes: String
    let dosageRationale: String
    let expectedTimeline: String
    let whatToLookFor: String
    let formAndBioavailability: String
    let evidenceLevel: EvidenceLevel
}

// MARK: - Goal–Supplement Entry

struct GoalSupplementEntry {
    let name: String
    let weight: Int  // 3 = meta-analyses or 3+ RCTs, 2 = limited RCTs or mixed results, 1 = mechanistic/preclinical
}

// MARK: - Exclusion Group Entry

struct ExclusionGroupEntry {
    let groupKey: String
    let supplementName: String
    let priority: Int  // lower wins tiebreak
}

// MARK: - Knowledge Base

enum SupplementKnowledgeBase {

    // MARK: - Exclusion Groups

    static let exclusionGroups: [ExclusionGroupEntry] = [
        ExclusionGroupEntry(groupKey: "protein", supplementName: "Whey Protein Isolate", priority: 1),
        ExclusionGroupEntry(groupKey: "protein", supplementName: "Plant Protein Blend", priority: 2),
    ]

    // MARK: - Goal → Supplement Mapping (Evidence-Weighted)

    static let goalSupplementMap: [String: [GoalSupplementEntry]] = [
        "sleep": [
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 3),
            GoalSupplementEntry(name: "L-Theanine", weight: 2),
            GoalSupplementEntry(name: "Melatonin", weight: 3),
            GoalSupplementEntry(name: "Tart Cherry Extract", weight: 1),
        ],
        "energy": [
            GoalSupplementEntry(name: "Vitamin B Complex", weight: 2),
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
        "immune_support": [
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
        "muscle_recovery": [
            GoalSupplementEntry(name: "Creatine Monohydrate", weight: 3),
            GoalSupplementEntry(name: "Whey Protein Isolate", weight: 3),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Plant Protein Blend", weight: 2),
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
            GoalSupplementEntry(name: "CoQ10", weight: 2),
            GoalSupplementEntry(name: "Omega-3 (EPA/DHA)", weight: 3),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 2),
            GoalSupplementEntry(name: "Berberine", weight: 1),
        ],
    ]

    // MARK: - Seeded Supplements

    static let allSupplements: [Supplement] = [
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Magnesium Glycinate",
            category: "mineral",
            commonDosageRange: "200-400mg",
            recommendedDosageMg: 400,
            displayDose: "400mg",
            recommendedTiming: .evening,
            benefits: ["sleep", "stress_anxiety", "muscle_recovery", "heart_health"],
            contraindications: [],
            drugInteractions: ["blood_pressure", "levothyroxine"],
            notes: "Best absorbed form of magnesium. Take in the evening for sleep support.",
            dosageRationale: "400mg — the upper end of the clinically studied range, chosen for combined sleep and recovery support.",
            expectedTimeline: "Calming effects can be felt within 30-60 minutes. Cumulative benefits for sleep quality and muscle recovery build over 1-2 weeks.",
            whatToLookFor: "Better sleep onset and fewer nighttime wake-ups{stress_note}. Reduced muscle tension after workouts{exercise_note}.",
            formAndBioavailability: "Glycinate chelate — one of the most bioavailable forms of magnesium with minimal GI side effects compared to oxide or citrate.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000002")!,
            name: "Vitamin D3 + K2",
            category: "vitamin",
            commonDosageRange: "2000-5000 IU",
            recommendedDosageMg: 2000,
            displayDose: "2,000 IU",
            recommendedTiming: .morning,
            benefits: ["immune_support", "energy", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: [],
            notes: "K2 ensures calcium goes to bones, not arteries. Take with fat-containing food.",
            dosageRationale: "2000 IU — a safe daily maintenance dose that brings most adults into the optimal 40-60 ng/mL range.",
            expectedTimeline: "Blood levels rise steadily over 4-8 weeks. Energy and mood benefits often noticed within 2-3 weeks.",
            whatToLookFor: "Improved energy levels and a general sense of vitality. Better resilience during cold and flu season.",
            formAndBioavailability: "D3 (cholecalciferol) with K2 (MK-7) — D3 is 87% more effective than D2 at raising serum levels. K2 directs calcium to bones, not arteries. Take with a fat-containing meal for optimal absorption.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000003")!,
            name: "Omega-3 (EPA/DHA)",
            category: "fatty_acid",
            commonDosageRange: "1000-2000mg",
            recommendedDosageMg: 1000,
            displayDose: "1,000mg",
            recommendedTiming: .morning,
            benefits: ["focus", "longevity", "muscle_recovery", "heart_health"],
            contraindications: [],
            drugInteractions: ["warfarin", "blood_thinner", "ssri"],
            notes: "Look for high EPA+DHA content. Take with food to reduce fishy aftertaste.",
            dosageRationale: "1000mg combined EPA/DHA — the minimum effective dose shown in cardiovascular and cognitive studies.",
            expectedTimeline: "Anti-inflammatory benefits begin within 1-2 weeks. Cognitive and cardiovascular improvements build over 8-12 weeks of consistent use.",
            whatToLookFor: "Improved mental clarity and focus{caffeine_note}. Reduced joint stiffness after exercise{exercise_note}.",
            formAndBioavailability: "Triglyceride-form fish oil — 70% better absorbed than ethyl ester form. Enteric coating reduces fishy aftertaste. Take with a meal containing fat.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000004")!,
            name: "Ashwagandha KSM-66",
            category: "adaptogen",
            commonDosageRange: "300-600mg",
            recommendedDosageMg: 600,
            displayDose: "600mg",
            recommendedTiming: .evening,
            benefits: ["stress_anxiety", "energy", "sleep"],
            contraindications: ["thyroid_condition"],
            drugInteractions: [],
            notes: "KSM-66 is the most clinically studied extract. Effects build over 2-4 weeks.",
            dosageRationale: "600mg — the full clinically studied dose of KSM-66, shown to reduce cortisol by up to 30%.",
            expectedTimeline: "Some calming effects within the first few days. Significant stress reduction and improved sleep quality develop over 2-4 weeks of daily use.",
            whatToLookFor: "A noticeable drop in baseline anxiety and reactivity to stressors{stress_note}. Improved sleep quality and morning alertness.",
            formAndBioavailability: "KSM-66 root extract — full-spectrum extraction preserving all active withanolides. Standardized to 5% withanolides for consistent potency.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000005")!,
            name: "L-Theanine",
            category: "amino_acid",
            commonDosageRange: "100-200mg",
            recommendedDosageMg: 200,
            displayDose: "200mg",
            recommendedTiming: .morning,
            benefits: ["focus", "sleep", "stress_anxiety"],
            contraindications: [],
            drugInteractions: [],
            notes: "Found naturally in green tea. Promotes calm focus without drowsiness.",
            dosageRationale: "200mg — the clinically studied dose for cognitive calm without sedation.",
            expectedTimeline: "Most people notice calming effects within 30-60 minutes. Cumulative benefits build over 1-2 weeks.",
            whatToLookFor: "A sense of calm focus without drowsiness{caffeine_note}. Reduced mental chatter and easier concentration{stress_note}.",
            formAndBioavailability: "Free-form amino acid — highly bioavailable, crosses the blood-brain barrier within 30 minutes. Promotes alpha brain wave activity associated with relaxed alertness.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000006")!,
            name: "Vitamin B Complex",
            category: "vitamin",
            commonDosageRange: "1x daily",
            recommendedDosageMg: 0,
            displayDose: "1 capsule",
            recommendedTiming: .morning,
            benefits: ["energy", "focus", "mood"],
            contraindications: [],
            drugInteractions: [],
            notes: "Essential for energy metabolism. Take in morning as it can be energizing.",
            dosageRationale: "Full-spectrum B complex at 100% DV — covers all 8 essential B vitamins to support energy metabolism and nervous system function.",
            expectedTimeline: "Energy improvements often felt within the first week. Full benefits for mood and cognitive function build over 2-4 weeks.",
            whatToLookFor: "More consistent energy levels throughout the day. Improved mental clarity and reduced afternoon fatigue{caffeine_note}.",
            formAndBioavailability: "Methylated forms (methylfolate, methylcobalamin) — readily usable by the body without conversion. Important for those with MTHFR variations. Water-soluble, so excess is safely excreted.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000007")!,
            name: "Probiotics",
            category: "probiotic",
            commonDosageRange: "10-50B CFU",
            recommendedDosageMg: 0,
            displayDose: "30B CFU",
            recommendedTiming: .emptyStomach,
            benefits: ["gut_health", "immune_support"],
            contraindications: [],
            drugInteractions: [],
            notes: "Take on empty stomach for best survival rate through digestive tract.",
            dosageRationale: "Multi-strain formula with 30B CFU — clinically effective range for gut microbiome support and immune modulation.",
            expectedTimeline: "Digestive improvements often noticed within 1-2 weeks. Full microbiome rebalancing takes 4-8 weeks of consistent use.",
            whatToLookFor: "Reduced bloating and more regular digestion. Improved immune resilience over time.",
            formAndBioavailability: "Delayed-release capsule — protects live cultures from stomach acid, delivering 10x more viable bacteria to the intestines than standard capsules.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000008")!,
            name: "Zinc",
            category: "mineral",
            commonDosageRange: "15-30mg",
            recommendedDosageMg: 25,
            displayDose: "25mg",
            recommendedTiming: .evening,
            benefits: ["immune_support", "skin_hair_nails", "gut_health"],
            contraindications: [],
            drugInteractions: ["levothyroxine"],
            notes: "Take with food to avoid nausea. Don't take with iron or calcium.",
            dosageRationale: "25mg — within the therapeutic range for immune support without risking copper depletion at higher doses.",
            expectedTimeline: "Immune benefits begin within 1-2 weeks. Skin and hair improvements develop gradually over 4-8 weeks.",
            whatToLookFor: "Fewer and shorter colds. Improved skin clarity and wound healing over time.",
            formAndBioavailability: "Zinc picolinate — one of the most bioavailable forms, with 20% better absorption than zinc gluconate. Take with food to minimize nausea.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000009")!,
            name: "Vitamin C",
            category: "vitamin",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 1000,
            displayDose: "1,000mg",
            recommendedTiming: .morning,
            benefits: ["immune_support", "skin_hair_nails"],
            contraindications: [],
            drugInteractions: ["immunosuppressant"],
            notes: "Enhances iron absorption. Split doses for better absorption.",
            dosageRationale: "1000mg — above the RDA to support collagen synthesis and antioxidant protection under daily stress.",
            expectedTimeline: "Immune support begins immediately. Skin brightness and collagen benefits build over 4-8 weeks.",
            whatToLookFor: "Improved recovery from minor illnesses. Brighter, more even skin tone over time{stress_note}.",
            formAndBioavailability: "Buffered ascorbic acid — gentler on the stomach than pure ascorbic acid. Water-soluble, so splitting into two doses improves utilization.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000010")!,
            name: "CoQ10",
            category: "coenzyme",
            commonDosageRange: "100-200mg",
            recommendedDosageMg: 200,
            displayDose: "200mg",
            recommendedTiming: .morning,
            benefits: ["energy", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: ["blood_pressure", "statin"],
            notes: "Ubiquinol form is better absorbed. Recommended alongside statins.",
            dosageRationale: "200mg — the dose used in major cardiovascular and energy studies, providing robust mitochondrial support.",
            expectedTimeline: "Energy improvements typically noticed within 2-4 weeks. Cardiovascular benefits build over 4-12 weeks of consistent use.",
            whatToLookFor: "More sustained energy throughout the day, especially during physical activity{exercise_note}. Improved exercise recovery.",
            formAndBioavailability: "Ubiquinol (reduced form) — 2-3x better absorbed than ubiquinone. Already in the active form your cells can use immediately. Fat-soluble; take with a meal.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000011")!,
            name: "Creatine Monohydrate",
            category: "amino_acid",
            commonDosageRange: "3-5g",
            recommendedDosageMg: 5000,
            displayDose: "5g",
            recommendedTiming: .morning,
            benefits: ["muscle_recovery", "focus"],
            contraindications: [],
            drugInteractions: [],
            notes: "Most researched supplement. No loading phase needed at 5g/day.",
            dosageRationale: "5g — the standard clinically validated daily dose. No loading phase necessary; saturation occurs within 3-4 weeks.",
            expectedTimeline: "Muscle saturation takes 3-4 weeks at 5g/day. Strength and cognitive benefits become noticeable once stores are full.",
            whatToLookFor: "Improved strength and power output during workouts{exercise_note}. Enhanced mental sharpness, especially under fatigue or sleep debt.",
            formAndBioavailability: "Creatine monohydrate — the most studied form with over 500 clinical trials. Nearly 100% bioavailable. Dissolves easily in water or any beverage.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000012")!,
            name: "Collagen Peptides",
            category: "protein",
            commonDosageRange: "10-15g",
            recommendedDosageMg: 10000,
            displayDose: "10g",
            recommendedTiming: .morning,
            benefits: ["skin_hair_nails", "gut_health"],
            contraindications: [],
            drugInteractions: [],
            notes: "Types I and III for skin/hair. Can mix into coffee or smoothie.",
            dosageRationale: "10g — the dose shown in clinical studies to improve skin elasticity and reduce wrinkle depth.",
            expectedTimeline: "Nail strength improves within 2-4 weeks. Skin hydration and elasticity benefits typically visible by 6-8 weeks.",
            whatToLookFor: "Stronger nails and improved skin hydration. Hair thickness may improve with consistent use over 3+ months.",
            formAndBioavailability: "Hydrolyzed peptides (Types I & III) — enzymatically broken down for 90%+ absorption. Dissolves in hot or cold liquids. Pairs optimally with Vitamin C for collagen synthesis.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000013")!,
            name: "Lion's Mane",
            category: "mushroom",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 1000,
            displayDose: "1,000mg",
            recommendedTiming: .morning,
            benefits: ["focus", "longevity"],
            contraindications: [],
            drugInteractions: [],
            notes: "Supports nerve growth factor. Effects build over several weeks.",
            dosageRationale: "1000mg — the dose used in cognitive performance studies, providing meaningful nerve growth factor stimulation.",
            expectedTimeline: "Subtle cognitive improvements may begin within 2 weeks. Significant benefits for focus and memory build over 4-8 weeks.",
            whatToLookFor: "Improved recall and mental clarity{caffeine_note}. Easier sustained concentration during complex tasks.",
            formAndBioavailability: "Fruiting body extract — standardized for hericenones and erinacines, the bioactive compounds that stimulate nerve growth factor. Dual-extracted (water + alcohol) for full-spectrum benefits.",
            evidenceLevel: .emerging
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000014")!,
            name: "Rhodiola Rosea",
            category: "adaptogen",
            commonDosageRange: "200-400mg",
            recommendedDosageMg: 400,
            displayDose: "400mg",
            recommendedTiming: .morning,
            benefits: ["energy", "stress_anxiety"],
            contraindications: [],
            drugInteractions: [],
            notes: "Best taken in the morning. Look for 3% rosavins / 1% salidroside.",
            dosageRationale: "400mg — the upper clinical dose, standardized to 3% rosavins and 1% salidroside for maximum adaptogenic benefit.",
            expectedTimeline: "Anti-fatigue effects often felt within the first few days. Full adaptogenic benefits develop over 2-4 weeks.",
            whatToLookFor: "Reduced mental fatigue and improved endurance{exercise_note}. Better stress resilience without jitteriness{stress_note}.",
            formAndBioavailability: "Standardized root extract (3% rosavins, 1% salidroside) — the exact ratio used in clinical trials. Take on an empty stomach in the morning for best results.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000015")!,
            name: "Melatonin",
            category: "hormone",
            commonDosageRange: "0.5-3mg",
            recommendedDosageMg: 1,
            displayDose: "1mg",
            recommendedTiming: .bedtime,
            benefits: ["sleep"],
            contraindications: [],
            drugInteractions: [],
            notes: "Start low (0.5mg). Take 30 min before bed. Less is often more.",
            dosageRationale: "1mg — a physiologically appropriate dose that mimics natural production. Higher doses often cause grogginess without improving sleep.",
            expectedTimeline: "Sleep onset improvements typically felt the first night. Best used short-term or cyclically rather than continuously.",
            whatToLookFor: "Faster time to fall asleep and more consistent sleep onset timing. You should not feel groggy in the morning — if you do, try reducing to 0.5mg.",
            formAndBioavailability: "Sublingual tablet — absorbs directly through oral mucosa, bypassing first-pass liver metabolism for faster onset (15-20 minutes vs. 45 minutes for swallowed tablets).",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000016")!,
            name: "Biotin",
            category: "vitamin",
            commonDosageRange: "2500-5000mcg",
            recommendedDosageMg: 5,
            displayDose: "5,000mcg",
            recommendedTiming: .morning,
            benefits: ["skin_hair_nails"],
            contraindications: [],
            drugInteractions: [],
            notes: "Can interfere with lab tests. Inform doctor before blood work.",
            dosageRationale: "5000mcg — the dose used in hair and nail strengthening studies. Above dietary needs but safe as a water-soluble vitamin.",
            expectedTimeline: "Nail improvements typically visible within 3-4 weeks. Hair thickness and growth benefits require 3-6 months of consistent use.",
            whatToLookFor: "Stronger, less brittle nails first. Hair shedding may decrease over time. Important: inform your doctor before blood work, as biotin can interfere with lab results.",
            formAndBioavailability: "D-biotin — the naturally occurring, biologically active form. Water-soluble with high oral bioavailability. Excess is safely excreted.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000017")!,
            name: "Iron",
            category: "mineral",
            commonDosageRange: "18-27mg",
            recommendedDosageMg: 18,
            displayDose: "18mg",
            recommendedTiming: .emptyStomach,
            benefits: ["energy"],
            contraindications: ["hemochromatosis"],
            drugInteractions: ["levothyroxine"],
            notes: "Take with Vitamin C to enhance absorption. Can cause GI distress.",
            dosageRationale: "18mg — the RDA for adult women. Dose is adjusted based on sex (8mg for men, 27mg for women of reproductive age).",
            expectedTimeline: "If iron-deficient, energy improvements can be felt within 2-4 weeks. Ferritin levels take 3-6 months to fully normalize.",
            whatToLookFor: "Improved energy and reduced fatigue, especially during afternoon slumps{exercise_note}. Less shortness of breath during physical activity.",
            formAndBioavailability: "Iron bisglycinate — 4x better absorbed than ferrous sulfate with significantly fewer GI side effects. Take on an empty stomach with Vitamin C for maximum absorption.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000018")!,
            name: "NAC",
            category: "amino_acid",
            commonDosageRange: "600-1200mg",
            recommendedDosageMg: 600,
            displayDose: "600mg",
            recommendedTiming: .morning,
            benefits: ["immune_support", "longevity"],
            contraindications: [],
            drugInteractions: ["immunosuppressant"],
            notes: "Precursor to glutathione. Take on empty stomach for best absorption.",
            dosageRationale: "600mg — the standard clinical dose for glutathione support and antioxidant defense.",
            expectedTimeline: "Glutathione levels begin rising within 1-2 weeks. Full antioxidant and respiratory benefits develop over 4-8 weeks.",
            whatToLookFor: "Improved respiratory health and immune resilience. A general sense of reduced oxidative burden{exercise_note}.",
            formAndBioavailability: "N-Acetyl Cysteine — acetylated form of cysteine with improved oral bioavailability. Directly feeds glutathione synthesis. Best absorbed on an empty stomach.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000019")!,
            name: "Berberine",
            category: "plant_extract",
            commonDosageRange: "500mg",
            recommendedDosageMg: 500,
            displayDose: "500mg",
            recommendedTiming: .withFood,
            benefits: ["gut_health", "longevity", "heart_health"],
            contraindications: [],
            drugInteractions: ["metformin", "diabetes"],
            notes: "Take with meals. May lower blood sugar — monitor if diabetic.",
            dosageRationale: "500mg — the dose used in metabolic and gut health studies, taken with meals to improve tolerability.",
            expectedTimeline: "Digestive improvements often noticed within 1-2 weeks. Metabolic and cardiovascular benefits build over 8-12 weeks.",
            whatToLookFor: "Improved digestion and more stable energy after meals. Better fasting glucose readings if you track them.",
            formAndBioavailability: "Berberine HCl — the most common and well-studied salt form. Bioavailability is naturally low but improves significantly when taken with a meal. Some formulas add absorption enhancers.",
            evidenceLevel: .moderate
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000020")!,
            name: "Tart Cherry Extract",
            category: "fruit_extract",
            commonDosageRange: "500-1000mg",
            recommendedDosageMg: 500,
            displayDose: "500mg",
            recommendedTiming: .evening,
            benefits: ["sleep", "muscle_recovery"],
            contraindications: [],
            drugInteractions: [],
            notes: "Natural source of melatonin and anti-inflammatory compounds.",
            dosageRationale: "500mg — equivalent to approximately 100 tart cherries, providing natural melatonin and anthocyanins.",
            expectedTimeline: "Sleep onset improvements often felt within the first few days. Anti-inflammatory recovery benefits build over 1-2 weeks of consistent use.",
            whatToLookFor: "Easier sleep onset and improved sleep quality. Reduced muscle soreness after exercise{exercise_note}.",
            formAndBioavailability: "Concentrated Montmorency cherry extract — standardized for anthocyanins and natural melatonin precursors. Capsule form provides consistent dosing compared to juice.",
            evidenceLevel: .emerging
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000021")!,
            name: "Whey Protein Isolate",
            category: "protein",
            commonDosageRange: "20-30g",
            recommendedDosageMg: 25000,
            displayDose: "25g",
            recommendedTiming: .morning,
            benefits: ["muscle_recovery"],
            contraindications: [],
            drugInteractions: [],
            notes: "Fast-absorbing complete protein. Ideal post-workout or morning shake.",
            dosageRationale: "25g — provides the leucine threshold (~2.5g) needed to maximally stimulate muscle protein synthesis per serving.",
            expectedTimeline: "Amino acids peak in blood within 60-90 minutes. Strength and recovery gains build over 4-8 weeks of consistent training and intake.",
            whatToLookFor: "Faster post-workout recovery and reduced soreness{exercise_note}. Better maintenance of muscle mass during caloric deficits.",
            formAndBioavailability: "Whey protein isolate — filtered to 90%+ protein with minimal lactose and fat. Fast-digesting with the highest leucine content of any protein source.",
            evidenceLevel: .strong
        ),
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000022")!,
            name: "Plant Protein Blend",
            category: "protein",
            commonDosageRange: "20-30g",
            recommendedDosageMg: 25000,
            displayDose: "25g",
            recommendedTiming: .morning,
            benefits: ["muscle_recovery"],
            contraindications: [],
            drugInteractions: [],
            notes: "Pea + rice blend for a complete amino acid profile. Vegan-friendly.",
            dosageRationale: "25g — a blended serving combining pea and rice protein to achieve a complete amino acid profile comparable to whey.",
            expectedTimeline: "Amino acids absorb within 1-2 hours. Strength and body composition improvements build over 4-8 weeks with consistent training.",
            whatToLookFor: "Improved post-workout recovery and sustained energy{exercise_note}. A good option if dairy-based proteins cause digestive issues.",
            formAndBioavailability: "Pea + brown rice blend — complementary amino acid profiles create a complete protein. Slightly slower digestion than whey but comparable muscle protein synthesis at equal doses.",
            evidenceLevel: .moderate
        )
    ]

    // MARK: - Drug Interactions (populated from Supabase; empty fallback for hardcoded)

    static let knownDrugInteractions: [String: [String]] = [:]

    // MARK: - Onset Timelines

    static let onsetTimelines: [String: (min: Int, max: Int, description: String)] = [
        "Magnesium Glycinate": (1, 14, "Calming effects within hours; sleep quality improvements over 1-2 weeks"),
        "Vitamin D3 + K2": (14, 56, "Blood levels rise over 4-8 weeks; energy benefits in 2-3 weeks"),
        "Omega-3 (EPA/DHA)": (7, 84, "Anti-inflammatory benefits in 1-2 weeks; cognitive gains over 8-12 weeks"),
        "Ashwagandha KSM-66": (3, 28, "Calming effects within days; full stress reduction over 2-4 weeks"),
        "L-Theanine": (1, 14, "Calming effects within 30-60 minutes; cumulative benefits over 1-2 weeks"),
        "Vitamin B Complex": (3, 28, "Energy improvements within the first week; full benefits over 2-4 weeks"),
        "Probiotics": (7, 56, "Digestive improvements in 1-2 weeks; full microbiome rebalancing in 4-8 weeks"),
        "Zinc": (7, 56, "Immune benefits in 1-2 weeks; skin improvements over 4-8 weeks"),
        "Vitamin C": (1, 56, "Immune support begins immediately; skin benefits build over 4-8 weeks"),
        "CoQ10": (14, 84, "Energy improvements in 2-4 weeks; cardiovascular benefits over 4-12 weeks"),
        "Creatine Monohydrate": (21, 28, "Muscle saturation takes 3-4 weeks; strength gains follow"),
        "Collagen Peptides": (14, 56, "Nail strength in 2-4 weeks; skin elasticity by 6-8 weeks"),
        "Lion's Mane": (14, 56, "Subtle cognitive improvements in 2 weeks; significant focus gains over 4-8 weeks"),
        "Rhodiola Rosea": (3, 28, "Anti-fatigue effects within days; full adaptogenic benefits over 2-4 weeks"),
        "Melatonin": (1, 1, "Sleep onset improvements typically felt the first night"),
        "Biotin": (21, 120, "Nail improvements in 3-4 weeks; hair benefits require 3-6 months"),
        "Iron": (14, 180, "Energy improvements in 2-4 weeks if deficient; ferritin normalizes over 3-6 months"),
        "NAC": (7, 56, "Glutathione levels rise in 1-2 weeks; full antioxidant benefits over 4-8 weeks"),
        "Berberine": (7, 84, "Digestive improvements in 1-2 weeks; metabolic benefits over 8-12 weeks"),
        "Tart Cherry Extract": (3, 14, "Sleep onset improvements within days; recovery benefits over 1-2 weeks"),
        "Whey Protein Isolate": (1, 56, "Amino acids peak within 60-90 minutes; strength and recovery gains over 4-8 weeks"),
        "Plant Protein Blend": (1, 56, "Amino acids absorb within 1-2 hours; body composition improvements over 4-8 weeks"),
    ]

    // MARK: - Supplement Phase Durations

    static let supplementPhases: [String: (loading: Int, adaptation: Int, onset: Int)] = [
        "Magnesium Glycinate":  (3, 8, 14),
        "Vitamin D3 + K2":      (7, 14, 35),
        "Omega-3 (EPA/DHA)":    (5, 16, 63),
        "Ashwagandha KSM-66":   (3, 8, 17),
        "L-Theanine":           (1, 4, 9),
        "Vitamin B Complex":    (2, 7, 19),
        "Probiotics":           (5, 14, 37),
        "Zinc":                 (5, 14, 37),
        "Vitamin C":            (1, 7, 48),
        "CoQ10":                (7, 21, 56),
        "Creatine Monohydrate": (7, 14, 7),
        "Collagen Peptides":    (7, 14, 35),
        "Lion's Mane":          (7, 14, 35),
        "Rhodiola Rosea":       (3, 8, 17),
        "Melatonin":            (0, 0, 1),
        "Biotin":               (7, 21, 92),
        "Iron":                 (7, 21, 152),
        "NAC":                  (5, 14, 37),
        "Berberine":            (5, 16, 63),
        "Tart Cherry Extract":  (2, 4, 8),
        "Whey Protein Isolate": (1, 7, 48),
        "Plant Protein Blend":  (1, 7, 48),
    ]

    static func phaseDurations(for supplementName: String) -> SupplementPhaseDurations? {
        guard let phases = supplementPhases[supplementName] else { return nil }
        return SupplementPhaseDurations(
            loadingDays: phases.loading,
            adaptationDays: phases.adaptation,
            onsetDays: phases.onset
        )
    }

    // MARK: - Goal → Dimension Mapping

    static let goalToDimension: [String: WellnessDimension] = [
        "sleep": .sleep,
        "energy": .energy,
        "focus": .clarity,
        "gut_health": .gut,
        "stress_anxiety": .mood,
        "immune_support": .energy,
        "muscle_recovery": .energy,
        "skin_hair_nails": .gut,
        "heart_health": .energy,
        "longevity": .clarity,
    ]

    // MARK: - Phase Content

    struct SupplementPhaseContent {
        let biologicalDescription: String
        let watchFor: String
        let nextMilestone: String
    }

    static let phaseContent: [String: [SupplementPhase: SupplementPhaseContent]] = [
        "Magnesium Glycinate": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Your body is absorbing magnesium glycinate and beginning to restore intracellular magnesium stores. The glycinate chelate ensures high bioavailability with minimal GI disruption.",
                watchFor: "A subtle calming sensation in the evenings. Some people notice relaxed muscles within the first few doses.",
                nextMilestone: "By day 3-4, you may notice easier sleep onset as GABA receptor activity begins to normalize."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Magnesium is integrating into enzymatic pathways that regulate GABA, the neurotransmitter responsible for calming your nervous system. Muscle and nerve function are recalibrating.",
                watchFor: "Improved sleep quality and reduced nighttime waking. Less muscle tension, especially after physical activity.",
                nextMilestone: "By week 2, sleep architecture typically begins to shift toward deeper, more restorative patterns."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Your magnesium stores are reaching optimal levels. The full cascade of benefits — sleep, stress resilience, muscle recovery — is establishing itself as enzymatic function normalizes.",
                watchFor: "Consistent sleep quality improvements and reduced stress reactivity. Recovery from workouts should feel noticeably faster.",
                nextMilestone: "Steady state — your body maintains optimal levels with continued daily supplementation."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Magnesium levels are fully replenished. Your body is maintaining optimal enzymatic function for sleep, muscle recovery, and stress resilience.",
                watchFor: "Sustained benefits across sleep, recovery, and calm. If you miss doses for several days, effects may start to diminish.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Omega-3 (EPA/DHA)": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "EPA and DHA are being absorbed and beginning to incorporate into cell membranes. This process reshapes how your cells communicate and manage inflammation.",
                watchFor: "No noticeable effects yet — omega-3s work at the cellular level and need time to integrate into tissues.",
                nextMilestone: "Within 1-2 weeks, early anti-inflammatory signaling shifts should begin."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Cell membrane composition is actively shifting as omega-3s replace pro-inflammatory omega-6 fatty acids. This rebalancing affects every tissue in your body, especially the brain and cardiovascular system.",
                watchFor: "Reduced joint stiffness and subtle improvements in mental clarity. Skin may begin to feel more hydrated.",
                nextMilestone: "By week 6-8, cognitive benefits become measurable as brain cell membranes reach optimal DHA saturation."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Your cell membranes now have significantly improved omega-3 ratios. Neural signaling is faster, inflammation markers are lower, and cardiovascular function is optimizing.",
                watchFor: "Clearer thinking, improved focus, and reduced brain fog. Better mood stability and cardiovascular markers if tracked.",
                nextMilestone: "Full steady state — continued supplementation maintains your improved omega-3 index."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Your omega-3 index has reached optimal levels. Cell membranes throughout your body maintain their improved anti-inflammatory profile.",
                watchFor: "Sustained cognitive clarity, reduced inflammation, and cardiovascular benefits. These are maintained with consistent intake.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Ashwagandha KSM-66": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Withanolides from KSM-66 are beginning to modulate your HPA axis — the system governing cortisol and your stress response. This is the initial calibration period.",
                watchFor: "A mild calming effect may be noticeable within the first few days, especially in the evening.",
                nextMilestone: "By day 5-7, cortisol modulation begins to show measurable effects on baseline stress."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Your HPA axis is actively recalibrating. Cortisol rhythms are normalizing — lower spikes during stress, better recovery between stressors. Thyroid function may also be gently supported.",
                watchFor: "Reduced anxiety and improved stress resilience. Sleep quality should improve, especially if stress was disrupting it.",
                nextMilestone: "By week 3-4, cortisol can be reduced by up to 30% based on clinical studies."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Full adaptogenic benefits are establishing. Your stress response is significantly more regulated, with improved cortisol patterns throughout the day.",
                watchFor: "Noticeably better stress management, improved morning energy, and a calmer baseline mood.",
                nextMilestone: "Steady state — your adapted stress response maintains with continued use."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Your HPA axis has fully adapted. Stress resilience, sleep quality, and energy balance are optimized through consistent withanolide activity.",
                watchFor: "Maintained calm and resilience. Effects may diminish if you stop — consider cycling 8 weeks on, 2 weeks off.",
                nextMilestone: "You've reached steady state. Consider periodic cycling for sustained efficacy."
            ),
        ],
        "L-Theanine": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "L-Theanine crosses the blood-brain barrier rapidly, boosting alpha brain wave activity within 30-60 minutes. GABA and serotonin production begin to increase.",
                watchFor: "A calm, focused feeling without drowsiness. Reduced mental chatter, especially if paired with caffeine.",
                nextMilestone: "Cumulative effects begin building within the first week as neurotransmitter balance stabilizes."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Daily supplementation is establishing consistent alpha wave patterns and neurotransmitter support. Your brain is adapting to sustained, calm focus.",
                watchFor: "More consistent focus and concentration. Reduced stress reactivity throughout the day, not just at dosing time.",
                nextMilestone: "By day 10-14, the full cumulative cognitive benefits should be apparent."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Full cognitive benefits are active. Alpha brain wave activity is consistently elevated, supporting sustained focus and mental clarity.",
                watchFor: "Reliable calm focus, improved sleep quality, and better stress management throughout the day.",
                nextMilestone: "Steady state — effects are maximized at this point."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "L-Theanine benefits are fully established. Your brain maintains elevated alpha wave activity and balanced neurotransmitter levels.",
                watchFor: "Consistent focus and calm. L-Theanine has no tolerance buildup, so benefits maintain indefinitely.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Vitamin D3 + K2": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Vitamin D3 is being converted to its active form (calcitriol) in the liver and kidneys. K2 is directing calcium metabolism toward bones and away from arteries.",
                watchFor: "No immediate effects — D3 accumulates gradually. Absorption improves when taken with dietary fat.",
                nextMilestone: "Blood levels begin rising measurably within the first 1-2 weeks."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Serum 25(OH)D levels are steadily climbing toward the optimal 40-60 ng/mL range. Immune cell receptors are becoming more active, and calcium metabolism is normalizing.",
                watchFor: "Gradual improvements in energy and mood. Immune resilience may begin to improve.",
                nextMilestone: "By week 4-6, most people reach noticeable improvements in energy and immune function."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Your vitamin D levels are approaching optimal range. Immune modulation, bone metabolism, and energy systems are all benefiting from adequate D3/K2 status.",
                watchFor: "Consistent energy, improved mood, and better immune resilience. If you get blood work, aim for 40-60 ng/mL.",
                nextMilestone: "Full steady state — levels stabilize with consistent daily supplementation."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Vitamin D levels have stabilized in the optimal range. K2 continues to support proper calcium distribution.",
                watchFor: "Maintained energy, immune function, and bone health. Seasonal variation may affect needs — consider higher doses in winter.",
                nextMilestone: "You've reached steady state. Consider seasonal dose adjustments."
            ),
        ],
        "Creatine Monohydrate": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Creatine is being absorbed and beginning to saturate your muscle cells and brain tissue. At 5g/day without a loading phase, this is a gradual process.",
                watchFor: "Slight increase in water retention as muscles begin pulling in creatine and water. This is normal and expected.",
                nextMilestone: "By week 2, muscle creatine stores are roughly 50% saturated."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Muscle creatine phosphate stores are building toward full saturation. ATP regeneration capacity during high-intensity efforts is increasing.",
                watchFor: "Improved performance in strength and power exercises. You may notice an extra rep or two on heavy sets.",
                nextMilestone: "Full muscle saturation occurs around week 3-4 at 5g/day."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Muscle creatine stores are nearing full saturation. Both physical and cognitive performance benefits are becoming reliable and consistent.",
                watchFor: "Consistent strength gains, better recovery between sets, and improved mental sharpness under fatigue.",
                nextMilestone: "Steady state — full saturation maintained with daily 5g dose."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Creatine stores are fully saturated. Daily 5g maintains optimal levels for strength, power, and cognitive function.",
                watchFor: "Sustained performance benefits. No need to cycle — creatine maintains efficacy with continuous use.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Probiotics": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Live bacterial cultures are establishing in your gut, competing for attachment sites on the intestinal lining. The microbiome is beginning to shift.",
                watchFor: "Mild gas or bloating in the first few days is normal as your gut flora adjusts. This typically resolves quickly.",
                nextMilestone: "By day 7-10, initial colonies should be establishing and digestive comfort improving."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Beneficial bacteria are multiplying and reshaping your gut microbiome. Short-chain fatty acid production is increasing, supporting gut barrier integrity.",
                watchFor: "Improved digestion, more regular bowel movements, and reduced bloating. Immune function begins to benefit.",
                nextMilestone: "By week 4-6, significant microbiome rebalancing occurs with measurable changes in gut diversity."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Your microbiome has undergone significant positive shifts. Gut barrier function is improved, immune signaling is better regulated, and nutrient absorption is optimized.",
                watchFor: "Consistent digestive comfort, improved immune resilience, and potentially better mood via the gut-brain axis.",
                nextMilestone: "Full steady state — your rebalanced microbiome maintains with continued supplementation."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Your gut microbiome is well-supported with diverse beneficial bacteria. Ongoing supplementation maintains the improved microbial balance.",
                watchFor: "Sustained digestive health and immune support. Probiotic benefits depend on continued use — colonies diminish if you stop.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Lion's Mane": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Hericenones and erinacines from Lion's Mane are stimulating nerve growth factor (NGF) production in the brain. Neural pathways are beginning to respond.",
                watchFor: "Effects are subtle at first — NGF-driven neuroplasticity takes time to manifest as noticeable cognitive changes.",
                nextMilestone: "By week 2, early improvements in mental clarity and recall may become apparent."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "NGF production is sustained and neuroplasticity is actively increasing. New neural connections are forming and existing pathways are being strengthened.",
                watchFor: "Improved recall, clearer thinking, and better sustained concentration during complex tasks.",
                nextMilestone: "By week 6-8, significant cognitive improvements are typically established."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Sustained NGF stimulation has produced meaningful neuroplastic changes. Cognitive function, memory, and focus are operating at an elevated baseline.",
                watchFor: "Reliable improvements in focus, memory, and mental clarity. Some users report improved creativity.",
                nextMilestone: "Steady state — continued supplementation maintains neuroplastic benefits."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Your brain is maintaining elevated NGF levels and the neuroplastic benefits that come with them. Continued supplementation sustains these gains.",
                watchFor: "Sustained cognitive enhancement. Benefits may slowly diminish if supplementation stops, as NGF levels normalize.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "CoQ10": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Ubiquinol is being absorbed and beginning to accumulate in your mitochondria — the energy factories in every cell. Heart and muscle cells, which have the highest mitochondrial density, benefit first.",
                watchFor: "No immediate effects. CoQ10 accumulates gradually in tissue stores over the first few weeks.",
                nextMilestone: "By week 2-3, mitochondrial CoQ10 levels are measurably increasing."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "Mitochondrial energy production is increasing as CoQ10 levels rise. The electron transport chain operates more efficiently, generating more ATP per cycle.",
                watchFor: "Improved energy levels, especially during physical activity. Less post-exercise fatigue and faster recovery.",
                nextMilestone: "By week 6-8, full mitochondrial benefits are establishing."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "Tissue CoQ10 levels are approaching optimal saturation. Cardiovascular function, energy metabolism, and antioxidant protection are all benefiting.",
                watchFor: "Sustained energy throughout the day. Improved exercise capacity. Better cardiovascular markers if tracked.",
                nextMilestone: "Full steady state — tissue levels are optimized with continued daily supplementation."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "CoQ10 levels are fully optimized across all tissues. Mitochondrial function, cardiovascular health, and antioxidant defense are at their best.",
                watchFor: "Maintained energy and cardiovascular support. Especially important if you're over 40 or taking statins.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
        "Vitamin B Complex": [
            .loading: SupplementPhaseContent(
                biologicalDescription: "Methylated B vitamins are being rapidly absorbed and entering metabolic pathways. As water-soluble vitamins, they begin working quickly but need daily replenishment.",
                watchFor: "Subtle energy boost, especially in the morning. Bright yellow urine is normal — it's excess riboflavin (B2) being excreted.",
                nextMilestone: "By day 4-5, energy metabolism should be noticeably more consistent."
            ),
            .adaptation: SupplementPhaseContent(
                biologicalDescription: "All eight B vitamins are supporting energy metabolism, nervous system function, and red blood cell production. Homocysteine levels may begin to normalize.",
                watchFor: "More consistent energy throughout the day. Improved mental clarity and reduced afternoon fatigue.",
                nextMilestone: "By week 3-4, full neurological and metabolic benefits are established."
            ),
            .onset: SupplementPhaseContent(
                biologicalDescription: "B vitamin status is fully optimized. Energy metabolism, neurotransmitter synthesis, and methylation pathways are all running at peak efficiency.",
                watchFor: "Reliable daily energy, improved mood stability, and sharper cognitive function.",
                nextMilestone: "Steady state — continued daily supplementation maintains optimal B vitamin levels."
            ),
            .steadyState: SupplementPhaseContent(
                biologicalDescription: "Your B vitamin levels are fully maintained. As water-soluble vitamins, daily intake is essential — your body doesn't store significant reserves.",
                watchFor: "Sustained energy and cognitive benefits. Missing several days may lead to noticeable dips in energy.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            ),
        ],
    ]

    static func phaseContentFor(supplement: String, phase: SupplementPhase) -> SupplementPhaseContent {
        if let specific = phaseContent[supplement]?[phase] {
            return specific
        }
        return genericPhaseContent(for: phase, supplementName: supplement)
    }

    private static func genericPhaseContent(for phase: SupplementPhase, supplementName: String) -> SupplementPhaseContent {
        switch phase {
        case .loading:
            return SupplementPhaseContent(
                biologicalDescription: "Your body is absorbing \(supplementName) and beginning to build tissue levels. This initial phase establishes the foundation for benefits to come.",
                watchFor: "Effects may be subtle or not yet noticeable. Consistent daily intake is key during this phase.",
                nextMilestone: "As tissue levels build, your body will begin adapting to the supplement's active compounds."
            )
        case .adaptation:
            return SupplementPhaseContent(
                biologicalDescription: "\(supplementName) is actively integrating into your biological systems. Key pathways are adapting and beginning to show functional improvements.",
                watchFor: "Early signs of benefit may start to appear. Pay attention to the wellness dimensions this supplement targets.",
                nextMilestone: "Full onset of benefits is approaching as your body reaches optimal levels."
            )
        case .onset:
            return SupplementPhaseContent(
                biologicalDescription: "The primary benefits of \(supplementName) are now actively establishing. Your body has built sufficient levels for consistent, noticeable effects.",
                watchFor: "Clear improvements in the targeted wellness areas. Your check-in scores should begin reflecting these changes.",
                nextMilestone: "Steady state is approaching — benefits will be maintained with continued daily supplementation."
            )
        case .steadyState:
            return SupplementPhaseContent(
                biologicalDescription: "\(supplementName) has reached full efficacy. Your body is maintaining optimal levels with continued supplementation.",
                watchFor: "Sustained benefits across your targeted wellness areas. Continue consistent daily intake to maintain these levels.",
                nextMilestone: "You've reached steady state. Continue daily for maintained benefits."
            )
        }
    }

    // MARK: - Daily Tips

    static let dailyTips: [String] = [
        "Fat-soluble vitamins (D3, K2, CoQ10) absorb up to 3x better when taken with a meal containing healthy fats.",
        "Magnesium glycinate is one of the most bioavailable forms and causes less GI distress than oxide or citrate.",
        "Taking probiotics on an empty stomach helps more live cultures survive the journey through stomach acid.",
        "Omega-3 fish oil in triglyceride form is 70% better absorbed than the cheaper ethyl ester form.",
        "L-Theanine crosses the blood-brain barrier within 30 minutes, promoting alpha brain waves for calm focus.",
        "Ashwagandha KSM-66 is standardized to 5% withanolides — the active compounds that reduce cortisol.",
        "Splitting your Vitamin C dose into two servings improves utilization since it's water-soluble.",
        "Creatine doesn't require a loading phase at 5g/day — full muscle saturation occurs within 3-4 weeks.",
        "Biotin can interfere with certain lab tests. Let your doctor know you're taking it before blood work.",
        "Iron bisglycinate is 4x better absorbed than ferrous sulfate with significantly fewer side effects.",
        "Taking iron with Vitamin C can enhance absorption by up to 67%.",
        "Zinc and iron compete for absorption — space them at least 2 hours apart for best results.",
        "Collagen synthesis requires Vitamin C as a cofactor — pairing them together maximizes skin benefits.",
        "NAC is best absorbed on an empty stomach, where it directly feeds glutathione production.",
        "Rhodiola Rosea works best when taken in the morning on an empty stomach.",
        "Tart cherry extract contains natural melatonin precursors plus anti-inflammatory anthocyanins.",
        "Methylated B vitamins (methylfolate, methylcobalamin) are important for those with MTHFR variations.",
        "CoQ10 in ubiquinol form is 2-3x better absorbed than ubiquinone and is already in its active form.",
        "Lion's Mane dual-extracted (water + alcohol) provides the full spectrum of hericenones and erinacines.",
        "Consistency matters more than timing for most supplements — the same time daily builds the habit.",
        "Melatonin works best at low doses (0.5-1mg). Higher doses often cause grogginess without better sleep.",
        "Berberine's naturally low bioavailability improves significantly when taken with a meal.",
        "Delayed-release probiotic capsules deliver 10x more viable bacteria to the intestines than standard ones.",
        "Vitamin D3 (cholecalciferol) is 87% more effective than D2 at raising serum levels.",
        "K2 in the MK-7 form has the longest half-life, directing calcium to bones instead of arteries.",
        "Hydrolyzed collagen peptides have over 90% absorption — they dissolve in both hot and cold liquids.",
        "Morning supplements like B vitamins can be energizing — avoid taking them close to bedtime.",
        "Store probiotics according to label instructions — some require refrigeration to maintain potency.",
        "Sublingual melatonin absorbs directly through oral mucosa, working in 15-20 minutes vs 45 for swallowed tablets.",
        "Your supplement plan is personalized — taking them consistently helps us measure what's actually working.",
        "Adaptogens like Ashwagandha and Rhodiola work by modulating your stress response, not masking it.",
        "Water-soluble vitamins (B, C) are safely excreted if you take more than needed — no toxicity risk.",
        "Whey protein isolate has the highest leucine content of any protein source — leucine is the key trigger for muscle protein synthesis.",
        "Plant protein blends (pea + rice) provide a complete amino acid profile comparable to whey, without dairy.",
    ]

    // MARK: - Personalization Signals (Static Fallback)

    /// Highest-impact personalization signals seeded for offline/static mode.
    /// Profile field → condition → effect on supplement scoring.
    static let personalizationSignals: [SupabasePersonalizationSignal] = {
        var signals: [SupabasePersonalizationSignal] = []
        var index = 0

        func id() -> UUID {
            index += 1
            return UUID(uuidString: "10000000-0000-0000-0000-\(String(format: "%012d", index))")!
        }

        func suppId(_ name: String) -> UUID {
            allSupplements.first(where: { $0.name == name })!.id
        }

        // Diet signals
        for name in ["Vitamin B Complex", "Vitamin D3 + K2"] {
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "diet_type", condition: "vegan", effect: "increase", magnitude: "major", source: "onboarding_profile", rationale: "Vegan diets lack reliable sources of B12 and D3", createdAt: nil))
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "diet_type", condition: "vegetarian", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Vegetarian diets often lack adequate B12 and D3", createdAt: nil))
        }
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Iron"), profileField: "diet_type", condition: "vegan", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Plant-based iron (non-heme) is less bioavailable", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Magnesium Glycinate"), profileField: "diet_type", condition: "keto", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Keto diets increase magnesium excretion", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Omega-3 (EPA/DHA)"), profileField: "diet_type", condition: "pescatarian", effect: "decrease", magnitude: "minor", source: "onboarding_profile", rationale: "Pescatarian diets typically provide adequate omega-3 from fish", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Omega-3 (EPA/DHA)"), profileField: "diet_type", condition: "mediterranean", effect: "decrease", magnitude: "minor", source: "onboarding_profile", rationale: "Mediterranean diets are rich in omega-3 fatty acids", createdAt: nil))

        // Exercise signals
        for name in ["Creatine Monohydrate", "Magnesium Glycinate"] {
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "exercise_frequency", condition: "5+_weekly", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "High exercise frequency increases demand for recovery nutrients", createdAt: nil))
        }
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Whey Protein Isolate"), profileField: "exercise_frequency", condition: "5+_weekly", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Active training increases protein requirements", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Plant Protein Blend"), profileField: "exercise_frequency", condition: "5+_weekly", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Active training increases protein requirements", createdAt: nil))

        // Stress signals
        for name in ["Ashwagandha KSM-66", "L-Theanine", "Magnesium Glycinate"] {
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "stress_level", condition: "high", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "High stress increases demand for calming and adaptogenic support", createdAt: nil))
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "stress_level", condition: "very_high", effect: "increase", magnitude: "major", source: "onboarding_profile", rationale: "Very high stress strongly increases need for stress-modulating supplements", createdAt: nil))
        }

        // Caffeine signals
        for name in ["L-Theanine", "Magnesium Glycinate"] {
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "caffeine_daily", condition: "high", effect: "increase", magnitude: "minor", source: "onboarding_profile", rationale: "High caffeine intake increases magnesium excretion and benefits from L-Theanine pairing", createdAt: nil))
        }

        // Alcohol signals
        for name in ["Vitamin B Complex", "NAC", "Magnesium Glycinate", "Zinc"] {
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "alcohol_weekly", condition: "4-7_drinks", effect: "increase", magnitude: "minor", source: "onboarding_profile", rationale: "Moderate alcohol depletes B vitamins, glutathione, magnesium, and zinc", createdAt: nil))
            signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId(name), profileField: "alcohol_weekly", condition: "8+_drinks", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Heavy alcohol significantly depletes B vitamins, glutathione, magnesium, and zinc", createdAt: nil))
        }

        // Age signals
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("CoQ10"), profileField: "age_range", condition: "50-64", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Natural CoQ10 production declines significantly after age 50", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("CoQ10"), profileField: "age_range", condition: "65+", effect: "increase", magnitude: "major", source: "onboarding_profile", rationale: "CoQ10 production is substantially reduced over 65", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Collagen Peptides"), profileField: "age_range", condition: "50-64", effect: "increase", magnitude: "minor", source: "onboarding_profile", rationale: "Collagen production declines with age", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Collagen Peptides"), profileField: "age_range", condition: "65+", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Significant collagen decline over 65", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Rhodiola Rosea"), profileField: "age_range", condition: "65+", effect: "decrease", magnitude: "minor", source: "onboarding_profile", rationale: "Stimulating adaptogens should be used cautiously in older adults", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Ashwagandha KSM-66"), profileField: "age_range", condition: "65+", effect: "decrease", magnitude: "minor", source: "onboarding_profile", rationale: "Adaptogen dosing should be conservative for older adults", createdAt: nil))

        // Baseline wellness signals
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Magnesium Glycinate"), profileField: "baseline_sleep", condition: "low", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Low baseline sleep indicates strong need for sleep-supporting minerals", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Melatonin"), profileField: "baseline_sleep", condition: "low", effect: "increase", magnitude: "minor", source: "onboarding_profile", rationale: "Low baseline sleep may benefit from melatonin support", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("Vitamin B Complex"), profileField: "baseline_energy", condition: "low", effect: "increase", magnitude: "moderate", source: "onboarding_profile", rationale: "Low baseline energy suggests B vitamin support for energy metabolism", createdAt: nil))
        signals.append(SupabasePersonalizationSignal(id: id(), supplementId: suppId("CoQ10"), profileField: "baseline_energy", condition: "low", effect: "increase", magnitude: "minor", source: "onboarding_profile", rationale: "Low baseline energy may benefit from mitochondrial support", createdAt: nil))

        return signals
    }()

    // MARK: - Dose Ranges (Static Fallback)

    /// Safe dose ranges for each supplement: (low, high, upperTolerableLimit)
    static let doseRanges: [String: (low: Double, high: Double, limit: Double?)] = [
        "Magnesium Glycinate": (200, 400, 400),
        "Vitamin D3 + K2": (1000, 5000, 10000),
        "Omega-3 (EPA/DHA)": (500, 2000, 3000),
        "Ashwagandha KSM-66": (300, 600, 600),
        "L-Theanine": (100, 400, 400),
        "Vitamin B Complex": (0, 0, nil),   // dosed by capsule, not mg
        "Probiotics": (0, 0, nil),           // dosed by CFU
        "Zinc": (15, 30, 40),
        "Vitamin C": (500, 2000, 2000),
        "CoQ10": (100, 300, 1200),
        "Creatine Monohydrate": (3000, 5000, 10000),
        "Collagen Peptides": (5000, 15000, nil),
        "Lion's Mane": (500, 3000, nil),
        "Rhodiola Rosea": (200, 600, 600),
        "Melatonin": (0.5, 3, 5),
        "Biotin": (2.5, 10, nil),            // in mg (2500-10000mcg)
        "Iron": (8, 27, 45),
        "NAC": (600, 1800, 1800),
        "Berberine": (500, 1500, 1500),
        "Tart Cherry Extract": (500, 1000, nil),
        "Whey Protein Isolate": (20000, 40000, nil),
        "Plant Protein Blend": (20000, 40000, nil),
    ]

}
