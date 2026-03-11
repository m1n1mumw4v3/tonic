import SwiftUI

enum InsightsPeriod: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"

    var id: String { rawValue }
    var dayCount: Int { self == .week ? 7 : 30 }
    var headerLabel: String { self == .week ? "LAST 7 DAYS" : "LAST 30 DAYS" }
}

@Observable
class InsightsViewModel {
    var periodData: [DayData] = []
    var dimensionAverages: [DimensionAverage] = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalCheckIns: Int = 0
    var baselineScore: Double? = nil
    var adherencePercentage: String = "—"
    var periodAverage: Double?
    var trendDirection: TrendInfo?

    // Timeline
    var timelineCards: [TimelineCardData] = []
    var timelineSummary: TimelineSummaryData?
    var daysOnPlan: Int = 0
    var checkInCount: Int = 0
    var isEarlyState: Bool { checkInCount < 3 }
    var hasActivePlan: Bool = false

    func loadTimeline(appState: AppState) {
        guard let plan = appState.activePlan else {
            hasActivePlan = false
            timelineCards = []
            timelineSummary = nil
            return
        }
        hasActivePlan = true
        checkInCount = appState.recentCheckIns.count

        let calendar = Calendar.current
        let now = Date()
        daysOnPlan = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: plan.createdAt), to: calendar.startOfDay(for: now)).day ?? 0)

        let checkIns = appState.recentCheckIns.sorted { $0.checkInDate < $1.checkInDate }
        let activeSupplements = plan.supplements.filter { !$0.isRemoved }

        timelineCards = activeSupplements.compactMap { supplement in
            guard let durations = SupplementKnowledgeBase.phaseDurations(for: supplement.name) else { return nil }

            let phaseState = SupplementPhaseState.compute(daysOnPlan: daysOnPlan, durations: durations)
            let phaseContent = SupplementKnowledgeBase.phaseContentFor(supplement: supplement.name, phase: phaseState.currentPhase)

            // Determine primary dimension from matched goals
            let primaryDimension = supplement.matchedGoals
                .compactMap { SupplementKnowledgeBase.goalToDimension[$0] }
                .first ?? .energy

            let accentColor = primaryDimension.color

            // Baseline score for this dimension
            let baselineScore: Double = {
                guard let user = appState.currentUser else { return 5.0 }
                switch primaryDimension {
                case .sleep:   return Double(user.baselineSleep)
                case .energy:  return Double(user.baselineEnergy)
                case .clarity: return Double(user.baselineClarity)
                case .mood:    return Double(user.baselineMood)
                case .gut:     return Double(user.baselineGut)
                }
            }()

            // 7-day average for primary dimension (need >= 3 check-ins)
            var currentAverage: Double? = nil
            var deltaVsBaseline: Double? = nil
            let recentCheckIns = Array(checkIns.suffix(7))
            if recentCheckIns.count >= 3 {
                let scores = recentCheckIns.map { Double($0.score(for: primaryDimension)) }
                let avg = scores.reduce(0, +) / Double(scores.count)
                currentAverage = avg
                deltaVsBaseline = avg - baselineScore
            }

            return TimelineCardData(
                id: UUID(),
                supplementName: supplement.name,
                dosage: supplement.dosage,
                timing: supplement.timing,
                tier: supplement.tier,
                primaryDimension: primaryDimension,
                accentColor: accentColor,
                phaseState: phaseState,
                phaseContent: phaseContent,
                baselineScore: baselineScore,
                currentAverage: currentAverage,
                deltaVsBaseline: deltaVsBaseline
            )
        }
        .sorted { a, b in
            if a.phaseState.currentPhase != b.phaseState.currentPhase {
                return a.phaseState.currentPhase < b.phaseState.currentPhase
            }
            return a.tier.sortOrder < b.tier.sortOrder
        }

        // Build summary
        let inOnsetOrLater = timelineCards.filter(\.phaseState.hasReachedOnset).count
        let total = timelineCards.count

        let summaryText: String
        if inOnsetOrLater == 0 {
            summaryText = "All supplements are in their early phases. Consistency is key right now."
        } else if inOnsetOrLater == total {
            summaryText = "All supplements have reached onset or steady state."
        } else {
            let slowest = timelineCards.last(where: { !$0.phaseState.hasReachedOnset })
            if let slowest {
                summaryText = "\(slowest.supplementName) has the longest road ahead at \(slowest.phaseState.currentPhase.label) phase."
            } else {
                summaryText = "Your supplements are progressing well."
            }
        }

        timelineSummary = TimelineSummaryData(
            supplementsInOnsetOrLater: inOnsetOrLater,
            totalSupplements: total,
            summaryText: summaryText
        )
    }

    func load(appState: AppState, period: InsightsPeriod = .week) {
        let checkIns = appState.recentCheckIns
            .sorted { $0.checkInDate < $1.checkInDate }

        currentStreak = appState.streak.currentStreak
        longestStreak = appState.streak.longestStreak
        totalCheckIns = checkIns.count

        if let user = appState.currentUser {
            let baselines = [
                Double(user.baselineSleep),
                Double(user.baselineEnergy),
                Double(user.baselineClarity),
                Double(user.baselineMood),
                Double(user.baselineGut)
            ]
            baselineScore = baselines.reduce(0, +) / Double(baselines.count)
        }

        guard !checkIns.isEmpty else { return }

        let days = period.dayCount
        let periodCheckIns = Array(checkIns.suffix(days))
        let calendar = Calendar.current

        // Bar chart data
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = period == .week ? "EEE" : "d"

        periodData = periodCheckIns.map { checkIn in
            DayData(
                score: checkIn.wellbeingScore,
                dayLabel: dayFormatter.string(from: checkIn.checkInDate).uppercased(),
                date: checkIn.checkInDate,
                isToday: calendar.isDateInToday(checkIn.checkInDate)
            )
        }

        // Period average
        let scores = periodCheckIns.map(\.wellbeingScore)
        periodAverage = scores.reduce(0, +) / Double(scores.count)

        // Trend direction (compare recent half vs earlier half of the period)
        if periodCheckIns.count >= 3 {
            let halfCount = max(1, periodCheckIns.count / 2)
            let recentHalf = periodCheckIns.suffix(halfCount)
            let earlierHalf = periodCheckIns.prefix(halfCount)
            let recentAvg = recentHalf.map(\.wellbeingScore).reduce(0, +) / Double(recentHalf.count)
            let earlierAvg = earlierHalf.map(\.wellbeingScore).reduce(0, +) / Double(earlierHalf.count)
            let diff = recentAvg - earlierAvg

            let periodLabel = period == .week ? "last week" : "prior period"
            if diff > 0.3 {
                trendDirection = TrendInfo(
                    icon: "arrow.up.right",
                    label: String(format: "Trending up %.1f pts from \(periodLabel)", diff),
                    color: DesignTokens.positive
                )
            } else if diff < -0.3 {
                trendDirection = TrendInfo(
                    icon: "arrow.down.right",
                    label: String(format: "Down %.1f pts from \(periodLabel)", abs(diff)),
                    color: DesignTokens.negative
                )
            } else {
                trendDirection = TrendInfo(
                    icon: "arrow.right",
                    label: "Holding steady",
                    color: DesignTokens.textSecondary
                )
            }
        }

        // Dimension averages
        dimensionAverages = WellnessDimension.allCases.map { dim in
            let dimScores = periodCheckIns.map { Double($0.score(for: dim)) }
            let avg = dimScores.reduce(0, +) / Double(dimScores.count)

            var change: Double? = nil
            if periodCheckIns.count >= 4 {
                let halfCount = max(1, periodCheckIns.count / 2)
                let recentDim = periodCheckIns.suffix(halfCount).map { Double($0.score(for: dim)) }
                let earlierDim = periodCheckIns.prefix(halfCount).map { Double($0.score(for: dim)) }
                let recentAvg = recentDim.reduce(0, +) / Double(recentDim.count)
                let earlierAvg = earlierDim.reduce(0, +) / Double(earlierDim.count)
                change = recentAvg - earlierAvg
            }

            return DimensionAverage(dimension: dim, average: avg, change: change)
        }

        // Supplement adherence
        let allLogs = checkIns.flatMap(\.supplementLogs)
        if !allLogs.isEmpty {
            let taken = allLogs.filter(\.taken).count
            let pct = Int(Double(taken) / Double(allLogs.count) * 100)
            adherencePercentage = "\(pct)%"
        }
    }
}

// MARK: - View Data Models

struct DayData: Identifiable {
    let id = UUID()
    let score: Double
    let dayLabel: String
    let date: Date
    let isToday: Bool

    var fullDateLabel: String {
        Self.tooltipFormatter.string(from: date).uppercased()
    }

    private static let tooltipFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
}

struct DimensionAverage: Identifiable {
    var id: String { dimension.rawValue }
    let dimension: WellnessDimension
    let average: Double
    let change: Double?
}

struct TrendInfo {
    let icon: String
    let label: String
    let color: Color
}

struct TimelineCardData: Identifiable {
    let id: UUID
    let supplementName: String
    let dosage: String
    let timing: SupplementTiming
    let tier: SupplementTier
    let primaryDimension: WellnessDimension
    let accentColor: Color
    let phaseState: SupplementPhaseState
    let phaseContent: SupplementKnowledgeBase.SupplementPhaseContent
    let baselineScore: Double
    let currentAverage: Double?   // 7-day avg for primary dimension, nil if < 3 check-ins
    let deltaVsBaseline: Double?  // currentAverage - baselineScore
}

struct TimelineSummaryData {
    let supplementsInOnsetOrLater: Int
    let totalSupplements: Int
    let summaryText: String
}
