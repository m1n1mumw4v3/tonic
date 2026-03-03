import Foundation

struct DailyCheckIn: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var checkInDate: Date = Date()
    var createdAt: Date = Date()

    // Wellness scores (0-10)
    var sleepScore: Int = 5
    var energyScore: Int = 5
    var clarityScore: Int = 5
    var moodScore: Int = 5
    var gutScore: Int = 5

    // Whether the wellbeing sliders have been submitted (vs just supplement logging)
    var wellbeingCompleted: Bool = true

    // Computed wellbeing score
    var wellbeingScore: Double {
        WellbeingScore.calculate(
            sleep: sleepScore, energy: energyScore,
            clarity: clarityScore, mood: moodScore, gut: gutScore
        )
    }

    var notes: String?

    // Supplement log for this day
    var supplementLogs: [SupplementLog] = []

    enum CodingKeys: String, CodingKey {
        case id, userId, checkInDate, createdAt
        case sleepScore, energyScore, clarityScore, moodScore, gutScore
        case wellbeingCompleted, notes, supplementLogs
    }

    init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        checkInDate: Date = Date(),
        createdAt: Date = Date(),
        sleepScore: Int = 5,
        energyScore: Int = 5,
        clarityScore: Int = 5,
        moodScore: Int = 5,
        gutScore: Int = 5,
        wellbeingCompleted: Bool = true,
        notes: String? = nil,
        supplementLogs: [SupplementLog] = []
    ) {
        self.id = id
        self.userId = userId
        self.checkInDate = checkInDate
        self.createdAt = createdAt
        self.sleepScore = sleepScore
        self.energyScore = energyScore
        self.clarityScore = clarityScore
        self.moodScore = moodScore
        self.gutScore = gutScore
        self.wellbeingCompleted = wellbeingCompleted
        self.notes = notes
        self.supplementLogs = supplementLogs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        checkInDate = try container.decode(Date.self, forKey: .checkInDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sleepScore = try container.decode(Int.self, forKey: .sleepScore)
        energyScore = try container.decode(Int.self, forKey: .energyScore)
        clarityScore = try container.decode(Int.self, forKey: .clarityScore)
        moodScore = try container.decode(Int.self, forKey: .moodScore)
        gutScore = try container.decode(Int.self, forKey: .gutScore)
        // Backward compatible: existing check-ins without this field were full check-ins
        wellbeingCompleted = try container.decodeIfPresent(Bool.self, forKey: .wellbeingCompleted) ?? true
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        supplementLogs = try container.decodeIfPresent([SupplementLog].self, forKey: .supplementLogs) ?? []
    }
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
    var missedYesterday: Bool = false
    var forgivenessUsedThisWeek: Date?

    mutating func recordCheckIn(on date: Date = Date()) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        // Reset forgiveness tracking on new calendar week
        if let forgivenessDate = forgivenessUsedThisWeek {
            let forgivenessWeek = calendar.component(.weekOfYear, from: forgivenessDate)
            let forgivenessYear = calendar.component(.yearForWeekOfYear, from: forgivenessDate)
            let currentWeek = calendar.component(.weekOfYear, from: today)
            let currentYear = calendar.component(.yearForWeekOfYear, from: today)
            if forgivenessWeek != currentWeek || forgivenessYear != currentYear {
                forgivenessUsedThisWeek = nil
            }
        }

        if let lastDate = lastCheckInDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 1 {
                // Consecutive day
                currentStreak += 1
                missedYesterday = false
            } else if daysDiff == 2 && forgivenessUsedThisWeek == nil {
                // Missed exactly 1 day — forgiveness: preserve streak
                currentStreak += 1
                missedYesterday = true
                forgivenessUsedThisWeek = today
            } else if daysDiff > 1 {
                // Streak broken
                currentStreak = 1
                missedYesterday = false
                forgivenessUsedThisWeek = nil
            }
            // daysDiff == 0 means same day, don't change streak
        } else {
            currentStreak = 1
            missedYesterday = false
        }

        longestStreak = max(longestStreak, currentStreak)
        lastCheckInDate = date
    }
}

// MARK: - Dimension Score Accessor

extension DailyCheckIn {
    func score(for dimension: WellnessDimension) -> Int {
        switch dimension {
        case .sleep: return sleepScore
        case .energy: return energyScore
        case .clarity: return clarityScore
        case .mood: return moodScore
        case .gut: return gutScore
        }
    }
}
