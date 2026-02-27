import XCTest
@testable import Tonic

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
}
