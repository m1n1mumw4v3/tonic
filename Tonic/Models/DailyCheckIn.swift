import Foundation

struct DailyCheckIn: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var checkInDate: Date = Date()
    var createdAt: Date = Date()

    // Wellness scores (0-100)
    var sleepScore: Int = 50
    var energyScore: Int = 50
    var clarityScore: Int = 50
    var moodScore: Int = 50
    var gutScore: Int = 50

    // Computed wellbeing score
    var wellbeingScore: Int {
        WellbeingScore.calculate(
            sleep: sleepScore, energy: energyScore,
            clarity: clarityScore, mood: moodScore, gut: gutScore
        )
    }

    var notes: String?

    // Supplement log for this day
    var supplementLogs: [SupplementLog] = []
}

struct SupplementLog: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var planSupplementId: UUID
    var loggedDate: Date = Date()
    var taken: Bool = false
    var loggedAt: Date = Date()
}

// MARK: - Streak

struct UserStreak: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCheckInDate: Date?

    mutating func recordCheckIn(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        if let lastDate = lastCheckInDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysDiff == 0 means same day, don't change streak
        } else {
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastCheckInDate = date
    }
}
