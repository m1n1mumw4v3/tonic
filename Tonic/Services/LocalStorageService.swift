import Foundation

class LocalStorageService: DataStore {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let profile = "tonic_user_profile"
        static let plan = "tonic_active_plan"
        static let checkIns = "tonic_check_ins"
        static let streak = "tonic_streak"
        static let insights = "tonic_insights"
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) throws {
        let data = try encoder.encode(profile)
        defaults.set(data, forKey: Keys.profile)
    }

    func getProfile() throws -> UserProfile? {
        guard let data = defaults.data(forKey: Keys.profile) else { return nil }
        return try decoder.decode(UserProfile.self, from: data)
    }

    // MARK: - Plan

    func savePlan(_ plan: SupplementPlan) throws {
        let data = try encoder.encode(plan)
        defaults.set(data, forKey: Keys.plan)
    }

    func getActivePlan() throws -> SupplementPlan? {
        guard let data = defaults.data(forKey: Keys.plan) else { return nil }
        return try decoder.decode(SupplementPlan.self, from: data)
    }

    // MARK: - Check-Ins

    func saveCheckIn(_ checkIn: DailyCheckIn) throws {
        var checkIns = (try? getCheckIns(limit: nil)) ?? []

        // Replace if same date exists
        if let index = checkIns.firstIndex(where: {
            Calendar.current.isDate($0.checkInDate, inSameDayAs: checkIn.checkInDate)
        }) {
            checkIns[index] = checkIn
        } else {
            checkIns.append(checkIn)
        }

        // Keep last 90 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        checkIns = checkIns.filter { $0.checkInDate > cutoff }

        let data = try encoder.encode(checkIns)
        defaults.set(data, forKey: Keys.checkIns)
    }

    func getCheckIns(limit: Int?) throws -> [DailyCheckIn] {
        guard let data = defaults.data(forKey: Keys.checkIns) else { return [] }
        var checkIns = try decoder.decode([DailyCheckIn].self, from: data)
        checkIns.sort { $0.checkInDate > $1.checkInDate }
        if let limit = limit {
            return Array(checkIns.prefix(limit))
        }
        return checkIns
    }

    func getTodayCheckIn() throws -> DailyCheckIn? {
        let checkIns = try getCheckIns(limit: 7)
        return checkIns.first { Calendar.current.isDateInToday($0.checkInDate) }
    }

    // MARK: - Streak

    func saveStreak(_ streak: UserStreak) throws {
        let data = try encoder.encode(streak)
        defaults.set(data, forKey: Keys.streak)
    }

    func getStreak() throws -> UserStreak {
        guard let data = defaults.data(forKey: Keys.streak) else { return UserStreak() }
        return try decoder.decode(UserStreak.self, from: data)
    }

    // MARK: - Insights

    func saveInsights(_ insights: [Insight]) throws {
        let data = try encoder.encode(insights)
        defaults.set(data, forKey: Keys.insights)
    }

    func getInsights() throws -> [Insight] {
        guard let data = defaults.data(forKey: Keys.insights) else { return [] }
        return try decoder.decode([Insight].self, from: data)
    }
}
