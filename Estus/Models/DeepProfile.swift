import Foundation
import SwiftUI

// MARK: - Response Value

enum ResponseValue: Codable, Equatable {
    case string(String)
    case strings([String])

    // Codable
    enum CodingKeys: String, CodingKey {
        case type, value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "string":
            let val = try container.decode(String.self, forKey: .value)
            self = .string(val)
        case "strings":
            let val = try container.decode([String].self, forKey: .value)
            self = .strings(val)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .string(let val):
            try container.encode("string", forKey: .type)
            try container.encode(val, forKey: .value)
        case .strings(let val):
            try container.encode("strings", forKey: .type)
            try container.encode(val, forKey: .value)
        }
    }

    var stringValue: String? {
        if case .string(let val) = self { return val }
        return nil
    }

    var stringsValue: [String]? {
        if case .strings(let val) = self { return val }
        return nil
    }
}

// MARK: - Deep Profile Module (Persisted)

struct DeepProfileModule: Codable, Identifiable {
    var id: UUID = UUID()
    var moduleId: DeepProfileModuleType
    var responses: [String: ResponseValue]
    var completedAt: Date
    var updatedAt: Date

    init(moduleId: DeepProfileModuleType, responses: [String: ResponseValue]) {
        self.moduleId = moduleId
        self.responses = responses
        self.completedAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Module Type

enum DeepProfileModuleType: String, Codable, CaseIterable, Identifiable {
    case sleepCircadian = "sleep_circadian"
    case hormonalMetabolic = "hormonal_metabolic"
    case gutHealth = "gut_health"
    case stressNervousSystem = "stress_nervous_system"
    case cognitiveFunction = "cognitive_function"
    case musculoskeletalRecovery = "musculoskeletal_recovery"
    case environmentExposures = "environment_exposures"
    case labWorkBiomarkers = "lab_work_biomarkers"
    case skinHairNails = "skin_hair_nails"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleepCircadian: return "Sleep & Circadian"
        case .hormonalMetabolic: return "Hormonal & Metabolic"
        case .gutHealth: return "Gut Health"
        case .stressNervousSystem: return "Stress & Nervous System"
        case .cognitiveFunction: return "Cognitive Function"
        case .musculoskeletalRecovery: return "Musculoskeletal & Recovery"
        case .environmentExposures: return "Environment & Exposures"
        case .labWorkBiomarkers: return "Lab Work & Biomarkers"
        case .skinHairNails: return "Skin, Hair & Nails"
        }
    }

    var icon: String {
        switch self {
        case .sleepCircadian: return "moon.stars.fill"
        case .hormonalMetabolic: return "flame.fill"
        case .gutHealth: return "leaf.fill"
        case .stressNervousSystem: return "brain.head.profile.fill"
        case .cognitiveFunction: return "lightbulb.fill"
        case .musculoskeletalRecovery: return "figure.strengthtraining.traditional"
        case .environmentExposures: return "sun.max.fill"
        case .labWorkBiomarkers: return "cross.case.fill"
        case .skinHairNails: return "sparkles"
        }
    }

    var accentColor: Color {
        switch self {
        case .sleepCircadian: return DesignTokens.accentSleep
        case .hormonalMetabolic: return DesignTokens.accentHeart
        case .gutHealth: return DesignTokens.accentGut
        case .stressNervousSystem: return DesignTokens.accentClarity
        case .cognitiveFunction: return DesignTokens.accentMood
        case .musculoskeletalRecovery: return DesignTokens.accentMuscle
        case .environmentExposures: return DesignTokens.accentEnergy
        case .labWorkBiomarkers: return DesignTokens.accentLongevity
        case .skinHairNails: return DesignTokens.accentSkin
        }
    }

    var questionCount: Int {
        switch self {
        case .sleepCircadian: return 10
        case .hormonalMetabolic: return 8
        case .gutHealth: return 10
        case .stressNervousSystem: return 8
        case .cognitiveFunction: return 8
        case .musculoskeletalRecovery: return 8
        case .environmentExposures: return 8
        case .labWorkBiomarkers: return 8
        case .skinHairNails: return 9
        }
    }

    var estimatedSeconds: Int {
        switch self {
        case .sleepCircadian: return 150
        case .hormonalMetabolic: return 120
        case .gutHealth: return 150
        case .stressNervousSystem: return 120
        case .cognitiveFunction: return 120
        case .musculoskeletalRecovery: return 120
        case .environmentExposures: return 120
        case .labWorkBiomarkers: return 120
        case .skinHairNails: return 150
        }
    }

    var estimatedTimeLabel: String {
        let minutes = estimatedSeconds / 60
        if estimatedSeconds % 60 > 0 {
            return "~\(minutes + 1) min"
        }
        return "~\(minutes) min"
    }

    var benefitCopy: String {
        switch self {
        case .sleepCircadian: return "Complete your sleep profile to refine your magnesium timing."
        case .stressNervousSystem: return "Share your stress patterns to optimize your adaptogen dosing."
        case .cognitiveFunction: return "Map your cognitive goals to sharpen your nootropic stack."
        case .hormonalMetabolic: return "Add metabolic data to fine-tune your vitamin D and CoQ10 dosing."
        case .gutHealth: return "Detail your gut health to personalize your probiotic recommendation."
        case .musculoskeletalRecovery: return "Log your recovery patterns to adjust your creatine and collagen timing."
        case .labWorkBiomarkers: return "Add lab results for evidence-based dosage adjustments."
        case .environmentExposures: return "Share your environment to identify targeted antioxidant needs."
        case .skinHairNails: return "Detail your skin, hair, and nail concerns to target the right compounds and doses."
        }
    }

    /// Related health goals — used to determine which modules to recommend
    var relatedGoals: [HealthGoal] {
        switch self {
        case .sleepCircadian: return [.sleep]
        case .hormonalMetabolic: return [.energy, .muscleDevelopment, .longevity]
        case .gutHealth: return [.gutHealth]
        case .stressNervousSystem: return [.stressAnxiety]
        case .cognitiveFunction: return [.focus]
        case .musculoskeletalRecovery: return [.muscleDevelopment]
        case .environmentExposures: return [.immunity, .longevity, .skinHairNails]
        case .labWorkBiomarkers: return [.heartHealth, .longevity, .energy]
        case .skinHairNails: return [.skinHairNails]
        }
    }
}

// MARK: - Question Condition

/// Closure-based predicate that determines whether a question is shown.
/// Evaluated against the user profile and the current module's collected responses.
struct QuestionCondition {
    let evaluate: (UserProfile, [String: ResponseValue]) -> Bool
}

// MARK: - Input Type

enum DeepProfileInputType {
    case singleSelect([SelectOption])
    case multiSelect([SelectOption])
    case timeInput
    case numericInput(unit: String, range: ClosedRange<Int>)
    case slider(min: Int, max: Int, step: Int)
}

// MARK: - Select Option

struct SelectOption: Identifiable {
    let value: String
    let label: String

    var id: String { value }
}

// MARK: - Question

struct DeepProfileQuestion: Identifiable {
    let id: String
    let text: String
    var subtext: String? = nil
    let inputType: DeepProfileInputType
    var condition: QuestionCondition? = nil
    var isOptional: Bool = false
}

// MARK: - Module Config

struct DeepProfileModuleConfig {
    let type: DeepProfileModuleType
    let introDescription: String
    var disclaimer: String? = nil
    let questions: [DeepProfileQuestion]
}
