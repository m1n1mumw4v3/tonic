import XCTest
@testable import Estus

final class CheckInInsightGeneratorTests: XCTestCase {

    private let generator = CheckInInsightGenerator()

    // MARK: - Helpers

    private func makeContext(
        todayScores: [WellnessDimension: Int] = [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
        baselines: [WellnessDimension: Int] = [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
        trailingAverages: [WellnessDimension: Double] = [:],
        recentCheckIns: [DailyCheckIn] = [],
        streak: UserStreak = UserStreak(),
        supplementsTakenToday: [(name: String, id: UUID)] = [],
        plan: SupplementPlan? = nil,
        recentlyShownKeys: Set<String> = [],
        catalog: SupplementCatalog? = nil
    ) -> CheckInInsightGenerator.Context {
        CheckInInsightGenerator.Context(
            todayScores: todayScores,
            baselines: baselines,
            trailingAverages: trailingAverages,
            recentCheckIns: recentCheckIns,
            streak: streak,
            supplementsTakenToday: supplementsTakenToday,
            plan: plan,
            recentlyShownKeys: recentlyShownKeys,
            catalog: catalog
        )
    }

    private func makeCheckIn(
        daysAgo: Int = 0,
        sleep: Int = 5, energy: Int = 5, clarity: Int = 5, mood: Int = 5, gut: Int = 5,
        supplementLogs: [SupplementLog] = []
    ) -> DailyCheckIn {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        return DailyCheckIn(
            checkInDate: date,
            sleepScore: sleep,
            energyScore: energy,
            clarityScore: clarity,
            moodScore: mood,
            gutScore: gut,
            wellbeingCompleted: true,
            supplementLogs: supplementLogs
        )
    }

    // MARK: - Always Returns an Insight

    func testGenerateAlwaysReturnsAnInsight() {
        let context = makeContext()
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight, "Generator should always produce at least a generic fallback")
    }

    // MARK: - Generic Fallback

    func testGenericFallbackWhenNoRulesMatch() {
        let context = makeContext()
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.key.hasPrefix("generic_"), "Should produce a generic fallback")
    }

    // MARK: - Personal Best (Rule 1)

