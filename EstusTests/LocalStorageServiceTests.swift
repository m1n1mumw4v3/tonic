import XCTest
@testable import Estus

final class LocalStorageServiceTests: XCTestCase {

    private var sut: LocalStorageService!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "TestSuite-\(UUID().uuidString)"
        sut = LocalStorageService()
        // Clear any residual test data by using the standard defaults
        // (We operate on the app's UserDefaults since LocalStorageService uses .standard)
        clearTestKeys()
    }

    override func tearDown() {
        clearTestKeys()
        sut = nil
        super.tearDown()
    }

    private func clearTestKeys() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "estus_user_profile")
        defaults.removeObject(forKey: "estus_active_plan")
        defaults.removeObject(forKey: "estus_check_ins")
        defaults.removeObject(forKey: "estus_streak")
        defaults.removeObject(forKey: "estus_insights")
        defaults.removeObject(forKey: "estus_deep_profile")
    }

    // MARK: - Profile

    func testSaveAndRetrieveProfile() throws {
        var profile = UserProfile()
        profile.firstName = "Test"
        profile.healthGoals = [.sleep, .energy]

        try sut.saveProfile(profile)
        let retrieved = try sut.getProfile()

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.firstName, "Test")
        XCTAssertEqual(retrieved?.healthGoals, [.sleep, .energy])
    }

    func testGetProfileReturnsNilWhenEmpty() throws {
        let profile = try sut.getProfile()
        XCTAssertNil(profile)
    }

    // MARK: - Plan

    func testSaveAndRetrievePlan() throws {
        let plan = SupplementPlan()
        try sut.savePlan(plan)

        let retrieved = try sut.getActivePlan()
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.id, plan.id)
    }

    func testGetPlanReturnsNilWhenEmpty() throws {
        let plan = try sut.getActivePlan()
        XCTAssertNil(plan)
    }

    // MARK: - Check-Ins

    func testSaveAndRetrieveCheckIn() throws {
        var checkIn = DailyCheckIn()
        checkIn.sleepScore = 8
        checkIn.energyScore = 7

        try sut.saveCheckIn(checkIn)
        let checkIns = try sut.getCheckIns(limit: nil)

        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.sleepScore, 8)
        XCTAssertEqual(checkIns.first?.energyScore, 7)
    }

    func testCheckInUpsertReplacesExistingForSameDay() throws {
        var checkIn1 = DailyCheckIn()
        checkIn1.sleepScore = 5
        try sut.saveCheckIn(checkIn1)

        // Save another check-in for today — should replace, not append
        var checkIn2 = DailyCheckIn()
        checkIn2.sleepScore = 9
        try sut.saveCheckIn(checkIn2)

        let checkIns = try sut.getCheckIns(limit: nil)
        XCTAssertEqual(checkIns.count, 1, "Should upsert, not duplicate")
        XCTAssertEqual(checkIns.first?.sleepScore, 9, "Should have the updated score")
    }

    func testCheckInsSortedDescendingByDate() throws {
        let cal = Calendar.current
        let today = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var checkIn1 = DailyCheckIn()
        checkIn1.checkInDate = yesterday
        checkIn1.sleepScore = 3

        var checkIn2 = DailyCheckIn()
        checkIn2.checkInDate = today
        checkIn2.sleepScore = 8

        try sut.saveCheckIn(checkIn1)
        try sut.saveCheckIn(checkIn2)

        let checkIns = try sut.getCheckIns(limit: nil)
        XCTAssertEqual(checkIns.count, 2)
        // Most recent first
        XCTAssertEqual(checkIns.first?.sleepScore, 8)
        XCTAssertEqual(checkIns.last?.sleepScore, 3)
    }

    func testCheckInsLimitReturnsCorrectCount() throws {
        let cal = Calendar.current
        for i in 0..<5 {
            var checkIn = DailyCheckIn()
            checkIn.checkInDate = cal.date(byAdding: .day, value: -i, to: Date())!
            checkIn.sleepScore = i
            try sut.saveCheckIn(checkIn)
        }

        let limited = try sut.getCheckIns(limit: 3)
        XCTAssertEqual(limited.count, 3)
    }

    func testGetTodayCheckInReturnsTodaysOnly() throws {
        let cal = Calendar.current

        var yesterdayCheckIn = DailyCheckIn()
        yesterdayCheckIn.checkInDate = cal.date(byAdding: .day, value: -1, to: Date())!
        yesterdayCheckIn.sleepScore = 3

        var todayCheckIn = DailyCheckIn()
        todayCheckIn.sleepScore = 9

        try sut.saveCheckIn(yesterdayCheckIn)
        try sut.saveCheckIn(todayCheckIn)

        let today = try sut.getTodayCheckIn()
        XCTAssertNotNil(today)
        XCTAssertEqual(today?.sleepScore, 9)
    }

    func testCheckIn90DayTrimRemovesOldEntries() throws {
        let cal = Calendar.current

        // Save a check-in from 91 days ago
        var oldCheckIn = DailyCheckIn()
        oldCheckIn.checkInDate = cal.date(byAdding: .day, value: -91, to: Date())!
        oldCheckIn.sleepScore = 1
        try sut.saveCheckIn(oldCheckIn)

        // Save today's check-in — this triggers the trim
        var todayCheckIn = DailyCheckIn()
        todayCheckIn.sleepScore = 8
        try sut.saveCheckIn(todayCheckIn)

        let checkIns = try sut.getCheckIns(limit: nil)
        // The 91-day-old check-in should be trimmed
        XCTAssertEqual(checkIns.count, 1)
        XCTAssertEqual(checkIns.first?.sleepScore, 8)
    }

    // MARK: - Streak

    func testGetStreakReturnsDefaultWhenEmpty() throws {
        let streak = try sut.getStreak()
        XCTAssertEqual(streak.currentStreak, 0)
    }

    func testSaveAndRetrieveStreak() throws {
        var streak = UserStreak()
        streak.currentStreak = 7
        try sut.saveStreak(streak)

        let retrieved = try sut.getStreak()
        XCTAssertEqual(retrieved.currentStreak, 7)
    }

    // MARK: - Insights

    func testGetInsightsReturnsEmptyWhenNone() throws {
        let insights = try sut.getInsights()
        XCTAssertTrue(insights.isEmpty)
    }

    // MARK: - Deep Profile

    func testDeepProfileModuleUpsertByType() throws {
        let module1 = DeepProfileModule(
            moduleId: .sleepCircadian,
            responses: ["test": .string("value1")]
        )
        try sut.saveDeepProfileModule(module1)

        // Save same module type with different data — should replace
        let module2 = DeepProfileModule(
            moduleId: .sleepCircadian,
            responses: ["test": .string("value2")]
        )
        try sut.saveDeepProfileModule(module2)

        let modules = try sut.getDeepProfileModules()
        XCTAssertEqual(modules.count, 1, "Should upsert, not duplicate")
        XCTAssertEqual(modules.first?.responses["test"], .string("value2"))
    }

    func testDeleteDeepProfileModule() throws {
        let module = DeepProfileModule(
            moduleId: .sleepCircadian,
            responses: [:]
        )
        try sut.saveDeepProfileModule(module)

        try sut.deleteDeepProfileModule(.sleepCircadian)

        let modules = try sut.getDeepProfileModules()
        XCTAssertTrue(modules.isEmpty)
    }
}
