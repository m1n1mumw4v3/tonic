import XCTest
@testable import Estus

// MARK: - Mock DataStore

final class MockDataStore: DataStore {
    var storedProfile: UserProfile?
    var storedPlan: SupplementPlan?
    var storedCheckIns: [DailyCheckIn] = []
    var storedStreak: UserStreak = UserStreak()
    var storedInsights: [Insight] = []
    var storedDeepProfileModules: [DeepProfileModule] = []

    func saveProfile(_ profile: UserProfile) throws { storedProfile = profile }
    func getProfile() throws -> UserProfile? { storedProfile }

    func savePlan(_ plan: SupplementPlan) throws { storedPlan = plan }
    func getActivePlan() throws -> SupplementPlan? { storedPlan }

    func saveCheckIn(_ checkIn: DailyCheckIn) throws {
        if let index = storedCheckIns.firstIndex(where: {
            Calendar.current.isDate($0.checkInDate, inSameDayAs: checkIn.checkInDate)
        }) {
            storedCheckIns[index] = checkIn
        } else {
            storedCheckIns.append(checkIn)
        }
    }

    func getCheckIns(limit: Int?) throws -> [DailyCheckIn] {
        let sorted = storedCheckIns.sorted { $0.checkInDate > $1.checkInDate }
        if let limit = limit {
            return Array(sorted.prefix(limit))
        }
        return sorted
    }

    func getTodayCheckIn() throws -> DailyCheckIn? {
        storedCheckIns.first { Calendar.current.isDateInToday($0.checkInDate) }
    }

    func saveStreak(_ streak: UserStreak) throws { storedStreak = streak }
    func getStreak() throws -> UserStreak { storedStreak }

    func saveInsights(_ insights: [Insight]) throws { storedInsights = insights }
    func getInsights() throws -> [Insight] { storedInsights }

    func saveDeepProfileModule(_ module: DeepProfileModule) throws {
        storedDeepProfileModules.removeAll { $0.moduleId == module.moduleId }
        storedDeepProfileModules.append(module)
    }

    func getDeepProfileModules() throws -> [DeepProfileModule] { storedDeepProfileModules }

    func deleteDeepProfileModule(_ moduleId: DeepProfileModuleType) throws {
        storedDeepProfileModules.removeAll { $0.moduleId == moduleId }
    }
}

// MARK: - Tests

final class TodayViewModelTests: XCTestCase {

    private var mockStore: MockDataStore!
    private var sut: TodayViewModel!

    override func setUp() {
        super.setUp()
        mockStore = MockDataStore()
        sut = TodayViewModel(dataStore: mockStore)
    }

