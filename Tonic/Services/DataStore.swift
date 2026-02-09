import Foundation

// MARK: - DataStore Protocol
// Abstract data layer: swap LocalStorageService (M1-M2) for SupabaseDataStore (M3+)

protocol DataStore {
    func saveProfile(_ profile: UserProfile) throws
    func getProfile() throws -> UserProfile?

    func savePlan(_ plan: SupplementPlan) throws
    func getActivePlan() throws -> SupplementPlan?

    func saveCheckIn(_ checkIn: DailyCheckIn) throws
    func getCheckIns(limit: Int?) throws -> [DailyCheckIn]
    func getTodayCheckIn() throws -> DailyCheckIn?

    func saveStreak(_ streak: UserStreak) throws
    func getStreak() throws -> UserStreak

    func saveInsights(_ insights: [Insight]) throws
    func getInsights() throws -> [Insight]
}

// Default parameter
extension DataStore {
    func getCheckIns() throws -> [DailyCheckIn] {
        try getCheckIns(limit: nil)
    }
}
