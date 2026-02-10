import Foundation

struct RecommendationEngine {

    // MARK: - Generate Plan

    func generatePlan(for profile: UserProfile) -> SupplementPlan {
        // Step 1: Goal mapping → candidate supplements scored by goal overlap
        var candidateScores: [String: Int] = [:]
        let goalKeys = profile.healthGoals.map { $0.rawValue }

        for goal in goalKeys {
            if let supplementNames = SupplementKnowledgeBase.goalSupplementMap[goal] {
                for name in supplementNames {
                    candidateScores[name, default: 0] += 1
                }
            }
        }

        // Step 2: Interaction filter
        let medicationKeywords = extractMedicationKeywords(from: profile)
        let excludedSupplements = findExcludedSupplements(medications: medicationKeywords, allergies: profile.allergies)

        let filteredCandidates = candidateScores.filter { !excludedSupplements.contains($0.key) }

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
            guard let supplement = SupplementKnowledgeBase.supplement(named: name) else { continue }

            // Allow max 2 per category for diversity
            let categoryCount = selected.filter { $0.category == supplement.category }.count
            if categoryCount >= 2 { continue }

            selected.append(supplement)
            usedCategories.insert(supplement.category)
        }

        // Ensure vegan/vegetarian get B12 and D3
        if profile.dietType == .vegan || profile.dietType == .vegetarian {
            addIfMissing("Vitamin B Complex", to: &selected, excluded: excludedSupplements)
            addIfMissing("Vitamin D3 + K2", to: &selected, excluded: excludedSupplements)
        }

        // Step 5: Build plan supplements with dosage adjustments, timing, and tier data
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
                SupplementKnowledgeBase.goalSupplementMap[goalKey]?.contains(supplement.name) == true
            }
            let overlapScore = matched.count

            return PlanSupplement(
                supplementId: supplement.id,
                name: supplement.name,
                dosage: dosageText,
                dosageMg: dosage,
                timing: timing,
                category: supplement.category,
                sortOrder: index,
                matchedGoals: Array(matched).sorted(),
                goalOverlapScore: overlapScore,
                researchNote: supplement.notes
            )
        }

        // Assign tiers based on goal overlap score
        assignTiers(to: &planSupplements)

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

        return SupplementPlan(supplements: planSupplements)
    }

    // MARK: - Build Single Plan Supplement

    func buildPlanSupplement(from supplement: Supplement, for profile: UserProfile, existingSupplements: [PlanSupplement]) -> PlanSupplement {
        let userGoalKeys = Set(profile.healthGoals.map { $0.rawValue })

        var dosage = supplement.recommendedDosageMg
        dosage = adjustDosage(baseDosage: dosage, supplement: supplement, profile: profile)
        let dosageText = formatDosage(dosage: dosage, supplement: supplement)
        let timing = resolveTiming(for: supplement, profile: profile)

        let matched = userGoalKeys.filter { goalKey in
            SupplementKnowledgeBase.goalSupplementMap[goalKey]?.contains(supplement.name) == true
        }
        let overlapScore = matched.count

        var planSupplement = PlanSupplement(
            supplementId: supplement.id,
            name: supplement.name,
            dosage: dosageText,
            dosageMg: dosage,
            timing: timing,
            category: supplement.category,
            sortOrder: existingSupplements.count,
            matchedGoals: Array(matched).sorted(),
            goalOverlapScore: overlapScore,
            researchNote: supplement.notes
        )

        // Assign tier based on score
        var tempList = existingSupplements + [planSupplement]
        assignTiers(to: &tempList)
        if let assigned = tempList.last {
            planSupplement.tier = assigned.tier
        }

        return planSupplement
    }

    // MARK: - Tier Assignment

    func assignTiers(to supplements: inout [PlanSupplement]) {
        // Standard thresholds: 3+ = core, 2 = targeted, 1 = supporting
        let hasNaturalCore = supplements.contains { $0.goalOverlapScore >= 3 }

        if hasNaturalCore {
            for i in supplements.indices {
                let score = supplements[i].goalOverlapScore
                if score >= 3 {
                    supplements[i].tier = .core
                } else if score == 2 {
                    supplements[i].tier = .targeted
                } else {
                    supplements[i].tier = .supporting
                }
            }
        } else {
            // Edge case: no supplements score 3+, promote highest-scoring to core
            let maxScore = supplements.map(\.goalOverlapScore).max() ?? 1
            for i in supplements.indices {
                let score = supplements[i].goalOverlapScore
                if score == maxScore {
                    supplements[i].tier = .core
                } else if score == maxScore - 1, maxScore > 1 {
                    supplements[i].tier = .targeted
                } else {
                    supplements[i].tier = .supporting
                }
            }
        }
    }

    // MARK: - Helpers

    func extractMedicationKeywords(from profile: UserProfile) -> [String] {
        let meds = profile.medications
        return meds.flatMap { med in
            med.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { !$0.isEmpty }
        }
    }

    func findExcludedSupplements(medications: [String], allergies: [String]) -> Set<String> {
        var excluded: Set<String> = []

        // Check medication interactions
        for keyword in medications {
            let interactions = SupplementKnowledgeBase.interactionsForMedication(keyword)
            excluded.formUnion(interactions)
        }

        // Check allergies
        let allergyKeywords = allergies.map { $0.lowercased() }
        if allergyKeywords.contains("shellfish") {
            // Some glucosamine/chondroitin derived from shellfish, but none in our KB currently
        }
        if allergyKeywords.contains("fish") || allergyKeywords.contains("shellfish") {
            excluded.insert("Omega-3 (EPA/DHA)") // Fish-derived; could suggest algae-based instead
        }
        if allergyKeywords.contains("soy") {
            // Some supplements use soy-based capsules
        }

        return excluded
    }

    private func addIfMissing(_ name: String, to list: inout [Supplement], excluded: Set<String>) {
        guard !excluded.contains(name) else { return }
        guard !list.contains(where: { $0.name == name }) else { return }
        if let supplement = SupplementKnowledgeBase.supplement(named: name) {
            list.append(supplement)
        }
    }

    func adjustDosage(baseDosage: Double, supplement: Supplement, profile: UserProfile) -> Double {
        var dosage = baseDosage

        // Age adjustments
        if profile.age > 65 {
            // Reduce stimulant-type supplements for older adults
            if ["Rhodiola Rosea", "CoQ10"].contains(supplement.name) {
                dosage *= 0.75
            }
        }

        // Sex-based adjustments
        if profile.sex == .female && supplement.name == "Iron" {
            dosage = 27 // Higher iron for women of reproductive age
        } else if profile.sex == .male && supplement.name == "Iron" {
            dosage = 8 // Lower for men
        }

        // Weight-based adjustments for fat-soluble vitamins
        if let weight = profile.weightLbs, weight > 200 {
            if supplement.name == "Vitamin D3 + K2" {
                dosage = 4000 // Higher D3 for heavier individuals
            }
        }

        return dosage
    }

    func formatDosage(dosage: Double, supplement: Supplement) -> String {
        // Special cases
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
        // Use the recommended timing from knowledge base
        return supplement.recommendedTiming
    }
}
