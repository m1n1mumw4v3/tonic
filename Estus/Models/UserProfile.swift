import Foundation
import SwiftUI

struct UserProfile: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // Basic info
    var firstName: String = ""
    var age: Int = 30
    var dateOfBirth: Date?
    var sex: Sex = .preferNotToSay
    var isPregnant: Bool = false
    var isBreastfeeding: Bool = false
    var heightInches: Int?
    var weightLbs: Int?

    // Goals
    var healthGoals: [HealthGoal] = []

    // Current supplements
    var currentSupplements: [String] = []
    var takingSupplements: Bool = false

    // Health constraints
    var allergies: [String] = []
    var medications: [String] = []
    var takingMedications: Bool = false

    // Structured medication data (from Supabase medications table)
    var medicationIds: [UUID] = []
    var customMedications: [String] = []

    // Lifestyle
    var dietType: DietType = .omnivore
    var customDietText: String = ""
    var exerciseFrequency: ExerciseFrequency = .none
    var coffeeCupsDaily: Int = 0
    var teaCupsDaily: Int = 0
    var energyDrinksDaily: Int = 0
    var sodaCupsDaily: Int = 0
    var alcoholWeekly: AlcoholIntake = .none
    var stressLevel: StressLevel = .moderate

    // Baselines (0-10)
    var baselineSleep: Int = 5
    var baselineEnergy: Int = 5
    var baselineClarity: Int = 5
    var baselineMood: Int = 5
    var baselineGut: Int = 5

    // Apple Health
    var healthKitEnabled: Bool = false
    var healthMetrics: HealthMetrics?

    // Notification reminders
    var morningReminderEnabled: Bool = false
    var eveningReminderEnabled: Bool = false
    var morningReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
    var eveningReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!

    enum CodingKeys: String, CodingKey {
        case id, userId, createdAt, updatedAt
        case firstName, age, dateOfBirth, sex, isPregnant, isBreastfeeding
        case heightInches, weightLbs
        case healthGoals, currentSupplements, takingSupplements
        case allergies, medications, takingMedications
        case medicationIds, customMedications
        case dietType, customDietText, exerciseFrequency
        case coffeeCupsDaily, teaCupsDaily, energyDrinksDaily, sodaCupsDaily
        case alcoholWeekly, stressLevel
        case baselineSleep, baselineEnergy, baselineClarity, baselineMood, baselineGut
        case healthKitEnabled, healthMetrics
        case morningReminderEnabled, eveningReminderEnabled
        case morningReminderTime, eveningReminderTime
    }
}

// MARK: - Resilient Decoder

extension UserProfile {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName) ?? ""
        age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 30
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth)
        sex = try container.decodeIfPresent(Sex.self, forKey: .sex) ?? .preferNotToSay
        isPregnant = try container.decodeIfPresent(Bool.self, forKey: .isPregnant) ?? false
        isBreastfeeding = try container.decodeIfPresent(Bool.self, forKey: .isBreastfeeding) ?? false
        heightInches = try container.decodeIfPresent(Int.self, forKey: .heightInches)
        weightLbs = try container.decodeIfPresent(Int.self, forKey: .weightLbs)
        healthGoals = try container.decodeIfPresent([HealthGoal].self, forKey: .healthGoals) ?? []
        currentSupplements = try container.decodeIfPresent([String].self, forKey: .currentSupplements) ?? []
        takingSupplements = try container.decodeIfPresent(Bool.self, forKey: .takingSupplements) ?? false
        allergies = try container.decodeIfPresent([String].self, forKey: .allergies) ?? []
        medications = try container.decodeIfPresent([String].self, forKey: .medications) ?? []
        takingMedications = try container.decodeIfPresent(Bool.self, forKey: .takingMedications) ?? false
        medicationIds = try container.decodeIfPresent([UUID].self, forKey: .medicationIds) ?? []
        customMedications = try container.decodeIfPresent([String].self, forKey: .customMedications) ?? []
        dietType = try container.decodeIfPresent(DietType.self, forKey: .dietType) ?? .omnivore
        customDietText = try container.decodeIfPresent(String.self, forKey: .customDietText) ?? ""
        exerciseFrequency = try container.decodeIfPresent(ExerciseFrequency.self, forKey: .exerciseFrequency) ?? .none
        coffeeCupsDaily = try container.decodeIfPresent(Int.self, forKey: .coffeeCupsDaily) ?? 0
        teaCupsDaily = try container.decodeIfPresent(Int.self, forKey: .teaCupsDaily) ?? 0
        energyDrinksDaily = try container.decodeIfPresent(Int.self, forKey: .energyDrinksDaily) ?? 0
        sodaCupsDaily = try container.decodeIfPresent(Int.self, forKey: .sodaCupsDaily) ?? 0
        alcoholWeekly = try container.decodeIfPresent(AlcoholIntake.self, forKey: .alcoholWeekly) ?? .none
        stressLevel = try container.decodeIfPresent(StressLevel.self, forKey: .stressLevel) ?? .moderate
        baselineSleep = try container.decodeIfPresent(Int.self, forKey: .baselineSleep) ?? 5
        baselineEnergy = try container.decodeIfPresent(Int.self, forKey: .baselineEnergy) ?? 5
        baselineClarity = try container.decodeIfPresent(Int.self, forKey: .baselineClarity) ?? 5
        baselineMood = try container.decodeIfPresent(Int.self, forKey: .baselineMood) ?? 5
        baselineGut = try container.decodeIfPresent(Int.self, forKey: .baselineGut) ?? 5
        healthKitEnabled = try container.decodeIfPresent(Bool.self, forKey: .healthKitEnabled) ?? false
        healthMetrics = try container.decodeIfPresent(HealthMetrics.self, forKey: .healthMetrics)
        morningReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .morningReminderEnabled) ?? false
        eveningReminderEnabled = try container.decodeIfPresent(Bool.self, forKey: .eveningReminderEnabled) ?? false
        morningReminderTime = try container.decodeIfPresent(Date.self, forKey: .morningReminderTime) ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 0))!
        eveningReminderTime = try container.decodeIfPresent(Date.self, forKey: .eveningReminderTime) ?? Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!
    }
}

