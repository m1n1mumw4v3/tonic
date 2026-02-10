import SwiftUI

// MARK: - Insight Model

struct CheckInInsight {
    let key: String
    let message: String
    let icon: String
    let accentColor: Color
    let dimension: WellnessDimension?
}

// MARK: - Recent Insight Tracker

enum RecentInsightTracker {
    private static let defaultsKey = "recentInsightKeys"
    private static let maxCount = 5

    static func recentKeys() -> Set<String> {
        let array = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        return Set(array)
    }

    static func record(_ key: String) {
        var array = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
        array.append(key)
        if array.count > maxCount {
            array = Array(array.suffix(maxCount))
        }
        UserDefaults.standard.set(array, forKey: defaultsKey)
    }
}

// MARK: - Generator

struct CheckInInsightGenerator {

    struct Context {
        let todayScores: [WellnessDimension: Int]
        let baselines: [WellnessDimension: Int]
        let trailingAverages: [WellnessDimension: Double]
        let recentCheckIns: [DailyCheckIn]
        let streak: UserStreak
        let supplementsTakenToday: [(name: String, id: UUID)]
        let plan: SupplementPlan?
        let recentlyShownKeys: Set<String>
    }

    func generate(from context: Context) -> CheckInInsight? {
        let rules: [(Context) -> CheckInInsight?] = [
            personalBest,
            supplementConsistency,
            aboveBaseline,
            aboveTrailingAverage,
            consecutiveImprovement,
            fullAdherence,
            supplementFunFact,
            supplementTip,
            genericFallback,
        ]

        for rule in rules {
            if let insight = rule(context) {
                // Generic fallback bypasses freshness filter
                if insight.key.hasPrefix("generic_") {
                    return insight
                }
                if !context.recentlyShownKeys.contains(insight.key) {
                    return insight
                }
            }
        }

        // If all filtered, force generic fallback
        return genericFallback(context)
    }

    // MARK: - Rule 1: Personal Best

    private func personalBest(_ context: Context) -> CheckInInsight? {
        guard context.recentCheckIns.count >= 3 else { return nil }

        var bestDimension: WellnessDimension?
        var bestScore = 0

        for dimension in WellnessDimension.allCases {
            guard let todayScore = context.todayScores[dimension] else { continue }
            let historicalMax = context.recentCheckIns.map { $0.score(for: dimension) }.max() ?? 0
            if todayScore > historicalMax && todayScore > bestScore {
                bestScore = todayScore
                bestDimension = dimension
            }
        }

        guard let dimension = bestDimension else { return nil }
        return CheckInInsight(
            key: "pb_\(dimension.rawValue)",
            message: "Personal best! Your \(dimension.label.lowercased()) hit \(bestScore)/10 \u{2014} your highest ever.",
            icon: "trophy.fill",
            accentColor: dimension.color,
            dimension: dimension
        )
    }

    // MARK: - Rule 2: Supplement Consistency

    private func supplementConsistency(_ context: Context) -> CheckInInsight? {
        let milestones = [3, 5, 7, 14, 21, 30]
        guard !context.supplementsTakenToday.isEmpty else { return nil }

        for supp in context.supplementsTakenToday {
            var consecutiveDays = 1 // today counts
            for checkIn in context.recentCheckIns {
                let wasTaken = checkIn.supplementLogs.contains {
                    $0.planSupplementId == supp.id && $0.taken
                }
                if wasTaken {
                    consecutiveDays += 1
                } else {
                    break
                }
            }

            if let milestone = milestones.last(where: { consecutiveDays >= $0 }) {
                let nameSlug = supp.name.lowercased().replacingOccurrences(of: " ", with: "_")
                let key = "supp_\(nameSlug)_\(milestone)"

                // Look up notes from knowledge base
                var hint = ""
                if let kb = SupplementKnowledgeBase.supplement(named: supp.name) {
                    hint = " " + kb.notes
                }

                return CheckInInsight(
                    key: key,
                    message: "You've been consistent with \(supp.name) for \(milestone) days.\(hint)",
                    icon: "pills.fill",
                    accentColor: DesignTokens.positive,
                    dimension: nil
                )
            }
        }

        return nil
    }

    // MARK: - Rule 3: Above Baseline

    private func aboveBaseline(_ context: Context) -> CheckInInsight? {
        var bestDimension: WellnessDimension?
        var bestDelta = 0

        for dimension in WellnessDimension.allCases {
            guard let todayScore = context.todayScores[dimension],
                  let baseline = context.baselines[dimension] else { continue }
            let delta = todayScore - baseline
            if delta >= 2 && delta > bestDelta {
                bestDelta = delta
                bestDimension = dimension
            }
        }

        guard let dimension = bestDimension else { return nil }
        return CheckInInsight(
            key: "above_baseline_\(dimension.rawValue)",
            message: "Your \(dimension.label.lowercased()) is \(bestDelta) points above your baseline today. Nice start!",
            icon: "arrow.up.right",
            accentColor: dimension.color,
            dimension: dimension
        )
    }

