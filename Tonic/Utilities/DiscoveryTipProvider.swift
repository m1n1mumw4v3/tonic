import SwiftUI

enum DiscoveryTipProvider {

    static func tips(for plan: SupplementPlan?) -> [DiscoveryTip] {
        let supplementTips = supplementTips(for: plan)
        let habitTips = habitTips

        // Interleave: supplement, habit, supplement, habit, ...
        var result: [DiscoveryTip] = []
        var sIdx = 0
        var hIdx = 0

        while result.count < 8 && (sIdx < supplementTips.count || hIdx < habitTips.count) {
            if sIdx < supplementTips.count {
                result.append(supplementTips[sIdx])
                sIdx += 1
            }
            if result.count < 8 && hIdx < habitTips.count {
                result.append(habitTips[hIdx])
                hIdx += 1
            }
        }

        return result
    }

    // MARK: - Supplement Tips

    private static func supplementTips(for plan: SupplementPlan?) -> [DiscoveryTip] {
        guard let plan else { return [] }

        var tips: [DiscoveryTip] = []

        for supplement in plan.supplements where supplement.isIncluded {
            let color = dimensionColor(for: supplement)

            // Fun fact from CheckInInsightGenerator
            if let facts = CheckInInsightGenerator.supplementFunFacts[supplement.name],
               let fact = facts.first {
                tips.append(DiscoveryTip(
                    category: .didYouKnow,
                    title: supplement.name,
                    body: fact,
                    accentColor: color,
                    supplementName: supplement.name
                ))
            }

            // Absorption/timing tip from knowledge base
            if let kb = SupplementKnowledgeBase.supplement(named: supplement.name) {
                tips.append(DiscoveryTip(
                    category: .supplementFact,
                    title: "\(supplement.name) Tip",
                    body: kb.notes,
                    accentColor: color,
                    supplementName: supplement.name
                ))
            }
        }

        return tips
    }

    // MARK: - Habit Tips

    private static let habitTips: [DiscoveryTip] = [
        DiscoveryTip(
            category: .habitTip,
            title: "Consistency Beats Perfection",
            body: "21 days of consistency builds lasting habits. Don't worry about being perfect — just keep showing up.",
            accentColor: DesignTokens.positive
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "The Tracking Effect",
            body: "People who track daily are 42% more likely to achieve their health goals. Your check-ins matter.",
            accentColor: DesignTokens.info
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "Timing Matters",
            body: "Taking supplements at the same time each day improves both adherence and absorption.",
            accentColor: DesignTokens.accentEnergy
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "Small Signals, Big Picture",
            body: "Patterns emerge after just 5-7 days of data. Your first week of check-ins unlocks real insights.",
            accentColor: DesignTokens.accentClarity
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "Stack Your Habits",
            body: "Attach supplement-taking to an existing routine — like morning coffee or brushing your teeth.",
            accentColor: DesignTokens.accentMood
        ),
        DiscoveryTip(
            category: .habitTip,
            title: "Rest Days Count Too",
            body: "Logging on off-days reveals which supplements are truly driving change in how you feel.",
            accentColor: DesignTokens.accentSleep
        ),
    ]

    // MARK: - Color Mapping

    private static func dimensionColor(for supplement: PlanSupplement) -> Color {
        // Map from matchedGoals to a WellnessDimension color
        let goalToDimension: [String: Color] = [
            "sleep": DesignTokens.accentSleep,
            "energy": DesignTokens.accentEnergy,
            "focus": DesignTokens.accentClarity,
            "gut_health": DesignTokens.accentGut,
            "stress_anxiety": DesignTokens.accentMood,
            "immunity": DesignTokens.accentGut,
            "fitness_recovery": DesignTokens.accentEnergy,
            "skin_hair_nails": DesignTokens.accentMood,
            "longevity": DesignTokens.accentLongevity,
        ]

        if let firstGoal = supplement.matchedGoals.first,
           let color = goalToDimension[firstGoal] {
            return color
        }

        // Fallback: check knowledge base benefits
        if let kb = SupplementKnowledgeBase.supplement(named: supplement.name),
           let firstBenefit = kb.benefits.first,
           let color = goalToDimension[firstBenefit] {
            return color
        }

        return DesignTokens.info
    }
}