    override func tearDown() {
        sut = nil
        mockStore = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makePlan(timings: [SupplementTiming] = [.morning, .evening]) -> SupplementPlan {
        var plan = SupplementPlan()
        plan.supplements = timings.enumerated().map { index, timing in
            PlanSupplement(
                name: "Supplement \(index + 1)",
                dosage: "\(index + 1)00mg",
                timing: timing
            )
        }
        return plan
    }

    // MARK: - Supplement Initialization

    func testInitializeSupplementsSetsAllToFalse() {
        let plan = makePlan()
        sut.initializeSupplements(from: plan)

        for supplement in plan.supplements {
            XCTAssertEqual(sut.supplementStates[supplement.id], false)
        }
    }

    func testInitializeSupplementsFromExistingCheckIn() {
        let plan = makePlan()
        let takenId = plan.supplements[0].id

        let checkIn = DailyCheckIn(
            supplementLogs: [
                SupplementLog(planSupplementId: takenId, taken: true),
                SupplementLog(planSupplementId: plan.supplements[1].id, taken: false),
            ]
        )

        sut.initializeSupplements(from: plan, existingCheckIn: checkIn)

        XCTAssertEqual(sut.supplementStates[takenId], true)
        XCTAssertEqual(sut.supplementStates[plan.supplements[1].id], false)
    }

    func testInitializeSupplementsIgnoresRemovedSupplements() {
        var plan = SupplementPlan()
        var removedSupp = PlanSupplement(name: "Removed", dosage: "100mg", timing: .morning)
        removedSupp.isRemoved = true
        let activeSupp = PlanSupplement(name: "Active", dosage: "200mg", timing: .morning)
        plan.supplements = [removedSupp, activeSupp]

        sut.initializeSupplements(from: plan)

        // Removed supplement should not have a state entry
        XCTAssertNil(sut.supplementStates[removedSupp.id])
        XCTAssertEqual(sut.supplementStates[activeSupp.id], false)
    }

    func testInitializeSupplementsWithNilPlan() {
        sut.initializeSupplements(from: nil)
        XCTAssertTrue(sut.supplementStates.isEmpty)
    }

    // MARK: - Supplement Toggling

    func testToggleSupplementFlipsState() {
        let plan = makePlan(timings: [.morning])
        let appState = AppState()
        appState.activePlan = plan
        appState.todayCheckIn = DailyCheckIn(wellbeingCompleted: false)

        sut.initializeSupplements(from: plan)
        let suppId = plan.supplements[0].id

        XCTAssertEqual(sut.supplementStates[suppId], false)
        sut.toggleSupplement(suppId, appState: appState)
        XCTAssertEqual(sut.supplementStates[suppId], true)
        sut.toggleSupplement(suppId, appState: appState)
        XCTAssertEqual(sut.supplementStates[suppId], false)
    }

    func testToggleSupplementPersistsCheckIn() {
        let plan = makePlan(timings: [.morning])
        let appState = AppState()
        appState.activePlan = plan
        appState.todayCheckIn = DailyCheckIn(wellbeingCompleted: false)

        sut.initializeSupplements(from: plan)
        sut.toggleSupplement(plan.supplements[0].id, appState: appState)

        // Check that a check-in was persisted
        XCTAssertEqual(mockStore.storedCheckIns.count, 1)
        let log = mockStore.storedCheckIns[0].supplementLogs.first {
            $0.planSupplementId == plan.supplements[0].id
        }
        XCTAssertEqual(log?.taken, true)
    }

    // MARK: - Progress Calculations

    func testAmProgressCalculation() {
        var plan = SupplementPlan()
        plan.supplements = [
            PlanSupplement(name: "S1", dosage: "100mg", timing: .morning),
            PlanSupplement(name: "S2", dosage: "200mg", timing: .morning),
            PlanSupplement(name: "S3", dosage: "300mg", timing: .evening),
        ]
        sut.initializeSupplements(from: plan)

        // 0 of 2 AM supplements taken
        XCTAssertEqual(sut.amProgress, 0.0, accuracy: 0.001)

        // Take 1 of 2 AM
        sut.supplementStates[plan.supplements[0].id] = true
        XCTAssertEqual(sut.amProgress, 0.5, accuracy: 0.001)

        // Take 2 of 2 AM
        sut.supplementStates[plan.supplements[1].id] = true
        XCTAssertEqual(sut.amProgress, 1.0, accuracy: 0.001)
    }

    func testPmProgressCalculation() {
        var plan = SupplementPlan()
        plan.supplements = [
            PlanSupplement(name: "S1", dosage: "100mg", timing: .morning),
            PlanSupplement(name: "S2", dosage: "200mg", timing: .evening),
            PlanSupplement(name: "S3", dosage: "300mg", timing: .bedtime),
        ]
        sut.initializeSupplements(from: plan)

        // 0 of 2 PM supplements taken
        XCTAssertEqual(sut.pmProgress, 0.0, accuracy: 0.001)

        // Take 1 of 2 PM
        sut.supplementStates[plan.supplements[1].id] = true
        XCTAssertEqual(sut.pmProgress, 0.5, accuracy: 0.001)
    }

    func testAmProgressWithNoAmSupplements() {
        let plan = makePlan(timings: [.evening, .bedtime])
        sut.initializeSupplements(from: plan)
        XCTAssertEqual(sut.amProgress, 0.0)
    }

    func testPmProgressWithNoPmSupplements() {
        let plan = makePlan(timings: [.morning, .withFood])
        sut.initializeSupplements(from: plan)
        XCTAssertEqual(sut.pmProgress, 0.0)
    }

    // MARK: - allTaken / takenCount

    func testAllTakenWhenAllSupplementsTaken() {
        let plan = makePlan(timings: [.morning, .evening])
        sut.initializeSupplements(from: plan)

        XCTAssertFalse(sut.allTaken)

        for supp in plan.supplements {
            sut.supplementStates[supp.id] = true
        }
        XCTAssertTrue(sut.allTaken)
    }

    func testAllTakenFalseWhenOneUntaken() {
        let plan = makePlan(timings: [.morning, .evening])
        sut.initializeSupplements(from: plan)

        sut.supplementStates[plan.supplements[0].id] = true
        // Second supplement still false
        XCTAssertFalse(sut.allTaken)
    }

    func testAllTakenFalseWhenEmpty() {
        XCTAssertFalse(sut.allTaken)
    }

    func testTakenCount() {
        let plan = makePlan(timings: [.morning, .evening, .bedtime])
        sut.initializeSupplements(from: plan)

        XCTAssertEqual(sut.takenCount, 0)

        sut.supplementStates[plan.supplements[0].id] = true
        XCTAssertEqual(sut.takenCount, 1)

        sut.supplementStates[plan.supplements[1].id] = true
        XCTAssertEqual(sut.takenCount, 2)
    }

    // MARK: - Trailing Averages

    func testLoadTrailingAveragesComputesCorrectly() {
        let cal = Calendar.current
        // Add check-ins within the last 7 days
        for i in 1...3 {
            let date = cal.date(byAdding: .day, value: -i, to: Date())!
            let checkIn = DailyCheckIn(
                checkInDate: date,
                sleepScore: i * 2,      // 2, 4, 6
                energyScore: 5,
                clarityScore: 5,
                moodScore: 5,
                gutScore: 5,
                wellbeingCompleted: true
            )
            mockStore.storedCheckIns.append(checkIn)
        }

        sut.loadTrailingAverages()

        XCTAssertEqual(sut.trailingCheckInCount, 3)
        // Sleep average: (2 + 4 + 6) / 3 = 4.0
        XCTAssertEqual(sut.trailingAverages[.sleep] ?? 0, 4.0, accuracy: 0.001)
        // Energy average: 5 + 5 + 5 / 3 = 5.0
        XCTAssertEqual(sut.trailingAverages[.energy] ?? 0, 5.0, accuracy: 0.001)
    }

    func testLoadTrailingAveragesExcludesNonWellbeingCheckIns() {
        let cal = Calendar.current
        let date = cal.date(byAdding: .day, value: -1, to: Date())!
        let checkIn = DailyCheckIn(
            checkInDate: date,
            sleepScore: 8,
            wellbeingCompleted: false  // Not a complete wellbeing check-in
        )
        mockStore.storedCheckIns.append(checkIn)

        sut.loadTrailingAverages()
        XCTAssertEqual(sut.trailingCheckInCount, 0)
        XCTAssertTrue(sut.trailingAverages.isEmpty)
    }

    // MARK: - Trailing Overall Average

    func testTrailingOverallAverageWithAllDimensions() {
        sut.trailingAverages = [
            .sleep: 6.0, .energy: 8.0, .clarity: 4.0, .mood: 7.0, .gut: 5.0
        ]
        // (6 + 8 + 4 + 7 + 5) / 5 = 6.0
        XCTAssertEqual(sut.trailingOverallAverage ?? 0, 6.0, accuracy: 0.001)
    }

    func testTrailingOverallAverageNilWhenIncomplete() {
        sut.trailingAverages = [.sleep: 6.0, .energy: 8.0]  // Missing 3 dimensions
        XCTAssertNil(sut.trailingOverallAverage)
    }

    // MARK: - Visible Supplements

    func testVisibleSupplementsExcludesRemoved() {
        var plan = SupplementPlan()
        var removed = PlanSupplement(name: "Removed", dosage: "100mg", timing: .morning)
        removed.isRemoved = true
        let active = PlanSupplement(name: "Active", dosage: "200mg", timing: .morning)
        plan.supplements = [removed, active]

        let visible = sut.visibleSupplements(for: .morning, plan: plan)
        XCTAssertEqual(visible.count, 1)
        XCTAssertEqual(visible.first?.name, "Active")
    }

    func testVisibleSupplementsReturnsEmptyForNilPlan() {
        let visible = sut.visibleSupplements(for: .morning, plan: nil)
        XCTAssertTrue(visible.isEmpty)
    }

    // MARK: - Feed

    func testDismissInsightRemovesFromFeed() {
        let insight = Insight(type: .trend, title: "Test", body: "Test body")
        mockStore.storedInsights = [insight]
        sut.insightFeed = [insight]

        sut.dismissInsight(insight.id)

        XCTAssertTrue(sut.insightFeed.isEmpty)
        // Also persisted as dismissed
        let stored = mockStore.storedInsights.first { $0.id == insight.id }
        XCTAssertTrue(stored?.isDismissed == true)
    }

    func testMarkInsightRead() {
        var insight = Insight(type: .trend, title: "Test", body: "Test body")
        insight.isRead = false
        mockStore.storedInsights = [insight]
        sut.insightFeed = [insight]

        sut.markInsightRead(insight.id)

        XCTAssertTrue(sut.insightFeed[0].isRead)
        let stored = mockStore.storedInsights.first { $0.id == insight.id }
        XCTAssertTrue(stored?.isRead == true)
    }
}
