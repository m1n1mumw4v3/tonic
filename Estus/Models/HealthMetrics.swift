import Foundation

struct HealthMetrics: Codable {
    var lastSyncDate: Date?

    // Sleep
    var averageSleepDurationHours: Double?
    var lastNightSleepDurationHours: Double?

    // Heart
    var restingHeartRate: Double?
    var heartRateVariability: Double?

    // Activity
    var averageDailySteps: Int?
    var weeklyWorkoutCount: Int?
    var weeklyWorkoutMinutes: Double?

    // Demographics
    var biologicalSex: BiologicalSex?

    var isStale: Bool {
        guard let lastSync = lastSyncDate else { return true }
        return Date().timeIntervalSince(lastSync) > 12 * 60 * 60
    }
}

enum BiologicalSex: String, Codable {
    case male
    case female
    case other

    var toSex: Sex {
        switch self {
        case .male: return .male
        case .female: return .female
        case .other: return .other
        }
    }
}
