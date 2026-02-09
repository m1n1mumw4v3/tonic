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
