import SwiftUI

@Observable
class TodayViewModel {
    private let dataStore: DataStore

    // MARK: - Time-of-Day State

    enum TodayPhase {
        case morning  // midnight - 4:59 PM
        case evening  // 5:00 PM - midnight
        case complete // all supplements logged + wellbeing submitted
    }

    // MARK: - Greeting / Date

    var greeting: String = ""
    var dateLabel: String = ""

    // MARK: - Supplement Logging (Today)

    var supplementStates: [UUID: Bool] = [:]
    var allJustCompleted: Bool = false
    private(set) var currentPlan: SupplementPlan?
    private var previousAmComplete = false
    private var previousPmComplete = false
    var amJustCompleted = false
    var pmJustCompleted = false
    var hasPlayedCompletionAnimation = false

    // MARK: - Yesterday Retroactive

    var yesterdaySupplementStates: [UUID: Bool] = [:]
    var showYesterdaySection: Bool = false

    // MARK: - Wellbeing Check-In (Evening)

    var sleepScore: Double = 5
    var energyScore: Double = 5
    var clarityScore: Double = 5
    var moodScore: Double = 5
    var gutScore: Double = 5
    var trailingAverages: [WellnessDimension: Double] = [:]
    var completionInsight: CheckInInsight?
    var wellbeingSubmitted: Bool = false

    // MARK: - Micro-Reward

    var microRewardContent: MicroRewardContent?

    // MARK: - Feed

    var insightFeed: [Insight] = []
    var discoveryTips: [DiscoveryTip] = []

    // MARK: - Timing Constants

    private static let amTimings: Set<SupplementTiming> = [.emptyStomach, .morning, .withFood]
    private static let pmTimings: Set<SupplementTiming> = [.afternoon, .evening, .bedtime]

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    // MARK: - Current Phase

    func currentPhase(appState: AppState) -> TodayPhase {
        if appState.isDayComplete {
            return .complete
        }
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 17 ? .evening : .morning
    }

    // MARK: - Load

    func load(appState: AppState) {
        let userName = appState.userName
        greeting = "\(Date().greetingPrefix), \(userName)"
        dateLabel = Date().monoDateLabel

        currentPlan = appState.activePlan

        // Initialize supplement states from today's check-in or fresh
        initializeSupplements(from: appState.activePlan, existingCheckIn: appState.todayCheckIn)

        // Pre-load wellbeing scores from yesterday (or baselines)
        loadWellbeingDefaults(appState: appState)

        // Trailing averages for sliders
        loadTrailingAverages()

        // Yesterday retroactive section
        loadYesterdayState(appState: appState)

        // Track if wellbeing was already submitted today
        wellbeingSubmitted = appState.hasCompletedWellbeingToday

        // Feed
        loadFeed(appState: appState)
    }

    // MARK: - Supplement Initialization

    func initializeSupplements(from plan: SupplementPlan?, existingCheckIn: DailyCheckIn? = nil) {
        guard let plan = plan else { return }
        currentPlan = plan

        let active = plan.supplements.filter { !$0.isRemoved }

        if let checkIn = existingCheckIn {
            for supplement in active {
                let taken = checkIn.supplementLogs.first { $0.planSupplementId == supplement.id }?.taken ?? false
                supplementStates[supplement.id] = taken
            }
            previousAmComplete = amComplete
            previousPmComplete = pmComplete
            if allTaken {
                hasPlayedCompletionAnimation = true
            }
        } else {
            for supplement in active {
                supplementStates[supplement.id] = false
            }
        }
    }

    // MARK: - Supplement Toggling

    func toggleSupplement(_ id: UUID, appState: AppState) {
        allJustCompleted = false
        amJustCompleted = false
        pmJustCompleted = false
        supplementStates[id] = !(supplementStates[id] ?? false)

        detectTrayCompletions()

        if allTaken {
            allJustCompleted = true
        }

        persistSupplementLog(appState: appState)
    }

