import SwiftUI

@Observable
class AppState {
    var isOnboardingComplete: Bool = false
    var isSubscribed: Bool = true
    var currentUser: UserProfile?
    var activePlan: SupplementPlan?
    var streak: UserStreak = UserStreak()
    var todayCheckIn: DailyCheckIn?
    var recentCheckIns: [DailyCheckIn] = []
    var insights: [Insight] = []
    var deepProfileService = DeepProfileService()

    // Supplement catalog (Supabase-backed)
    var supplementCatalog = SupplementCatalog()
    var isCatalogLoading: Bool = false
    var catalogLoadError: Error?

    // Navigation
    var selectedTab: AppTab = .today
    var showSettings: Bool = false
    var showPaywall: Bool = false

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

    var hasCompletedWellbeingToday: Bool {
        todayCheckIn?.wellbeingCompleted == true
    }

    var mostRecentWellbeingScore: DailyCheckIn? {
        recentCheckIns.first(where: { $0.wellbeingCompleted })
    }

    var isDayComplete: Bool {
        hasCheckedInToday && hasCompletedWellbeingToday && {
            guard let checkIn = todayCheckIn, let plan = activePlan else { return false }
            let active = plan.supplements.filter { !$0.isRemoved }
            return active.allSatisfy { supplement in
                checkIn.supplementLogs.contains { $0.planSupplementId == supplement.id && $0.taken }
            }
        }()
    }

    // MARK: - Supplement Catalog Loading

    func loadSupplementCatalog() async {
        isCatalogLoading = true
        catalogLoadError = nil

        do {
            let service = SupplementService()
            let data = try await service.loadCatalog()
            supplementCatalog.populate(
                supplements: data.supplements,
                goalMaps: data.goalMaps,
                synergyPairings: data.synergies
            )
        } catch {
            catalogLoadError = error
            // Fall back to static data so the app still works
            supplementCatalog.populateFromStatic()
        }

        isCatalogLoading = false
    }

    // MARK: - Demo Data

    func loadDemoData() {
        // Populate catalog from static data for demo mode
        supplementCatalog.populateFromStatic()

        // User profile
        var profile = UserProfile(firstName: "Matt")
        profile.age = 32
        profile.sex = .male
        profile.healthGoals = [.sleep, .energy, .focus, .gutHealth]
        profile.exerciseFrequency = .threeToFour
        profile.stressLevel = .moderate
        profile.dietType = .omnivore
        profile.baselineSleep = 5
        profile.baselineEnergy = 5
        profile.baselineClarity = 6
        profile.baselineMood = 6
        profile.baselineGut = 5
        currentUser = profile

        // Generate plan from profile
        let engine = RecommendationEngine(catalog: supplementCatalog)
        var plan = engine.generatePlan(for: profile)
        plan.aiReasoning = "Your plan targets sleep quality, sustained energy, mental clarity, and gut health. Magnesium and Ashwagandha form the core foundation, supported by Omega-3 for brain health and Probiotics for digestion. Timing is optimized to match your daily rhythm."
        activePlan = plan

        // Generate 30 days of check-in history
        let calendar = Calendar.current
        let today = Date()
        var checkIns: [DailyCheckIn] = []

        let demoScores: [(sleep: Int, energy: Int, clarity: Int, mood: Int, gut: Int)] = [
            (4, 4, 4, 5, 3), // 29 days ago
            (4, 3, 5, 4, 4),
            (5, 4, 4, 5, 4),
            (3, 4, 5, 4, 5),
            (5, 5, 4, 5, 4),
            (4, 5, 5, 6, 5),
            (5, 4, 5, 5, 5),
            (5, 5, 6, 5, 4), // 22 days ago
            (6, 5, 5, 6, 5),
            (5, 6, 5, 5, 5),
            (6, 5, 6, 6, 6),
            (5, 6, 6, 5, 6),
            (6, 6, 5, 6, 5),
            (6, 5, 6, 7, 6),
            (5, 6, 6, 6, 6), // 15 days ago
            (6, 6, 7, 6, 6),
            (7, 6, 6, 7, 6),
            (6, 7, 6, 6, 7),
            (6, 6, 7, 7, 6),
            (7, 7, 6, 7, 7),
            (7, 6, 7, 6, 7),
            (6, 7, 7, 7, 6), // 8 days ago
            (7, 7, 7, 7, 7),
            (5, 4, 5, 5, 4), // 6 days ago
            (6, 5, 6, 6, 5),
            (6, 6, 5, 7, 6),
            (7, 5, 7, 6, 6),
            (7, 7, 7, 7, 7),
            (8, 7, 8, 7, 7), // yesterday
            (7, 8, 7, 8, 7), // today
        ]

        for (i, scores) in demoScores.enumerated() {
            let daysAgo = demoScores.count - 1 - i
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let isToday = daysAgo == 0
            var checkIn = DailyCheckIn(
                checkInDate: date,
                createdAt: date,
                sleepScore: scores.sleep,
                energyScore: scores.energy,
                clarityScore: scores.clarity,
                moodScore: scores.mood,
                gutScore: scores.gut,
                wellbeingCompleted: !isToday
            )
            // Add supplement logs for each check-in
            if let supplements = activePlan?.supplements {
                checkIn.supplementLogs = supplements.map { supp in
                    SupplementLog(
                        planSupplementId: supp.id,
                        loggedDate: date,
                        taken: isToday ? false : (Bool.random() || i > 3), // today starts unlogged
                        loggedAt: date
                    )
                }
            }
            checkIns.append(checkIn)
        }

        recentCheckIns = checkIns
        todayCheckIn = checkIns.last

        // Streak
        streak = UserStreak(currentStreak: 30, longestStreak: 30, lastCheckInDate: today)

        // Insights
        insights = [
            Insight(
                type: .trend,
                title: "Sleep is trending up",
                body: "Your sleep scores have improved from 5.0 to 7.5 over the past week. The Magnesium Glycinate you're taking before bed may be contributing.",
                dataPointsUsed: 7,
                dimension: .sleep
            ),
            Insight(
                type: .correlation,
                title: "Energy peaks with consistency",
                body: "On days you took all your morning supplements, your energy score averaged 7.2 vs 4.8 on skipped days.",
                dataPointsUsed: 7,
                dimension: .energy
            ),
            Insight(
                type: .milestone,
                title: "7-day streak!",
                body: "You've checked in every day this week. Consistency is key to building a reliable picture of your wellness trends.",
                dataPointsUsed: 7
            ),
        ]

        // Load deep profile state
        deepProfileService.loadCompletedModules()

        // Mark onboarding complete so MainTabView shows
        isOnboardingComplete = true
    }
}

enum AppTab: Int, CaseIterable {
    case today = 0
    case progress
    case plan

    var label: String {
        switch self {
        case .today: return "Today"
        case .progress: return "Progress"
        case .plan: return "Plan"
        }
    }

    var icon: String {
        switch self {
        case .today: return "sun.max.fill"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .plan: return "pill.fill"
        }
    }
}
