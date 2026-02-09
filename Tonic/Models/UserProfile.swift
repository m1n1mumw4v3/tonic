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
    var sex: Sex = .preferNotToSay
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

    // Lifestyle
    var dietType: DietType = .omnivore
    var exerciseFrequency: ExerciseFrequency = .none
    var coffeeCupsDaily: Int = 0
    var teaCupsDaily: Int = 0
    var alcoholWeekly: AlcoholIntake = .none
    var stressLevel: StressLevel = .moderate

    // Baselines (0-100)
    var baselineSleep: Int = 50
    var baselineEnergy: Int = 50
    var baselineClarity: Int = 50
    var baselineMood: Int = 50
    var baselineGut: Int = 50

    // Apple Health
    var healthKitEnabled: Bool = false
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
    case sleep
    case energy
    case focus
    case gutHealth = "gut_health"
    case immunity
    case fitnessRecovery = "fitness_recovery"
    case stressAnxiety = "stress_anxiety"
    case skinHairNails = "skin_hair_nails"
    case longevity

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sleep: return "Better sleep"
        case .energy: return "More energy"
        case .focus: return "Mental clarity & focus"
        case .stressAnxiety: return "Stress & anxiety relief"
        case .gutHealth: return "Gut health & digestion"
        case .immunity: return "Immune support"
        case .fitnessRecovery: return "Fitness recovery"
        case .skinHairNails: return "Skin, hair & nails"
        case .longevity: return "Longevity"
        }
    }

    var icon: String {
        switch self {
        case .sleep: return "moon.fill"
        case .energy: return "bolt.fill"
        case .focus: return "brain.head.profile"
        case .stressAnxiety: return "heart.fill"
        case .gutHealth: return "leaf.fill"
        case .immunity: return "shield.fill"
        case .fitnessRecovery: return "figure.run"
        case .skinHairNails: return "sparkles"
        case .longevity: return "infinity"
        }
    }

    var accentColor: Color {
        switch self {
        case .sleep:           return DesignTokens.accentSleep
        case .energy:          return DesignTokens.accentEnergy
        case .focus:           return DesignTokens.accentClarity
        case .stressAnxiety:   return DesignTokens.accentMood
        case .gutHealth:       return DesignTokens.accentGut
        case .immunity:        return DesignTokens.info
        case .fitnessRecovery: return DesignTokens.positive
        case .skinHairNails:   return DesignTokens.negative
        case .longevity:       return DesignTokens.accentLongevity
        }
    }

    var shortLabel: String {
        switch self {
        case .sleep: return "Sleep"
        case .energy: return "Energy"
        case .focus: return "Focus"
        case .stressAnxiety: return "Stress"
        case .gutHealth: return "Gut"
        case .immunity: return "Immunity"
        case .fitnessRecovery: return "Recovery"
        case .skinHairNails: return "Skin"
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
