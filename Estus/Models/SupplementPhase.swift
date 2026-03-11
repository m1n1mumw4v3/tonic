import Foundation

// MARK: - Supplement Phase

enum SupplementPhase: Int, CaseIterable, Comparable, Codable {
    case loading = 1
    case adaptation = 2
    case onset = 3
    case steadyState = 4

    var label: String {
        switch self {
        case .loading:     return "Loading"
        case .adaptation:  return "Adaptation"
        case .onset:       return "Onset"
        case .steadyState: return "Steady State"
        }
    }

    var shortLabel: String {
        switch self {
        case .loading:     return "LOAD"
        case .adaptation:  return "ADAPT"
        case .onset:       return "ONSET"
        case .steadyState: return "STEADY"
        }
    }

    var phaseNumber: Int { rawValue }

    static func < (lhs: SupplementPhase, rhs: SupplementPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Phase Durations

struct SupplementPhaseDurations {
    let loadingDays: Int
    let adaptationDays: Int
    let onsetDays: Int

    func startDay(for phase: SupplementPhase) -> Int {
        switch phase {
        case .loading:     return 0
        case .adaptation:  return loadingDays
        case .onset:       return loadingDays + adaptationDays
        case .steadyState: return loadingDays + adaptationDays + onsetDays
        }
    }

    func durationDays(for phase: SupplementPhase) -> Int {
        switch phase {
        case .loading:     return loadingDays
        case .adaptation:  return adaptationDays
        case .onset:       return onsetDays
        case .steadyState: return 0  // open-ended
        }
    }

    var totalDaysToSteadyState: Int {
        loadingDays + adaptationDays + onsetDays
    }
}

// MARK: - Phase State

struct SupplementPhaseState {
    let currentPhase: SupplementPhase
    let dayInPhase: Int
    let totalDaysInPhase: Int
    let phaseProgress: Double
    let isComplete: Bool
    let hasReachedOnset: Bool

    static func compute(daysOnPlan: Int, durations: SupplementPhaseDurations) -> SupplementPhaseState {
        let day = max(0, daysOnPlan)

        for phase in SupplementPhase.allCases {
            let start = durations.startDay(for: phase)
            let duration = durations.durationDays(for: phase)

            if phase == .steadyState {
                return SupplementPhaseState(
                    currentPhase: .steadyState,
                    dayInPhase: day - start,
                    totalDaysInPhase: 0,
                    phaseProgress: 1.0,
                    isComplete: true,
                    hasReachedOnset: true
                )
            }

            if duration == 0 { continue }

            if day < start + duration {
                let dayIn = day - start
                let progress = Double(dayIn) / Double(duration)
                return SupplementPhaseState(
                    currentPhase: phase,
                    dayInPhase: dayIn + 1,
                    totalDaysInPhase: duration,
                    phaseProgress: min(1.0, max(0, progress)),
                    isComplete: false,
                    hasReachedOnset: phase >= .onset
                )
            }
        }

        // Fallback: past all phases
        return SupplementPhaseState(
            currentPhase: .steadyState,
            dayInPhase: day - durations.totalDaysToSteadyState,
            totalDaysInPhase: 0,
            phaseProgress: 1.0,
            isComplete: true,
            hasReachedOnset: true
        )
    }
}
