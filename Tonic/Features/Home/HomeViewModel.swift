import SwiftUI

@Observable
class HomeViewModel {
    private let dataStore: DataStore

    var greeting: String = ""
    var userName: String = ""
    var dateLabel: String = ""
    var streak: UserStreak = UserStreak()
    var todayCheckIn: DailyCheckIn?
    var insightFeed: [Insight] = []
    var discoveryTips: [DiscoveryTip] = []

    var hasCheckedInToday: Bool {
        guard let checkIn = todayCheckIn else { return false }
        return Calendar.current.isDateInToday(checkIn.checkInDate)
    }

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    func load(appState: AppState, kb: KnowledgeBaseProvider) {
        userName = appState.userName
        greeting = "\(Date().greetingPrefix), \(userName)"
        dateLabel = Date().monoDateLabel

        todayCheckIn = appState.todayCheckIn
        streak = appState.streak

        // Load insight feed — non-dismissed, up to 3
        let allInsights = (try? dataStore.getInsights()) ?? []
        insightFeed = Array(allInsights.filter { !$0.isDismissed }.prefix(3))

        // Generate discovery tips when no real insights exist
        if insightFeed.isEmpty {
            discoveryTips = DiscoveryTipProvider.tips(for: appState.activePlan, kb: kb)
        } else {
            discoveryTips = []
        }
    }

    func dismissInsight(_ id: UUID) {
        insightFeed.removeAll { $0.id == id }

        var allInsights = (try? dataStore.getInsights()) ?? []
        if let index = allInsights.firstIndex(where: { $0.id == id }) {
            allInsights[index].isDismissed = true
            try? dataStore.saveInsights(allInsights)
        }
    }

    func markInsightRead(_ id: UUID) {
        if let feedIndex = insightFeed.firstIndex(where: { $0.id == id }), !insightFeed[feedIndex].isRead {
            insightFeed[feedIndex].isRead = true

            var allInsights = (try? dataStore.getInsights()) ?? []
            if let index = allInsights.firstIndex(where: { $0.id == id }) {
                allInsights[index].isRead = true
                try? dataStore.saveInsights(allInsights)
            }
        }
    }
}
