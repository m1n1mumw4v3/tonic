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

    enum CodingKeys: String, CodingKey {
        case id, userId, createdAt, type, title, body
        case dataPointsUsed, dimension, isRead, isDismissed
    }
}

// MARK: - Resilient Decoder

extension Insight {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        type = try container.decode(InsightType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        dataPointsUsed = try container.decodeIfPresent(Int.self, forKey: .dataPointsUsed)
        dimension = try container.decodeIfPresent(WellnessDimension.self, forKey: .dimension)
        isRead = try container.decodeIfPresent(Bool.self, forKey: .isRead) ?? false
        isDismissed = try container.decodeIfPresent(Bool.self, forKey: .isDismissed) ?? false
    }
}

// MARK: - CheckInInsight Conversion

extension Insight {
    init(from checkInInsight: CheckInInsight) {
        let key = checkInInsight.key
        let (mappedType, mappedTitle): (InsightType, String) = {
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

        self.type = mappedType
        self.title = mappedTitle
        self.body = checkInInsight.message
        self.dimension = checkInInsight.dimension
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
