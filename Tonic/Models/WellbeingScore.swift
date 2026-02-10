import SwiftUI

// MARK: - Wellness Dimension

enum WellnessDimension: String, CaseIterable, Codable, Identifiable, Hashable {
    case sleep
    case energy
    case clarity
    case mood
    case gut

    var id: String { rawValue }

    var label: String {
        switch self {
        case .sleep:   return "Sleep"
        case .energy:  return "Energy"
        case .clarity: return "Clarity"
        case .mood:    return "Mood"
        case .gut:     return "Gut"
        }
    }

    var icon: String {
        switch self {
        case .sleep:   return "moon.fill"
        case .energy:  return "bolt.fill"
        case .clarity: return "brain.head.profile"
        case .mood:    return "heart.fill"
        case .gut:     return "leaf.fill"
        }
    }

    var shortLabel: String {
        switch self {
        case .sleep:   return "SLP"
        case .energy:  return "NRG"
        case .clarity: return "CLR"
        case .mood:    return "MOD"
        case .gut:     return "GUT"
        }
    }

    var color: Color {
        switch self {
        case .sleep:   return DesignTokens.accentSleep
        case .energy:  return DesignTokens.accentEnergy
        case .clarity: return DesignTokens.accentClarity
        case .mood:    return DesignTokens.accentMood
        case .gut:     return DesignTokens.accentGut
        }
    }

    var lowLabel: String {
        switch self {
        case .sleep:   return "Restless / Broken"
        case .energy:  return "Drained / Fatigued"
        case .clarity: return "Foggy / Scattered"
        case .mood:    return "Low / Flat"
        case .gut:     return "Uncomfortable / Off"
        }
    }

    var highLabel: String {
        switch self {
        case .sleep:   return "Deep & Restorative"
        case .energy:  return "Vibrant & Sustained"
        case .clarity: return "Sharp & Locked In"
        case .mood:    return "Positive & Balanced"
        case .gut:     return "Smooth & Settled"
        }
    }
}

// MARK: - Wellbeing Score Calculator

enum WellbeingScore {
    static func calculate(sleep: Int, energy: Int, clarity: Int, mood: Int, gut: Int) -> Double {
        Double(sleep + energy + clarity + mood + gut) / 5.0
    }

    static func calculate(scores: [WellnessDimension: Int]) -> Double {
        let sleep = scores[.sleep] ?? 5
        let energy = scores[.energy] ?? 5
        let clarity = scores[.clarity] ?? 5
        let mood = scores[.mood] ?? 5
        let gut = scores[.gut] ?? 5
        return calculate(sleep: sleep, energy: energy, clarity: clarity, mood: mood, gut: gut)
    }
}
