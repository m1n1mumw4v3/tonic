import SwiftUI

@Observable
class CheckInViewModel {
    private let dataStore: DataStore

    // Step 1: Wellness scores
    var sleepScore: Double = 50
    var energyScore: Double = 50
    var clarityScore: Double = 50
    var moodScore: Double = 50
    var gutScore: Double = 50

    // Step 2: Supplement states
    var supplementStates: [UUID: Bool] = [:]

    // Step 3: Completion
    var wellbeingScore: Int = 0
    var isComplete: Bool = false

    // Navigation
    var currentStep: Int = 0

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    var computedWellbeingScore: Int {
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

        isComplete = true
        HapticManager.notification(.success)
    }
}
