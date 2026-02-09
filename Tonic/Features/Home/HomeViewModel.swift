import SwiftUI

@Observable
class HomeViewModel {
    private let dataStore: DataStore

    var greeting: String = ""
    var userName: String = ""
    var dateLabel: String = ""
    var streak: UserStreak = UserStreak()
    var todayCheckIn: DailyCheckIn?
    var activePlan: SupplementPlan?
    var supplementStates: [UUID: Bool] = [:]
    var latestInsight: Insight?

    var hasCheckedInToday: Bool {
        guard let checkIn = todayCheckIn else { return false }
        return Calendar.current.isDateInToday(checkIn.checkInDate)
    }

    var takenCount: Int {
        supplementStates.values.filter { $0 }.count
    }

    var totalSupplements: Int {
        activePlan?.supplements.count ?? 0
    }

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    func load(appState: AppState) {
        userName = appState.userName
        greeting = "\(Date().greetingPrefix), \(userName)"
        dateLabel = Date().monoDateLabel

        // Load from AppState (which may be populated from local storage)
        activePlan = appState.activePlan
        todayCheckIn = appState.todayCheckIn
        streak = appState.streak

        // Initialize supplement states from today's check-in
        if let plan = activePlan {
            for supplement in plan.supplements {
                if let checkIn = todayCheckIn {
                    supplementStates[supplement.id] = checkIn.supplementLogs.first(where: { $0.planSupplementId == supplement.id })?.taken ?? false
                } else {
                    supplementStates[supplement.id] = false
                }
            }
        }

        // Load latest insight
        if let insights = try? dataStore.getInsights(), let latest = insights.first(where: { !$0.isDismissed }) {
            latestInsight = latest
        }
    }

    func toggleSupplement(_ id: UUID) {
        supplementStates[id] = !(supplementStates[id] ?? false)
    }

    func takeAll() {
        guard let plan = activePlan else { return }
        for supplement in plan.supplements {
            supplementStates[supplement.id] = true
        }
        HapticManager.notification(.success)
    }
}