    // MARK: - Rule 4: Above Trailing Average

    private func aboveTrailingAverage(_ context: Context) -> CheckInInsight? {
        var bestDimension: WellnessDimension?
        var bestDelta: Double = 0

        for dimension in WellnessDimension.allCases {
            guard let todayScore = context.todayScores[dimension],
                  let avg = context.trailingAverages[dimension] else { continue }
            let delta = Double(todayScore) - avg
            if delta >= 1.5 && delta > bestDelta {
                bestDelta = delta
                bestDimension = dimension
            }
        }

        guard let dimension = bestDimension else { return nil }
        return CheckInInsight(
            key: "above_avg_\(dimension.rawValue)",
            message: "Your \(dimension.label.lowercased()) is running above your 7-day average today.",
            icon: "chart.line.uptrend.xyaxis",
            accentColor: dimension.color,
            dimension: dimension
        )
    }

    // MARK: - Rule 5: Consecutive Improvement

    private func consecutiveImprovement(_ context: Context) -> CheckInInsight? {
        var bestDimension: WellnessDimension?
        var bestRun = 0

        for dimension in WellnessDimension.allCases {
            guard let todayScore = context.todayScores[dimension] else { continue }
            var run = 1
            var previousScore = todayScore

            for checkIn in context.recentCheckIns {
                let score = checkIn.score(for: dimension)
                if score < previousScore {
                    run += 1
                    previousScore = score
                } else {
                    break
                }
            }

            if run >= 3 && run > bestRun {
                bestRun = run
                bestDimension = dimension
            }
        }

        guard let dimension = bestDimension else { return nil }
        return CheckInInsight(
            key: "improving_\(dimension.rawValue)_\(bestRun)",
            message: "Your \(dimension.label.lowercased()) has been climbing for \(bestRun) days straight.",
            icon: "arrow.up.forward",
            accentColor: dimension.color,
            dimension: dimension
        )
    }

    // MARK: - Rule 6: Supplement Fun Fact

    private static let supplementFunFacts: [String: [String]] = [
        "Magnesium Glycinate": [
            "Magnesium is involved in 300+ enzymatic reactions in your body.",
            "Glycinate is the most bioavailable form — it crosses the blood-brain barrier easily.",
            "~50% of Americans don't get enough magnesium from diet alone.",
        ],
        "Vitamin D3 + K2": [
            "Your skin produces Vitamin D from sunlight, but most people still don't get enough.",
            "K2 directs calcium to your bones instead of your arteries — that's why D3+K2 pair together.",
            "Vitamin D receptors exist in nearly every cell in your body.",
        ],
        "Omega-3 (EPA/DHA)": [
            "EPA and DHA are the two fatty acids your brain actually uses — ALA from plants converts poorly.",
            "Your brain is ~60% fat, and DHA is its most abundant structural fatty acid.",
            "Omega-3s are incorporated into cell membranes, improving fluidity and signaling.",
        ],
        "Ashwagandha KSM-66": [
            "Ashwagandha is classified as an adaptogen — it helps your body resist physical and mental stress.",
            "KSM-66 is extracted from the root only, which has the highest concentration of withanolides.",
            "Clinical trials show cortisol reductions of ~25% with consistent use over 8 weeks.",
        ],
        "L-Theanine": [
            "L-Theanine promotes alpha brain waves — the same pattern seen during calm, focused attention.",
            "Found naturally in green tea, it's why tea feels calming despite the caffeine.",
            "It pairs well with caffeine: focus without the jitters.",
        ],
        "Vitamin B Complex": [
            "B vitamins are water-soluble — your body can't store them, so daily intake matters.",
            "B12 deficiency is common in vegetarians and older adults due to lower absorption.",
            "B vitamins are cofactors in converting food into cellular energy (ATP).",
        ],
        "Probiotics": [
            "Your gut contains ~70% of your immune system's cells.",
            "The gut-brain axis means your microbiome directly influences mood and cognition.",
            "Different probiotic strains do different things — diversity matters.",
        ],
        "Zinc": [
            "Zinc is essential for immune cell development and communication.",
            "It's a key cofactor for over 100 enzymes involved in metabolism.",
            "Zinc and copper compete for absorption — long-term zinc use may need copper balance.",
        ],
        "CoQ10": [
            "CoQ10 lives in your mitochondria and is essential for energy production in every cell.",
            "Your natural CoQ10 levels decline with age, especially after 40.",
            "Statins deplete CoQ10 — supplementing can help offset muscle-related side effects.",
        ],
        "Creatine Monohydrate": [
            "Creatine isn't just for athletes — it also supports brain energy and cognitive function.",
            "It's the most studied sports supplement in history, with a strong safety profile.",
            "Your body makes ~1g/day, but 3-5g supplementation saturates muscle stores.",
        ],
        "Lion's Mane": [
            "Lion's Mane stimulates Nerve Growth Factor (NGF), which supports neuron health.",
            "It's one of the few supplements studied for potential neurogenesis in adults.",
            "Traditional use in Chinese medicine dates back centuries for cognitive support.",
        ],
        "NAC": [
            "NAC is a precursor to glutathione, your body's most powerful endogenous antioxidant.",
            "It's used in hospitals to treat acetaminophen overdose due to its liver-protective effects.",
            "NAC also thins mucus, which is why it supports respiratory health.",
        ],
        "Collagen Peptides": [
            "Your body's collagen production drops ~1% per year starting in your mid-20s.",
            "Hydrolyzed collagen peptides are broken down for better absorption vs. whole collagen.",
            "Types I and III support skin elasticity; Type II supports joint cartilage.",
        ],
        "Rhodiola Rosea": [
            "Rhodiola is an adaptogen used for centuries in Scandinavian and Russian traditional medicine.",
            "It works partly by modulating cortisol and supporting serotonin/dopamine balance.",
            "Look for extracts standardized to 3% rosavins and 1% salidroside for best results.",
        ],
        "Berberine": [
            "Berberine activates AMPK, sometimes called the body's 'metabolic master switch.'",
            "Studies show blood sugar regulation comparable to some prescription medications.",
            "It also has antimicrobial properties that support a healthy gut microbiome.",
        ],
        "Tart Cherry Extract": [
            "Tart cherries are one of the few natural food sources of melatonin.",
            "Their anthocyanins have anti-inflammatory effects comparable to some NSAIDs.",
            "Studies show improved sleep duration and quality in adults taking tart cherry.",
        ],
    ]