// MARK: - Enums

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male
    case female
    case other
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Non-binary"
        case .preferNotToSay: return "Prefer not to say"
        }
    }
}

enum HealthGoal: String, Codable, CaseIterable, Identifiable {
    static let maxSelection = 4

    case energy
    case sleep
    case stressAnxiety = "stress_anxiety"
    case focus
    case gutHealth = "gut_health"
    case immunity = "immune_support"
    case muscleDevelopment = "muscle_recovery"
    case skinHairNails = "skin_hair_nails"
    case heartHealth = "heart_health"
    case longevity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .energy: return "More energy"
        case .sleep: return "Better sleep"
        case .stressAnxiety: return "Stress & anxiety relief"
        case .focus: return "Mental clarity & focus"
        case .gutHealth: return "Gut health & digestion"
        case .immunity: return "Immune support"
        case .muscleDevelopment: return "Muscle growth & recovery"
        case .skinHairNails: return "Skin, hair & nails"
        case .heartHealth: return "Heart health"
        case .longevity: return "Longevity"
        }
    }

    var icon: String {
        switch self {
        case .energy: return "bolt.fill"
        case .sleep: return "moon.fill"
        case .stressAnxiety: return "figure.mind.and.body"
        case .focus: return "brain.head.profile"
        case .gutHealth: return "leaf.fill"
        case .immunity: return "shield.fill"
        case .muscleDevelopment: return "figure.strengthtraining.traditional"
        case .skinHairNails: return "sparkles"
        case .heartHealth: return "heart.fill"
        case .longevity: return "infinity"
        }
    }

    var accentColor: Color {
        switch self {
        case .energy:          return DesignTokens.accentEnergy
        case .sleep:           return DesignTokens.accentSleep
        case .stressAnxiety:   return DesignTokens.accentMood
        case .focus:           return DesignTokens.accentClarity
        case .gutHealth:       return DesignTokens.accentGut
        case .immunity:        return DesignTokens.accentImmunity
        case .muscleDevelopment: return DesignTokens.accentMuscle
        case .skinHairNails:   return DesignTokens.accentSkin
        case .heartHealth:     return DesignTokens.accentHeart
        case .longevity:       return DesignTokens.accentLongevity
        }
    }

    var shortLabel: String {
        switch self {
        case .energy: return "Energy"
        case .sleep: return "Sleep"
        case .stressAnxiety: return "Stress"
        case .focus: return "Focus"
        case .gutHealth: return "Gut"
        case .immunity: return "Immunity"
        case .muscleDevelopment: return "Muscle"
        case .skinHairNails: return "Skin"
        case .heartHealth: return "Heart"
        case .longevity: return "Longevity"
        }
    }
}

enum DietType: String, Codable, CaseIterable, Identifiable {
    case omnivore
    case vegetarian
    case vegan
    case keto
    case paleo
    case pescatarian
    case halal
    case mediterranean
    case lowCarb = "low_carb"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .omnivore: return "No specific diet (Omnivore)"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .pescatarian: return "Pescatarian"
        case .halal: return "Halal"
        case .mediterranean: return "Mediterranean"
        case .lowCarb: return "Low-Carb"
        case .other: return "Other"
        }
    }
}

enum ExerciseFrequency: String, Codable, CaseIterable, Identifiable {
    case none
    case oneToTwo = "1-2_weekly"
    case threeToFour = "3-4_weekly"
    case fivePlus = "5+_weekly"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .oneToTwo: return "1-2x / week"
        case .threeToFour: return "3-4x / week"
        case .fivePlus: return "5+ / week"
        }
    }
}

enum AlcoholIntake: String, Codable, CaseIterable, Identifiable {
    case none
    case oneToThree = "1-3_drinks"
    case fourToSeven = "4-7_drinks"
    case eightPlus = "8+_drinks"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .oneToThree: return "1-3 drinks / week"
        case .fourToSeven: return "4-7 drinks / week"
        case .eightPlus: return "8+ drinks / week"
        }
    }
}

enum StressLevel: String, Codable, CaseIterable, Identifiable {
    case none
    case low
    case moderate
    case high
    case veryHigh = "very_high"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }
}
