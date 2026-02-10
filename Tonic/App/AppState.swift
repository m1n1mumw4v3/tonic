import SwiftUI

@Observable
class AppState {
    var isOnboardingComplete: Bool = false
    var isSubscribed: Bool = false
    var currentUser: UserProfile?
    var activePlan: SupplementPlan?
    var streak: UserStreak = UserStreak()
    var todayCheckIn: DailyCheckIn?
    var recentCheckIns: [DailyCheckIn] = []
    var insights: [Insight] = []

    // Navigation
    var selectedTab: AppTab = .home
    var showCheckInFlow: Bool = false

    // Computed
    var userName: String {
        currentUser?.firstName ?? "there"
    }

    var hasCheckedInToday: Bool {
        guard let checkIn = todayCheckIn else { return false }
        return Calendar.current.isDateInToday(checkIn.checkInDate)
    }

    var hasEverCheckedIn: Bool {
        !recentCheckIns.isEmpty
    }

    var todayWellbeingScore: Double? {
        todayCheckIn?.wellbeingScore
    }
}

enum AppTab: Int, CaseIterable {
    case home = 0
    case plan
    case progress
    case settings

    var label: String {
        switch self {
        case .home: return "Home"
        case .plan: return "Plan"
        case .progress: return "Progress"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .plan: return "pill.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .settings: return "gearshape.fill"
        }
    }
}