    func testPersonalBestDetected() {
        let history = (0..<4).map { makeCheckIn(daysAgo: $0 + 1, sleep: 5) }
        let context = makeContext(
            todayScores: [.sleep: 9, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            recentCheckIns: history
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.key, "pb_sleep")
        XCTAssertTrue(insight!.message.contains("Personal best"))
    }

    func testPersonalBestRequiresMinimumHistory() {
        // Only 2 check-ins — personal best needs >= 3
        let history = [makeCheckIn(daysAgo: 1, sleep: 5), makeCheckIn(daysAgo: 2, sleep: 5)]
        let context = makeContext(
            todayScores: [.sleep: 9, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            recentCheckIns: history
        )
        let insight = generator.generate(from: context)
        // Should NOT be a personal best
        XCTAssertNotEqual(insight?.key, "pb_sleep")
    }

    // MARK: - Above Baseline (Rule 3)

    func testAboveBaselineDetected() {
        let context = makeContext(
            todayScores: [.sleep: 8, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.key, "above_baseline_sleep")
    }

    func testAboveBaselineRequiresMinimumDelta() {
        // Only 1 point above — needs >= 2
        let context = makeContext(
            todayScores: [.sleep: 6, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotEqual(insight?.key, "above_baseline_sleep")
    }

    // MARK: - Above Trailing Average (Rule 4)

    func testAboveTrailingAverageDetected() {
        // Set baselines equal to today's scores so above_baseline (Rule 3) doesn't fire first
        let context = makeContext(
            todayScores: [.sleep: 5, .energy: 8, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 5, .energy: 8, .clarity: 5, .mood: 5, .gut: 5],
            trailingAverages: [.energy: 5.0]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.key, "above_avg_energy")
    }

    func testAboveTrailingAverageRequiresMinimumDelta() {
        // Only 1 point above — needs >= 1.5
        let context = makeContext(
            todayScores: [.sleep: 5, .energy: 6, .clarity: 5, .mood: 5, .gut: 5],
            trailingAverages: [.energy: 5.0]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotEqual(insight?.key, "above_avg_energy")
    }

    // MARK: - Consecutive Improvement (Rule 5)

    func testConsecutiveImprovementDetected() {
        // Today: 8 sleep, yesterday: 6, day before: 4 → 3-day improvement streak
        // Set baselines to match today so above_baseline doesn't fire first
        let history = [
            makeCheckIn(daysAgo: 1, sleep: 6),
            makeCheckIn(daysAgo: 2, sleep: 4),
        ]
        let context = makeContext(
            todayScores: [.sleep: 8, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 8, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            recentCheckIns: history
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.key.hasPrefix("improving_sleep_"))
    }

    // MARK: - Full Adherence (Rule 6)

    func testFullAdherenceDetected() {
        let suppId1 = UUID()
        let suppId2 = UUID()

        var plan = SupplementPlan()
        plan.supplements = [
            PlanSupplement(id: suppId1, name: "Vitamin D", dosage: "2000 IU", timing: .morning),
            PlanSupplement(id: suppId2, name: "Magnesium", dosage: "400mg", timing: .evening),
        ]

        let context = makeContext(
            supplementsTakenToday: [
                (name: "Vitamin D", id: suppId1),
                (name: "Magnesium", id: suppId2),
            ],
            plan: plan
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertEqual(insight?.key, "full_adherence")
    }

    func testFullAdherenceRequiresAtLeastTwoSupplements() {
        let suppId = UUID()
        var plan = SupplementPlan()
        plan.supplements = [
            PlanSupplement(id: suppId, name: "Vitamin D", dosage: "2000 IU", timing: .morning),
        ]

        let context = makeContext(
            supplementsTakenToday: [(name: "Vitamin D", id: suppId)],
            plan: plan
        )
        let insight = generator.generate(from: context)
        XCTAssertNotEqual(insight?.key, "full_adherence")
    }

    // MARK: - Deduplication

    func testRecentlyShownKeySkipped() {
        // Above baseline would trigger, but key is in recently shown
        let context = makeContext(
            todayScores: [.sleep: 8, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            recentlyShownKeys: ["above_baseline_sleep"]
        )
        let insight = generator.generate(from: context)
        // Should skip the above_baseline_sleep and fall through to something else
        XCTAssertNotEqual(insight?.key, "above_baseline_sleep")
    }

    func testGenericFallbackBypassesFreshnessFilter() {
        // All rules filtered out → should still get generic fallback
        let context = makeContext(
            recentlyShownKeys: ["above_baseline_sleep", "above_avg_sleep"]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        XCTAssertTrue(insight!.key.hasPrefix("generic_"))
    }

    // MARK: - Fun Fact (Rule 7)

    func testSupplementFunFactForKnownSupplement() {
        let suppId = UUID()
        let context = makeContext(
            supplementsTakenToday: [(name: "Magnesium Glycinate", id: suppId)]
        )
        let insight = generator.generate(from: context)
        XCTAssertNotNil(insight)
        // Fun fact or generic — depends on rule priority
        // Supplement consistency won't fire (no history), above baseline won't fire (no delta)
        // Fun fact should fire since supplement is in the known list
        XCTAssertTrue(insight!.key.hasPrefix("fun_fact_magnesium_glycinate"))
    }

    // MARK: - Rule Priority

    func testPersonalBestTakesPriorityOverAboveBaseline() {
        // Both personal best and above baseline would match for sleep=9, baseline=5
        let history = (0..<4).map { makeCheckIn(daysAgo: $0 + 1, sleep: 5) }
        let context = makeContext(
            todayScores: [.sleep: 9, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            baselines: [.sleep: 5, .energy: 5, .clarity: 5, .mood: 5, .gut: 5],
            recentCheckIns: history
        )
        let insight = generator.generate(from: context)
        // Personal best (Rule 1) should fire before above baseline (Rule 3)
        XCTAssertEqual(insight?.key, "pb_sleep")
    }
}
