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
