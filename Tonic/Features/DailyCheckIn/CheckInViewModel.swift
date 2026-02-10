import SwiftUI

@Observable
class CheckInViewModel {
    private let dataStore: DataStore

    // Step 1: Wellness scores
    var sleepScore: Double = 5
    var energyScore: Double = 5
    var clarityScore: Double = 5
    var moodScore: Double = 5
    var gutScore: Double = 5

    // Step 2: Supplement states
    var supplementStates: [UUID: Bool] = [:]

    // Step 3: Completion
    var wellbeingScore: Double = 0
    var isComplete: Bool = false
    var completionInsight: CheckInInsight?

    // 7-day trailing averages
    var trailingAverages: [WellnessDimension: Double] = [:]

    // Navigation
    var currentStep: Int = 0

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    var computedWellbeingScore: Double {
        WellbeingScore.calculate(
            sleep: Int(sleepScore), energy: Int(energyScore),
            clarity: Int(clarityScore), mood: Int(moodScore), gut: Int(gutScore)
        )
    }

    func initializeSupplements(from plan: SupplementPlan?) {
        guard let plan = plan else { return }
        for supplement in plan.supplements {
            supplementStates[supplement.id] = false
        }
    }

    func toggleSupplement(_ id: UUID) {
        supplementStates[id] = !(supplementStates[id] ?? false)
        HapticManager.impact(.medium)
    }

    func takeAll(plan: SupplementPlan?) {
        guard let plan = plan else { return }
        for supplement in plan.supplements {
            supplementStates[supplement.id] = true
        }
        HapticManager.notification(.success)
    }

    var takenCount: Int {
        supplementStates.values.filter { $0 }.count
    }

    func loadTrailingAverages(from appState: AppState) {
        guard let checkIns = try? dataStore.getCheckIns(limit: 7) else { return }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        let recent = checkIns.filter { $0.checkInDate >= sevenDaysAgo }

        guard !recent.isEmpty else { return }

        let count = Double(recent.count)
        trailingAverages[.sleep] = recent.map { Double($0.sleepScore) }.reduce(0, +) / count
        trailingAverages[.energy] = recent.map { Double($0.energyScore) }.reduce(0, +) / count
        trailingAverages[.clarity] = recent.map { Double($0.clarityScore) }.reduce(0, +) / count
        trailingAverages[.mood] = recent.map { Double($0.moodScore) }.reduce(0, +) / count
        trailingAverages[.gut] = recent.map { Double($0.gutScore) }.reduce(0, +) / count
    }

    func completeCheckIn(appState: AppState) {
        wellbeingScore = computedWellbeingScore

        // Build check-in
        var checkIn = DailyCheckIn()
        checkIn.sleepScore = Int(sleepScore)
        checkIn.energyScore = Int(energyScore)
        checkIn.clarityScore = Int(clarityScore)
        checkIn.moodScore = Int(moodScore)
        checkIn.gutScore = Int(gutScore)

        // Build supplement logs
        if let plan = appState.activePlan {
            checkIn.supplementLogs = plan.supplements.map { supplement in
                SupplementLog(
                    planSupplementId: supplement.id,
                    taken: supplementStates[supplement.id] ?? false
                )
            }
        }

        // Save
        try? dataStore.saveCheckIn(checkIn)

        // Update streak
        var streak = (try? dataStore.getStreak()) ?? UserStreak()
        streak.recordCheckIn()
        try? dataStore.saveStreak(streak)

        // Update app state
        appState.todayCheckIn = checkIn
        appState.streak = streak
        appState.recentCheckIns.insert(checkIn, at: 0)

        // Generate completion insight
        let todayScores: [WellnessDimension: Int] = [
            .sleep: Int(sleepScore),
            .energy: Int(energyScore),
            .clarity: Int(clarityScore),
            .mood: Int(moodScore),
            .gut: Int(gutScore),
        ]

        let takenSupplements: [(name: String, id: UUID)] = {
            guard let plan = appState.activePlan else { return [] }
            return plan.supplements.compactMap { supplement in
                guard supplementStates[supplement.id] == true else { return nil }
                return (name: supplement.name, id: supplement.id)
            }
        }()

        let context = CheckInInsightGenerator.Context(
            todayScores: todayScores,
            baselines: Self.baselines(from: appState.currentUser),
            trailingAverages: trailingAverages,
            recentCheckIns: Array(appState.recentCheckIns.dropFirst()), // exclude today's just-inserted entry
            streak: streak,
            supplementsTakenToday: takenSupplements,
            plan: appState.activePlan,
            recentlyShownKeys: RecentInsightTracker.recentKeys()
        )

        let insight = CheckInInsightGenerator().generate(from: context)
        completionInsight = insight
        if let key = insight?.key {
            RecentInsightTracker.record(key)
        }

        isComplete = true
        HapticManager.notification(.success)
    }

    private static func baselines(from profile: UserProfile?) -> [WellnessDimension: Int] {
        guard let profile = profile else {
            return Dictionary(uniqueKeysWithValues: WellnessDimension.allCases.map { ($0, 5) })
        }
        return [
            .sleep: profile.baselineSleep,
            .energy: profile.baselineEnergy,
            .clarity: profile.baselineClarity,
            .mood: profile.baselineMood,
            .gut: profile.baselineGut,
        ]
    }
}
