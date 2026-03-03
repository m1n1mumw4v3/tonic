import XCTest
@testable import Estus

final class RecommendationEngineTests: XCTestCase {
    let engine: RecommendationEngine = {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        return RecommendationEngine(catalog: catalog)
    }()

    // MARK: - Goal Mapping

    func testSleepGoalIncludesMagnesium() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Magnesium Glycinate" },
            "Sleep goal should include Magnesium Glycinate"
        )
    }

    func testStressGoalIncludesAshwagandha() {
        var profile = UserProfile()
        profile.healthGoals = [.stressAnxiety]
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Ashwagandha KSM-66" },
            "Stress goal should include Ashwagandha KSM-66"
        )
    }

    func testSleepAndStressGoals() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .stressAnxiety]
        let plan = engine.generatePlan(for: profile)

        let names = plan.supplements.map(\.name)
        XCTAssertTrue(names.contains("Magnesium Glycinate"), "Should include Magnesium")
        XCTAssertTrue(names.contains("Ashwagandha KSM-66"), "Should include Ashwagandha")
    }

    // MARK: - Interaction Filtering

    func testWarfarinExcludesOmega3() {
        var profile = UserProfile()
        profile.healthGoals = [.focus, .longevity]
        profile.medications = ["Warfarin"]
        let plan = engine.generatePlan(for: profile)

        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Omega-3 (EPA/DHA)" },
            "Warfarin should exclude Omega-3"
        )
    }

    func testLevothyroxineExcludesIron() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.medications = ["Levothyroxine"]
        let plan = engine.generatePlan(for: profile)

        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Iron" },
            "Levothyroxine should exclude Iron"
        )
    }

    // MARK: - Vegan Adjustments

    func testVeganGetsB12AndD3() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        profile.dietType = .vegan
        let plan = engine.generatePlan(for: profile)

        let names = plan.supplements.map(\.name)
        XCTAssertTrue(names.contains("Vitamin B Complex"), "Vegan should get B Complex")
        XCTAssertTrue(names.contains("Vitamin D3 + K2"), "Vegan should get D3 + K2")
    }

    // MARK: - Plan Size

    func testPlanSizeWithinBounds() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy, .focus, .immunity, .longevity]
        let plan = engine.generatePlan(for: profile)

        XCTAssertGreaterThanOrEqual(plan.supplements.count, 3, "Plan should have at least 3 supplements")
        XCTAssertLessThanOrEqual(plan.supplements.count, 10, "Plan should have at most 10 supplements")
    }

    // MARK: - Timing

    func testSupplementsHaveValidTiming() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy]
        let plan = engine.generatePlan(for: profile)

        for supplement in plan.supplements {
            XCTAssertNotNil(
                SupplementTiming(rawValue: supplement.timing.rawValue),
                "\(supplement.name) should have valid timing"
            )
        }
    }

    // MARK: - Determinism

    func testPlanIsDeterministic() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy, .focus]
        profile.age = 30
        profile.sex = .male

        let plan1 = engine.generatePlan(for: profile)
        let plan2 = engine.generatePlan(for: profile)

        let names1 = plan1.supplements.map(\.name)
        let names2 = plan2.supplements.map(\.name)

        XCTAssertEqual(names1, names2, "Same profile should produce same plan")
    }

    // MARK: - Dosage Adjustments

    func testFemaleGetsHigherIron() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .female
        let plan = engine.generatePlan(for: profile)

        if let iron = plan.supplements.first(where: { $0.name == "Iron" }) {
            XCTAssertEqual(iron.dosageMg, 27, "Women should get 27mg iron")
        }
    }

    // MARK: - Wellbeing Score

    func testWellbeingScoreCalculation() {
        let score = WellbeingScore.calculate(sleep: 80, energy: 60, clarity: 70, mood: 90, gut: 50)
        XCTAssertEqual(score, 70, "Average of 80,60,70,90,50 should be 70")
    }

    func testWellbeingScoreAllZero() {
        let score = WellbeingScore.calculate(sleep: 0, energy: 0, clarity: 0, mood: 0, gut: 0)
        XCTAssertEqual(score, 0)
    }

    func testWellbeingScoreAllMax() {
        let score = WellbeingScore.calculate(sleep: 100, energy: 100, clarity: 100, mood: 100, gut: 100)
        XCTAssertEqual(score, 100)
    }

    // MARK: - Plan Summary

    func testPlanSummaryIsGenerated() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy]
        let plan = engine.generatePlan(for: profile)

        XCTAssertNotNil(plan.aiReasoning, "Plan should have aiReasoning")
        XCTAssertFalse(plan.aiReasoning?.isEmpty ?? true, "aiReasoning should not be empty")
    }

    func testPlanSummaryMentionsGoals() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy]
        let plan = engine.generatePlan(for: profile)
        let summary = plan.aiReasoning ?? ""

        let mentionsGoal = summary.contains("sleep") || summary.contains("energy")
        XCTAssertTrue(mentionsGoal, "Summary should reference at least one goal descriptor")
    }

    func testPlanSummaryMentionsCaffeinePairing() {
        var profile = UserProfile()
        profile.healthGoals = [.focus, .energy]
        profile.coffeeCupsDaily = 3
        let plan = engine.generatePlan(for: profile)
        let summary = plan.aiReasoning ?? ""

        if plan.supplements.contains(where: { $0.name == "L-Theanine" }) {
            XCTAssertTrue(summary.contains("coffee") || summary.contains("L-Theanine"),
                          "Summary should mention caffeine pairing when user drinks coffee and plan has L-Theanine")
        }
    }

    func testPlanSummaryMentionsVeganDiet() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        profile.dietType = .vegan
        let plan = engine.generatePlan(for: profile)
        let summary = plan.aiReasoning ?? ""

        XCTAssertTrue(summary.lowercased().contains("vegan") || summary.contains("diet"),
                      "Summary should mention vegan diet context")
    }

    func testPlanSummaryDeterministic() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy, .focus]
        profile.age = 30
        profile.sex = .male
        profile.coffeeCupsDaily = 2

        let plan1 = engine.generatePlan(for: profile)
        let plan2 = engine.generatePlan(for: profile)

        XCTAssertEqual(plan1.aiReasoning, plan2.aiReasoning, "Same profile should produce same summary")
    }

    // MARK: - Phase 2: Personalization Signal Scoring

    func testHighStressBoostsAdaptogens() {
        var profile = UserProfile()
        profile.healthGoals = [.energy, .stressAnxiety]
        profile.stressLevel = .high
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Ashwagandha KSM-66" },
            "High stress should boost Ashwagandha into the plan"
        )
    }

    func testHeavyAlcoholBoostsBComplex() {
        var profile = UserProfile()
        profile.healthGoals = [.energy, .longevity]
        profile.alcoholWeekly = .eightPlus
        let plan = engine.generatePlan(for: profile)

        let names = plan.supplements.map(\.name)
        XCTAssertTrue(names.contains("Vitamin B Complex") || names.contains("NAC"),
                      "Heavy alcohol should boost B Complex or NAC into the plan")
    }

    func testActiveExerciseBoostsCreatine() {
        var profile = UserProfile()
        profile.healthGoals = [.muscleDevelopment, .energy]
        profile.exerciseFrequency = .fivePlus
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Creatine Monohydrate" },
            "5+/week exercise should boost Creatine"
        )
    }

    func testLowBaselineSleepBoostsMagnesium() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        profile.baselineSleep = 2
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Magnesium Glycinate" },
            "Low baseline sleep should boost Magnesium"
        )
    }

    func testPersonalizationIsDeterministic() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy, .focus]
        profile.stressLevel = .high
        profile.dietType = .vegan
        profile.exerciseFrequency = .fivePlus
        profile.baselineSleep = 3
        profile.age = 55

        let plan1 = engine.generatePlan(for: profile)
        let plan2 = engine.generatePlan(for: profile)

        let names1 = plan1.supplements.map(\.name)
        let names2 = plan2.supplements.map(\.name)
        XCTAssertEqual(names1, names2, "Personalized plans should be deterministic")
    }

    // MARK: - Phase 3: Current Supplement Deduplication

    func testExactDupExcluded() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .stressAnxiety]
        profile.currentSupplements = ["Magnesium Glycinate"]
        let plan = engine.generatePlan(for: profile)

        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Magnesium Glycinate" },
            "Exact dup should be excluded from plan"
        )
    }

    func testFormVariantKeptWithNote() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .stressAnxiety]
        profile.currentSupplements = ["magnesium oxide"]
        let plan = engine.generatePlan(for: profile)

        if let mag = plan.supplements.first(where: { $0.name == "Magnesium Glycinate" }) {
            XCTAssertNotNil(mag.formUpgradeNote, "Form variant should have an upgrade note")
        }
    }

    func testEmptyCurrentSupplementsNoChange() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy]
        profile.currentSupplements = []
        let plan = engine.generatePlan(for: profile)

        XCTAssertGreaterThanOrEqual(plan.supplements.count, 3, "Empty current supplements should not affect plan")
    }

    // MARK: - Phase 4: Safety Rules

    func testNoDeepProfileNoSafetyBlocks() {
        var profile = UserProfile()
        profile.healthGoals = [.gutHealth, .energy]
        let plan = engine.generatePlan(for: profile)

        // Berberine should be present for gut_health goal with no medications
        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Berberine" },
            "Without deep profile or diabetes meds, Berberine should not be blocked"
        )
    }

    func testPregnancyStillExcludesCorrectly() {
        var profile = UserProfile()
        profile.healthGoals = [.stressAnxiety, .gutHealth]
        profile.isPregnant = true
        let plan = engine.generatePlan(for: profile)

        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Ashwagandha KSM-66" },
            "Pregnancy should still exclude Ashwagandha"
        )
        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Berberine" },
            "Pregnancy should still exclude Berberine"
        )
    }

    func testDiabeticWarnsOnBerberine() {
        var profile = UserProfile()
        profile.healthGoals = [.gutHealth, .heartHealth]
        profile.medications = ["Metformin"]
        let plan = engine.generatePlan(for: profile)

        if let berberine = plan.supplements.first(where: { $0.name == "Berberine" }) {
            let note = berberine.interactionNote ?? ""
            XCTAssertTrue(note.contains("blood sugar") || note.contains("diabetes") || note.contains("glucose"),
                          "Berberine should have a diabetes warning for users on Metformin")
        }
    }

    // MARK: - Phase 5: Dosage Adjustments

    func testDoseClampedToRange() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        let plan = engine.generatePlan(for: profile)

        if let mag = plan.supplements.first(where: { $0.name == "Magnesium Glycinate" }) {
            XCTAssertGreaterThanOrEqual(mag.dosageMg ?? 0, 200, "Magnesium dose should be >= 200mg")
            XCTAssertLessThanOrEqual(mag.dosageMg ?? 1000, 400, "Magnesium dose should be <= 400mg")
        }
    }

    func testLegacyIronRuleStillWorks() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .female
        let plan = engine.generatePlan(for: profile)

        if let iron = plan.supplements.first(where: { $0.name == "Iron" }) {
            XCTAssertEqual(iron.dosageMg, 27, "Female iron dose should be 27mg")
        }
    }

    func testLegacyD3WeightRuleStillWorks() {
        var profile = UserProfile()
        profile.healthGoals = [.immunity, .energy]
        profile.weightLbs = 250
        let plan = engine.generatePlan(for: profile)

        if let d3 = plan.supplements.first(where: { $0.name == "Vitamin D3 + K2" }) {
            XCTAssertEqual(d3.dosageMg, 4000, "Heavy adults should get 4000 IU D3")
        }
    }

    // MARK: - Catalog Signal Infrastructure

    func testCatalogLoadsStaticSignals() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()

        XCTAssertFalse(catalog.allPersonalizationSignals.isEmpty, "Static catalog should have personalization signals")
    }

    func testCatalogSignalLookupByField() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()

        let dietSignals = catalog.personalizationSignals(forField: "diet_type")
        XCTAssertFalse(dietSignals.isEmpty, "Should have diet_type signals")
    }

    func testCatalogDoseRangeLookup() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()

        let range = catalog.doseRange(for: "Magnesium Glycinate")
        XCTAssertNotNil(range, "Should have dose range for Magnesium")
        XCTAssertEqual(range?.low, 200)
        XCTAssertEqual(range?.high, 400)
    }

    // MARK: - Name Matcher

    func testNameMatcherExact() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()

        let results = SupplementNameMatcher.match(userSupplements: ["Magnesium Glycinate"], catalog: catalog)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.catalogName, "Magnesium Glycinate")
        XCTAssertEqual(results.first?.matchType, .exact)
    }

    func testNameMatcherFormVariant() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()

        let results = SupplementNameMatcher.match(userSupplements: ["magnesium oxide"], catalog: catalog)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.catalogName, "Magnesium Glycinate")
        XCTAssertEqual(results.first?.matchType, .formVariant)
    }

    // MARK: - Change 1: Goal Weight Corrections

    func testMelatoninSleepWeightCorrected() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        XCTAssertEqual(catalog.weight(for: "Melatonin", goal: "sleep"), 3,
                       "Melatonin sleep weight should be 3 (corrected from 2)")
    }

    func testBComplexEnergyWeightCorrected() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        XCTAssertEqual(catalog.weight(for: "Vitamin B Complex", goal: "energy"), 2,
                       "B Complex energy weight should be 2 (corrected from 3)")
    }

    func testAshwagandhaStressWeightCorrected() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        XCTAssertEqual(catalog.weight(for: "Ashwagandha KSM-66", goal: "stress_anxiety"), 3,
                       "Ashwagandha stress weight should be 3 (corrected from 2)")
    }

    func testCoQ10HeartWeightCorrected() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        XCTAssertEqual(catalog.weight(for: "CoQ10", goal: "heart_health"), 2,
                       "CoQ10 heart weight should be 2 (corrected from 3)")
    }

    // MARK: - Changes 2+3: Tier-Aware Selection

    func testNoCategoryCap() {
        // With many goals, the scoring system naturally selects without category limits
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .immunity, .gutHealth, .skinHairNails]
        let plan = engine.generatePlan(for: profile)

        // Verify the plan runs correctly and produces a valid plan
        // The key is that no category-based filtering is applied
        XCTAssertGreaterThanOrEqual(plan.supplements.count, 3,
                                    "Plans should have at least 3 supplements without category cap blocking")
        // Check that category diversity emerges naturally (not forced)
        let categories = Set(plan.supplements.map(\.category))
        XCTAssertGreaterThanOrEqual(categories.count, 2,
                                    "Natural scoring should produce diverse categories")
    }

    func testMultiGoalPlanHasMinimumHighTier() {
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy, .focus]
        let plan = engine.generatePlan(for: profile)

        let highTier = plan.supplements.filter { $0.tier == .core || $0.tier == .targeted }
        XCTAssertGreaterThanOrEqual(highTier.count, 2,
                                    "Multi-goal plans should have ≥2 Core+Targeted supplements")
    }

    func testSingleGoalPlanHasMinimumHighTier() {
        var profile = UserProfile()
        profile.healthGoals = [.skinHairNails]
        let plan = engine.generatePlan(for: profile)

        let highTier = plan.supplements.filter { $0.tier == .core || $0.tier == .targeted }
        XCTAssertGreaterThanOrEqual(highTier.count, 2,
                                    "Single-goal plans should get ≥2 Core+Targeted via promotion")
    }

    // MARK: - Change 7: Iron Safety Guardrails

    func testMaleNoExemptionsNoIron() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .male
        profile.dietType = .omnivore
        profile.exerciseFrequency = .oneToTwo
        let plan = engine.generatePlan(for: profile)

        XCTAssertFalse(
            plan.supplements.contains { $0.name == "Iron" },
            "Males without exemptions should not get Iron"
        )
    }

    func testMaleVeganGetsIron() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .male
        profile.dietType = .vegan
        let plan = engine.generatePlan(for: profile)

        // Iron should not be excluded (vegan exemption)
        let excluded = engine.findExcludedSupplements(profile: profile)
        XCTAssertFalse(excluded.contains("Iron"),
                       "Male vegan should be exempt from iron guardrail")
    }

    func testMaleHighExerciseGetsIron() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .male
        profile.exerciseFrequency = .fivePlus
        let plan = engine.generatePlan(for: profile)

        let excluded = engine.findExcludedSupplements(profile: profile)
        XCTAssertFalse(excluded.contains("Iron"),
                       "Male with 5+/week exercise should be exempt from iron guardrail")
    }

    func testFemaleVeganIronBoosted() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .female
        profile.dietType = .vegan
        profile.age = 30
        let plan = engine.generatePlan(for: profile)

        // Iron should be in the plan — vegan diet (+2) and age 18-50 (+1) boost it
        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Iron" },
            "Female vegan should have Iron in plan (diet + age boosts)"
        )
    }

    func testMultivitaminUserGetsIronOverlapNote() {
        var profile = UserProfile()
        profile.healthGoals = [.energy]
        profile.sex = .female
        profile.currentSupplements = ["Centrum Silver"]
        let plan = engine.generatePlan(for: profile)

        if let iron = plan.supplements.first(where: { $0.name == "Iron" }) {
            let note = iron.interactionNote ?? ""
            XCTAssertTrue(note.contains("multivitamin"),
                          "Iron should have multivitamin overlap warning")
        }
    }

    // MARK: - Change 4: Deep Profile Signals

    func testBirthControlBoostsBComplexAndMagnesium() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        let deepModules = [
            DeepProfileModule(
                moduleId: .hormonalMetabolic,
                responses: ["hormonal_birth_control_hrt": .string("birth_control")]
            )
        ]
        let engine = RecommendationEngine(catalog: catalog, deepProfileModules: deepModules)
        var profile = UserProfile()
        profile.healthGoals = [.energy, .sleep]
        let plan = engine.generatePlan(for: profile)

        let names = plan.supplements.map(\.name)
        XCTAssertTrue(names.contains("Vitamin B Complex") || names.contains("Magnesium Glycinate"),
                      "Birth control user should have B Complex or Magnesium boosted")
    }

    func testGutModulePPIBoostsMinerals() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        let deepModules = [
            DeepProfileModule(
                moduleId: .gutHealth,
                responses: ["gut_ppi_usage": .string("yes_currently")]
            )
        ]
        let engine = RecommendationEngine(catalog: catalog, deepProfileModules: deepModules)
        var profile = UserProfile()
        profile.healthGoals = [.energy, .sleep]
        // No PPI in medications list
        let plan = engine.generatePlan(for: profile)

        let names = plan.supplements.map(\.name)
        XCTAssertTrue(names.contains("Magnesium Glycinate") || names.contains("Vitamin B Complex"),
                      "Gut module PPI user should get Magnesium or B Complex boosted")
    }

    func testSleepOnsetBoostsMelatonin() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        let deepModules = [
            DeepProfileModule(
                moduleId: .sleepCircadian,
                responses: ["sleep_onset_latency": .string("over_60")]
            )
        ]
        let engine = RecommendationEngine(catalog: catalog, deepProfileModules: deepModules)
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        let plan = engine.generatePlan(for: profile)

        // Melatonin should be in the plan — the +2 boost from sleep onset helps it rank higher
        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Melatonin" },
            "Melatonin should be in plan for sleep goal with high onset latency"
        )
        // With the sleep goal weight (3) + onset boost (+2), Melatonin should be core or targeted tier
        if let melatonin = plan.supplements.first(where: { $0.name == "Melatonin" }) {
            XCTAssertTrue(melatonin.tier == .core || melatonin.tier == .targeted,
                          "Sleep onset boost should push Melatonin to core or targeted tier")
        }
    }

    func testSleepMaintenanceBoostsMagnesium() {
        let catalog = SupplementCatalog()
        catalog.populateFromStatic()
        let deepModules = [
            DeepProfileModule(
                moduleId: .sleepCircadian,
                responses: ["sleep_wake_frequency": .string("three_plus")]
            )
        ]
        let engine = RecommendationEngine(catalog: catalog, deepProfileModules: deepModules)
        var profile = UserProfile()
        profile.healthGoals = [.sleep]
        let plan = engine.generatePlan(for: profile)

        XCTAssertTrue(
            plan.supplements.contains { $0.name == "Magnesium Glycinate" },
            "Sleep waking 3+ should boost Magnesium"
        )
    }

    func testNoDeepProfileEngineRunsNormally() {
        // This verifies existing behavior still works with no deep profile modules
        var profile = UserProfile()
        profile.healthGoals = [.sleep, .energy]
        let plan = engine.generatePlan(for: profile)

        XCTAssertGreaterThanOrEqual(plan.supplements.count, 3)
        XCTAssertTrue(plan.supplements.contains { $0.name == "Magnesium Glycinate" })
    }

    // MARK: - Change 5: Timing Conflicts

    func testTimingConflictsNocrash() {
        // Profile that would produce both Iron and Zinc
        var profile = UserProfile()
        profile.healthGoals = [.energy, .immunity]
        profile.sex = .female
        let plan = engine.generatePlan(for: profile)

        // Should not crash; plan should still be valid
        XCTAssertGreaterThanOrEqual(plan.supplements.count, 3)
    }

    func testDifferentTimingsNoSpuriousConflictNotes() {
        // Iron (emptyStomach) and Zinc (evening) already have different timings
        var profile = UserProfile()
        profile.healthGoals = [.energy, .immunity, .skinHairNails]
        profile.sex = .female
        let plan = engine.generatePlan(for: profile)

        // If both are in the plan, they should not get spurious conflict notes
        // since they already have different timings
        if let iron = plan.supplements.first(where: { $0.name == "Iron" }),
           let zinc = plan.supplements.first(where: { $0.name == "Zinc" }) {
            // Iron is emptyStomach, Zinc is evening — different timings → no conflict note
            if iron.timing != zinc.timing {
                let ironNote = iron.interactionNote ?? ""
                XCTAssertFalse(ironNote.contains("absorption conflict with Zinc"),
                               "Different timings should not produce spurious conflict notes")
            }
        }
    }

    // MARK: - Change 6: What To Look For Copy

    func testVeganWhatToLookForMentionsPlantBased() {
        var profile = UserProfile()
        profile.healthGoals = [.energy, .sleep]
        profile.dietType = .vegan
        let plan = engine.generatePlan(for: profile)

        if let bComplex = plan.supplements.first(where: { $0.name == "Vitamin B Complex" }) {
            let lookFor = bComplex.whatToLookFor ?? ""
            XCTAssertTrue(lookFor.contains("plant-based") || lookFor.contains("B12"),
                          "Vegan B Complex whatToLookFor should mention plant-based guidance")
        }
    }

    func testMultipleSignalsLimitedToTwo() {
        // Create a profile that fires many signals for the same supplement
        var profile = UserProfile()
        profile.healthGoals = [.energy, .sleep]
        profile.dietType = .vegan
        profile.stressLevel = .veryHigh
        profile.baselineEnergy = 2
        let plan = engine.generatePlan(for: profile)

        if let bComplex = plan.supplements.first(where: { $0.name == "Vitamin B Complex" }) {
            let lookFor = bComplex.whatToLookFor ?? ""
            // Count signal-based sentences (those from signalCopyMap)
            // They should be appended after the template text; we verify the text isn't excessively long
            // The base template plus 2 signal sentences should be reasonable
            XCTAssertLessThan(lookFor.count, 600,
                              "What to look for text should be bounded (max 2 signal sentences)")
        }
    }
}
