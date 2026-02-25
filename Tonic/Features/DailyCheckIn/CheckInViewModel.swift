import SwiftUI

@Observable
class CheckInViewModel {
    private let dataStore: DataStore
    var kb: KnowledgeBaseProvider = KnowledgeBaseProvider()

    // Step 1: Wellness scores
    var sleepScore: Double = 5
    var energyScore: Double = 5
    var clarityScore: Double = 5
    var moodScore: Double = 5
    var gutScore: Double = 5

    // Step 2: Supplement states
    var supplementStates: [UUID: Bool] = [:]
    var allJustCompleted: Bool = false

    // Step 3: Completion
    var wellbeingScore: Double = 0
    var isComplete: Bool = false
    var completionInsight: CheckInInsight?

    // 7-day trailing averages
    var trailingAverages: [WellnessDimension: Double] = [:]

    // Navigation
    var currentStep: Int = 0

    // Per-tray tracking
    private(set) var currentPlan: SupplementPlan?
    private var previousAmComplete = false
    private var previousPmComplete = false
    var amJustCompleted = false
    var pmJustCompleted = false

    // Micro-reward
    var microRewardContent: MicroRewardContent?

    // Completion celebration
    var hasPlayedCompletionAnimation = false

    private static let amTimings: Set<SupplementTiming> = [.emptyStomach, .morning, .withFood]
    private static let pmTimings: Set<SupplementTiming> = [.afternoon, .evening, .bedtime]

    init(dataStore: DataStore = LocalStorageService()) {
        self.dataStore = dataStore
    }

    var computedWellbeingScore: Double {
        WellbeingScore.calculate(
            sleep: Int(sleepScore), energy: Int(energyScore),
            clarity: Int(clarityScore), mood: Int(moodScore), gut: Int(gutScore)
        )
    }

    // MARK: - Per-Tray Progress

    var amProgress: CGFloat {
        guard let plan = currentPlan else { return 0 }
        let amSupps = plan.supplements.filter { Self.amTimings.contains($0.timing) }
        guard !amSupps.isEmpty else { return 0 }
        let taken = amSupps.filter { supplementStates[$0.id] == true }.count
        return CGFloat(taken) / CGFloat(amSupps.count)
    }

    var pmProgress: CGFloat {
        guard let plan = currentPlan else { return 0 }
        let pmSupps = plan.supplements.filter { Self.pmTimings.contains($0.timing) }
        guard !pmSupps.isEmpty else { return 0 }
        let taken = pmSupps.filter { supplementStates[$0.id] == true }.count
        return CGFloat(taken) / CGFloat(pmSupps.count)
    }

    var amComplete: Bool { amProgress >= 1.0 }
    var pmComplete: Bool { pmProgress >= 1.0 }

    // MARK: - Title

    var supplementTitle: String {
        allTaken ? "All done" : "Log your supplements"
    }

    // MARK: - Initialize

    func initializeSupplements(from plan: SupplementPlan?, existingCheckIn: DailyCheckIn? = nil) {
        guard let plan = plan else { return }
        currentPlan = plan

        let active = plan.supplements.filter { !$0.isRemoved }

        if let checkIn = existingCheckIn {
            // Re-entry: restore states from existing check-in
            for supplement in active {
                let taken = checkIn.supplementLogs.first { $0.planSupplementId == supplement.id }?.taken ?? false
                supplementStates[supplement.id] = taken
            }
            // Sync per-tray tracking
            previousAmComplete = amComplete
            previousPmComplete = pmComplete
            // If already all taken, mark celebration as played
            if allTaken {
                hasPlayedCompletionAnimation = true
            }
        } else {
            for supplement in active {
                supplementStates[supplement.id] = false
            }
        }
    }

    func toggleSupplement(_ id: UUID) {
        allJustCompleted = false
        amJustCompleted = false
        pmJustCompleted = false
        supplementStates[id] = !(supplementStates[id] ?? false)

        // Detect per-tray completion transitions
        detectTrayCompletions()

        // Check if all supplements are now taken
        let allNowTaken = allTaken
        if allNowTaken {
            allJustCompleted = true
        }
    }

    func takeAll(plan: SupplementPlan?) {
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

                // Check per-tray completions mid-cascade
                self.detectTrayCompletions()
            }
        }
        let totalDelay = Double(sorted.count) * 0.06 + 0.35
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            self.allJustCompleted = true
            HapticManager.notification(.success)
        }
    }

    func takeAllByIDs(_ ids: [UUID]) {
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
    }

    var allTaken: Bool {
        !supplementStates.isEmpty && supplementStates.values.allSatisfy { $0 }
    }

    var takenCount: Int {
        supplementStates.values.filter { $0 }.count
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

    // MARK: - Micro-Reward Generation

    func generateMicroReward(appState: AppState) {
        guard let plan = currentPlan else { return }

        // Priority 1: Timeline scaffolding
        if let milestone = generateTimelineMilestone(plan: plan, appState: appState) {
            microRewardContent = .timeline(milestone)
            return
        }

        // Priority 2: Adherence insight
        if let adherence = generateAdherenceInsight(appState: appState) {
            microRewardContent = .adherence(adherence)
            return
        }

        // Priority 3: Daily tip
        microRewardContent = .tip(generateDailyTip())
    }

    private func generateTimelineMilestone(plan: SupplementPlan, appState: AppState) -> SupplementMilestone? {
        let consecutiveDays = appState.streak.currentStreak

        for supplement in plan.supplements {
            guard let onset = kb.onsetTimelines[supplement.name] else { continue }

            // Check if user is approaching or within onset window
            if consecutiveDays >= onset.min && consecutiveDays <= onset.max {
                let progress: String
                if consecutiveDays <= onset.min + 2 {
                    progress = "You're entering the window where \(supplement.name) starts working."
                } else if consecutiveDays >= onset.max - 3 {
                    progress = "You should be feeling the full effects of \(supplement.name) soon."
                } else {
                    progress = "\(onset.description)"
                }

                let accent = SupplementIconRegistry.config(for: supplement.name).accentColor

                return SupplementMilestone(
                    supplementName: supplement.name,
                    dayCount: consecutiveDays,
                    onsetMin: onset.min,
                    onsetMax: onset.max,
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
        let tips = kb.dailyTips
        let index = Calendar.current.component(.day, from: Date()) % tips.count
        return SupplementTip(
            supplementName: nil,
            message: tips[index],
            accentColor: DesignTokens.positive
        )
    }

    // MARK: - Trailing Averages

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

        let insight = CheckInInsightGenerator(kb: kb).generate(from: context)
        completionInsight = insight
        if let key = insight?.key {
            RecentInsightTracker.record(key)
        }

        // Persist insight to storage
        if let checkInInsight = insight {
            let persistedInsight = Insight(from: checkInInsight)
            var allInsights = (try? dataStore.getInsights()) ?? []
            allInsights.insert(persistedInsight, at: 0)
            if allInsights.count > 50 { allInsights = Array(allInsights.prefix(50)) }
            try? dataStore.saveInsights(allInsights)
            appState.insights = allInsights
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