    private func supplementFunFact(_ context: Context) -> CheckInInsight? {
        for supp in context.supplementsTakenToday {
            guard let facts = Self.supplementFunFacts[supp.name], !facts.isEmpty else { continue }
            let index = context.recentCheckIns.count % facts.count
            let nameSlug = supp.name.lowercased().replacingOccurrences(of: " ", with: "_")
            return CheckInInsight(
                key: "fun_fact_\(nameSlug)_\(index)",
                message: facts[index],
                icon: "brain.head.profile",
                accentColor: DesignTokens.info,
                dimension: nil
            )
        }
        return nil
    }

    // MARK: - Rule 7: Full Adherence

    private func fullAdherence(_ context: Context) -> CheckInInsight? {
        guard let plan = context.plan,
              plan.supplements.count >= 2 else { return nil }

        let allTaken = plan.supplements.allSatisfy { supplement in
            context.supplementsTakenToday.contains { $0.id == supplement.id }
        }

        guard allTaken else { return nil }
        return CheckInInsight(
            key: "full_adherence",
            message: "Perfect adherence \u{2014} you took everything today!",
            icon: "checkmark.seal.fill",
            accentColor: DesignTokens.positive,
            dimension: nil
        )
    }

    // MARK: - Rule 8: Supplement Absorption Tip

    private func supplementTip(_ context: Context) -> CheckInInsight? {
        for supp in context.supplementsTakenToday {
            if let kb = SupplementKnowledgeBase.supplement(named: supp.name) {
                let nameSlug = supp.name.lowercased().replacingOccurrences(of: " ", with: "_")
                return CheckInInsight(
                    key: "supp_tip_\(nameSlug)",
                    message: "\(supp.name) tip: \(kb.notes)",
                    icon: "lightbulb.fill",
                    accentColor: DesignTokens.info,
                    dimension: nil
                )
            }
        }
        return nil
    }

    // MARK: - Rule 9: Generic Fallback

    private static let genericMessages = [
        "Every check-in teaches us something new about your body.",
        "Tracking is the first step to optimization.",
        "Your data is building a clearer picture every day.",
        "Small daily signals add up to big insights.",
        "The best supplement plan is the one you actually track.",
        "You showed up today. That matters.",
    ]

    private func genericFallback(_ context: Context) -> CheckInInsight? {
        let pool = Self.genericMessages
        let index = context.recentCheckIns.count % pool.count
        return CheckInInsight(
            key: "generic_\(index)",
            message: pool[index],
            icon: "sparkle",
            accentColor: DesignTokens.info,
            dimension: nil
        )
    }
}
