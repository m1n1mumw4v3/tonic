import Foundation

struct Insight: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var createdAt: Date = Date()
    var type: InsightType
    var title: String
    var body: String
    var dataPointsUsed: Int?
    var dimension: WellnessDimension?
    var isRead: Bool = false
    var isDismissed: Bool = false
}

extension Insight {
    init(from checkInInsight: CheckInInsight) {
        let key = checkInInsight.key
        let (type, title): (InsightType, String) = {
            if key.hasPrefix("pb_") { return (.milestone, "Personal Best") }
            if key.hasPrefix("supp_tip_") { return (.recommendation, "Supplement Tip") }
            if key.hasPrefix("supp_") { return (.milestone, "Supplement Consistency") }
            if key.hasPrefix("above_baseline_") { return (.trend, "Above Your Baseline") }
            if key.hasPrefix("above_avg_") { return (.trend, "Trending Up") }
            if key.hasPrefix("improving_") { return (.trend, "On a Roll") }
            if key == "full_adherence" { return (.milestone, "Perfect Adherence") }
            if key.hasPrefix("fun_fact_") { return (.recommendation, "Did You Know?") }
            return (.recommendation, "Daily Reflection")
        }()

        self.init(
            type: type,
            title: title,
            body: checkInInsight.message,
            dimension: checkInInsight.dimension
        )
    }
}

enum InsightType: String, Codable, CaseIterable {
    case correlation
    case trend
    case recommendation
    case milestone

    var label: String {
        switch self {
        case .correlation: return "Correlation"
        case .trend: return "Trend"
        case .recommendation: return "Tip"
        case .milestone: return "Milestone"
        }
    }

    var icon: String {
        switch self {
        case .correlation: return "arrow.triangle.branch"
        case .trend: return "chart.line.uptrend.xyaxis"
        case .recommendation: return "lightbulb.fill"
        case .milestone: return "star.fill"
        }
    }
}
