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
    let category: String
    let commonDosageRange: String
    let recommendedDosageMg: Double
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
        "immune_support": [
            GoalSupplementEntry(name: "Vitamin D3 + K2", weight: 3),
            GoalSupplementEntry(name: "Vitamin C", weight: 2),
            GoalSupplementEntry(name: "Zinc", weight: 2),
            GoalSupplementEntry(name: "NAC", weight: 1),
        ],
        "stress_anxiety": [
            GoalSupplementEntry(name: "Ashwagandha KSM-66", weight: 2),
            GoalSupplementEntry(name: "L-Theanine", weight: 2),
            GoalSupplementEntry(name: "Magnesium Glycinate", weight: 2),
            GoalSupplementEntry(name: "Rhodiola Rosea", weight: 2),
        ],
        "muscle_recovery": [
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

    // MARK: - Seeded Supplements

    static let allSupplements: [Supplement] = [
        Supplement(
            id: UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            name: "Magnesium Glycinate",
            category: "mineral",
            commonDosageRange: "200-400mg",
            recommendedDosageMg: 400,
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
    ]

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
    ]

}