    func takeAll(plan: SupplementPlan?, appState: AppState) {
        guard let plan = plan else { return }
        amJustCompleted = false
        pmJustCompleted = false

        let active = plan.supplements.filter { !$0.isRemoved }
        let untaken = active.filter { !(supplementStates[$0.id] ?? false) }
        let sorted = untaken.sorted { $0.timing.sortOrder < $1.timing.sortOrder }
        for (index, supplement) in sorted.enumerated() {
            let delay = Double(index) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                    self.supplementStates[supplement.id] = true
                }
                HapticManager.impact(.medium)
                self.detectTrayCompletions()
            }
        }
        let totalDelay = Double(sorted.count) * 0.06 + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.allJustCompleted = true
            HapticManager.notification(.success)
            self.persistSupplementLog(appState: appState)
        }
    }

    func takeAllByIDs(_ ids: [UUID], appState: AppState) {
        let untaken = ids.filter { !(supplementStates[$0] ?? false) }
        for (index, id) in untaken.enumerated() {
            let delay = Double(index) * 0.06
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                    self.supplementStates[id] = true
                }
                HapticManager.impact(.medium)
                self.detectTrayCompletions()
            }
        }
        let totalDelay = Double(untaken.count) * 0.06 + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.persistSupplementLog(appState: appState)
        }
    }

    // MARK: - Per-Tray Progress

    var amProgress: CGFloat {
        guard let plan = currentPlan else { return 0 }
        let amSupps = plan.supplements.filter { Self.amTimings.contains($0.timing) && !$0.isRemoved }
        guard !amSupps.isEmpty else { return 0 }
        let taken = amSupps.filter { supplementStates[$0.id] == true }.count
        return CGFloat(taken) / CGFloat(amSupps.count)
    }

    var pmProgress: CGFloat {
        guard let plan = currentPlan else { return 0 }
        let pmSupps = plan.supplements.filter { Self.pmTimings.contains($0.timing) && !$0.isRemoved }
        guard !pmSupps.isEmpty else { return 0 }
        let taken = pmSupps.filter { supplementStates[$0.id] == true }.count
        return CGFloat(taken) / CGFloat(pmSupps.count)
    }

    var amComplete: Bool { amProgress >= 1.0 }
    var pmComplete: Bool { pmProgress >= 1.0 }

    var allTaken: Bool {
        !supplementStates.isEmpty && supplementStates.values.allSatisfy { $0 }
    }

    var takenCount: Int {
        supplementStates.values.filter { $0 }.count
    }

    // MARK: - Time-Filtered Supplements

    func visibleSupplements(for phase: TodayPhase, plan: SupplementPlan?) -> [PlanSupplement] {
        guard let plan = plan else { return [] }
        let active = plan.supplements.filter { !$0.isRemoved }

        // QA OVERRIDE: show all supplements regardless of time-of-day phase
        return active.sorted { $0.timing.sortOrder < $1.timing.sortOrder }
    }

    // MARK: - Tray Completion Detection

    private func detectTrayCompletions() {
        let amNow = amComplete
        let pmNow = pmComplete

        if amNow && !previousAmComplete {
            amJustCompleted = true
            HapticManager.notification(.success)
        }
        if pmNow && !previousPmComplete {
            pmJustCompleted = true
            HapticManager.notification(.success)
        }

        previousAmComplete = amNow
        previousPmComplete = pmNow
    }

    // MARK: - Persist Supplement Log

    private func persistSupplementLog(appState: AppState) {
        guard let plan = appState.activePlan else { return }

        var checkIn = appState.todayCheckIn ?? DailyCheckIn(wellbeingCompleted: false)
        checkIn.supplementLogs = plan.supplements.filter { !$0.isRemoved }.map { supplement in
            SupplementLog(
                planSupplementId: supplement.id,
                taken: supplementStates[supplement.id] ?? false
            )
        }

        try? dataStore.saveCheckIn(checkIn)
        appState.todayCheckIn = checkIn

        // Update recentCheckIns
        if let index = appState.recentCheckIns.firstIndex(where: {
            Calendar.current.isDate($0.checkInDate, inSameDayAs: checkIn.checkInDate)
        }) {
            appState.recentCheckIns[index] = checkIn
        } else {
            appState.recentCheckIns.insert(checkIn, at: 0)
        }
    }

    // MARK: - Wellbeing Check-In

    private func loadWellbeingDefaults(appState: AppState) {
        // Pre-load from yesterday's scores, fall back to baselines
        let yesterday = appState.recentCheckIns.first(where: {
            Calendar.current.isDateInYesterday($0.checkInDate) && $0.wellbeingCompleted
        })

        if let y = yesterday {
            sleepScore = Double(y.sleepScore)
            energyScore = Double(y.energyScore)
            clarityScore = Double(y.clarityScore)
            moodScore = Double(y.moodScore)
            gutScore = Double(y.gutScore)
        } else if let user = appState.currentUser {
            sleepScore = Double(user.baselineSleep)
            energyScore = Double(user.baselineEnergy)
            clarityScore = Double(user.baselineClarity)
            moodScore = Double(user.baselineMood)
            gutScore = Double(user.baselineGut)
        }
    }

    func loadTrailingAverages() {
        guard let checkIns = try? dataStore.getCheckIns(limit: 7) else { return }

        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date()))!
        let recent = checkIns.filter { $0.checkInDate >= sevenDaysAgo && $0.wellbeingCompleted }

        guard !recent.isEmpty else { return }

        let count = Double(recent.count)
        trailingAverages[.sleep] = recent.map { Double($0.sleepScore) }.reduce(0, +) / count
        trailingAverages[.energy] = recent.map { Double($0.energyScore) }.reduce(0, +) / count
        trailingAverages[.clarity] = recent.map { Double($0.clarityScore) }.reduce(0, +) / count
        trailingAverages[.mood] = recent.map { Double($0.moodScore) }.reduce(0, +) / count
        trailingAverages[.gut] = recent.map { Double($0.gutScore) }.reduce(0, +) / count
    }

    func submitWellbeingCheckIn(appState: AppState) {
        guard var checkIn = appState.todayCheckIn else { return }

        checkIn.sleepScore = Int(sleepScore)
        checkIn.energyScore = Int(energyScore)
        checkIn.clarityScore = Int(clarityScore)
        checkIn.moodScore = Int(moodScore)
        checkIn.gutScore = Int(gutScore)
        checkIn.wellbeingCompleted = true

        try? dataStore.saveCheckIn(checkIn)
        appState.todayCheckIn = checkIn

        // Update in recentCheckIns
        if let index = appState.recentCheckIns.firstIndex(where: {
            Calendar.current.isDate($0.checkInDate, inSameDayAs: checkIn.checkInDate)
        }) {
            appState.recentCheckIns[index] = checkIn
        }

        // Check if day is now complete (supplements + check-in)
        updateStreakIfDayComplete(appState: appState)

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

        let baselines = Self.baselines(from: appState.currentUser)

        let context = CheckInInsightGenerator.Context(
            todayScores: todayScores,
            baselines: baselines,
            trailingAverages: trailingAverages,
            recentCheckIns: appState.recentCheckIns.filter {
                !Calendar.current.isDateInToday($0.checkInDate)
            },
            streak: appState.streak,
            supplementsTakenToday: takenSupplements,
            plan: appState.activePlan,
            recentlyShownKeys: RecentInsightTracker.recentKeys(),
            catalog: appState.supplementCatalog
        )

        let insight = CheckInInsightGenerator().generate(from: context)
        completionInsight = insight
        if let key = insight?.key {
            RecentInsightTracker.record(key)
        }

        // Persist insight
        if let checkInInsight = insight {
            let persistedInsight = Insight(from: checkInInsight)
            var allInsights = (try? dataStore.getInsights()) ?? []
            allInsights.insert(persistedInsight, at: 0)
            if allInsights.count > 50 { allInsights = Array(allInsights.prefix(50)) }
            try? dataStore.saveInsights(allInsights)
            appState.insights = allInsights
        }

        wellbeingSubmitted = true
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

    // MARK: - Yesterday Retroactive

    private func loadYesterdayState(appState: AppState) {
        guard let plan = appState.activePlan else {
            showYesterdaySection = false
            return
        }

        let calendar = Calendar.current
        let yesterdayCheckIn = appState.recentCheckIns.first(where: {
            calendar.isDateInYesterday($0.checkInDate)
        })

        // Check 48-hour window
        let now = Date()
        let fortyEightHoursAgo = calendar.date(byAdding: .hour, value: -48, to: now)!
        let yesterdayStart = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now)!)

        guard yesterdayStart >= fortyEightHoursAgo else {
            showYesterdaySection = false
            return
        }

        let active = plan.supplements.filter { !$0.isRemoved }

        if let checkIn = yesterdayCheckIn {
            // Check if any supplements are unlogged
            var hasUnlogged = false
            for supplement in active {
                let taken = checkIn.supplementLogs.first { $0.planSupplementId == supplement.id }?.taken ?? false
                yesterdaySupplementStates[supplement.id] = taken
                if !taken { hasUnlogged = true }
            }
            showYesterdaySection = hasUnlogged
        } else {
            // No check-in at all for yesterday
            for supplement in active {
                yesterdaySupplementStates[supplement.id] = false
            }
            showYesterdaySection = true
        }
    }

    var yesterdayRemainingCount: Int {
        yesterdaySupplementStates.values.filter { !$0 }.count
    }

    func toggleYesterdaySupplement(_ id: UUID, appState: AppState) {
        yesterdaySupplementStates[id] = !(yesterdaySupplementStates[id] ?? false)
        persistYesterdayLog(appState: appState)
    }

    private func persistYesterdayLog(appState: AppState) {
        guard let plan = appState.activePlan else { return }
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        var checkIn = appState.recentCheckIns.first(where: {
            calendar.isDateInYesterday($0.checkInDate)
        }) ?? DailyCheckIn(checkInDate: yesterday, wellbeingCompleted: false)

        checkIn.supplementLogs = plan.supplements.filter { !$0.isRemoved }.map { supplement in
            SupplementLog(
                planSupplementId: supplement.id,
                loggedDate: yesterday,
                taken: yesterdaySupplementStates[supplement.id] ?? false,
                loggedAt: Date()
            )
        }

        try? dataStore.saveCheckIn(checkIn)

        // Update recentCheckIns
        if let index = appState.recentCheckIns.firstIndex(where: {
            calendar.isDate($0.checkInDate, inSameDayAs: yesterday)
        }) {
            appState.recentCheckIns[index] = checkIn
        } else {
            appState.recentCheckIns.append(checkIn)
            appState.recentCheckIns.sort { $0.checkInDate > $1.checkInDate }
        }

        // Hide section if all logged
        if yesterdaySupplementStates.values.allSatisfy({ $0 }) {
            withAnimation {
                showYesterdaySection = false
            }
        }
    }

    // MARK: - Streak

    func updateStreakIfDayComplete(appState: AppState) {
        guard allTaken && wellbeingSubmitted else { return }

        var streak = (try? dataStore.getStreak()) ?? UserStreak()
        streak.recordCheckIn()
        try? dataStore.saveStreak(streak)
        appState.streak = streak
    }

    // MARK: - Micro-Reward Generation

    func generateMicroReward(appState: AppState) {
        guard let plan = currentPlan else { return }

        if let milestone = generateTimelineMilestone(plan: plan, appState: appState) {
            microRewardContent = .timeline(milestone)
            return
        }

        if let adherence = generateAdherenceInsight(appState: appState) {
            microRewardContent = .adherence(adherence)
            return
        }

        microRewardContent = .tip(generateDailyTip())
    }

    private func generateTimelineMilestone(plan: SupplementPlan, appState: AppState) -> SupplementMilestone? {
        let consecutiveDays = appState.streak.currentStreak

        for supplement in plan.supplements {
            guard let dbSupp = appState.supplementCatalog.dbSupplement(named: supplement.name),
                  let onsetMin = dbSupp.onsetMinDays,
                  let onsetMax = dbSupp.onsetMaxDays else { continue }

            if consecutiveDays >= onsetMin && consecutiveDays <= onsetMax {
                let progress: String
                if consecutiveDays <= onsetMin + 2 {
                    progress = "You're entering the window where \(supplement.name) starts working."
                } else if consecutiveDays >= onsetMax - 3 {
                    progress = "You should be feeling the full effects of \(supplement.name) soon."
                } else {
                    progress = "\(dbSupp.onsetDescription ?? "Changes are happening.")"
                }

                let accent = SupplementIconRegistry.config(for: supplement.name).accentColor

                return SupplementMilestone(
                    supplementName: supplement.name,
                    dayCount: consecutiveDays,
                    onsetMin: onsetMin,
                    onsetMax: onsetMax,
                    message: "Day \(consecutiveDays): \(progress)",
                    accentColor: accent
                )
            }
        }
        return nil
    }

    private func generateAdherenceInsight(appState: AppState) -> AdherenceInsight? {
        let recent = appState.recentCheckIns
        guard recent.count >= 7 else { return nil }

        let last7 = Array(recent.prefix(7))
        let totalLogs = last7.flatMap { $0.supplementLogs }
        guard !totalLogs.isEmpty else { return nil }

        let takenLogs = totalLogs.filter { $0.taken }
        let adherence = Int((Double(takenLogs.count) / Double(totalLogs.count)) * 100)

        guard adherence >= 80 else { return nil }

        return AdherenceInsight(
            message: "You've logged \(adherence)% of your supplements this week. Consistency is where the real benefits compound.",
            adherencePercent: adherence,
            accentColor: DesignTokens.accentEnergy
        )
    }

    private func generateDailyTip() -> SupplementTip {
        let tips = SupplementKnowledgeBase.dailyTips
        let index = Calendar.current.component(.day, from: Date()) % tips.count
        return SupplementTip(
            supplementName: nil,
            message: tips[index],
            accentColor: DesignTokens.positive
        )
    }

    // MARK: - Feed

    private func loadFeed(appState: AppState) {
        let allInsights = (try? dataStore.getInsights()) ?? []
        insightFeed = Array(allInsights.filter { !$0.isDismissed }.prefix(3))

        if insightFeed.isEmpty {
            discoveryTips = DiscoveryTipProvider.tips(for: appState.activePlan, catalog: appState.supplementCatalog)
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
