import Foundation

struct PersonalizationScorer {

    struct ScoreAdjustment {
        let supplementName: String
        let delta: Int
        let reason: String
    }

    /// Evaluates personalization signals against the user's profile and returns score adjustments.
    /// Each signal's `profileField` is mapped to a profile value, and if the value matches `condition`,
    /// the supplement's score is adjusted by `magnitude` (negated for decrease effects).
    static func evaluate(
        profile: UserProfile,
        signals: [SupabasePersonalizationSignal],
        catalog: SupplementCatalog
    ) -> [ScoreAdjustment] {
        var adjustments: [ScoreAdjustment] = []

        for signal in signals {
            guard let profileValue = profileValue(field: signal.profileField, profile: profile) else {
                continue
            }

            guard profileValue.lowercased() == signal.condition.lowercased() else {
                continue
            }

            guard let supplementName = catalog.supplement(byId: signal.supplementId)?.name else {
                continue
            }

            let delta = magnitudeToDelta(signal.magnitude, effect: signal.effect)
            guard delta != 0 else { continue }

            adjustments.append(ScoreAdjustment(
                supplementName: supplementName,
                delta: delta,
                reason: signal.rationale ?? "Adjusted based on your profile"
            ))
        }

        return adjustments
    }

    // MARK: - Profile Field Mapping

    /// Maps a signal's `profileField` to the corresponding value from the user's profile.
    /// Public so that `adjustDosage` can reuse the same field mapping.
    static func profileValue(field: String, profile: UserProfile) -> String? {
        switch field {
        case "diet_type":
            return profile.dietType.rawValue

        case "exercise_frequency":
            return profile.exerciseFrequency.rawValue

        case "stress_level":
            return profile.stressLevel.rawValue

        case "alcohol_weekly":
            return profile.alcoholWeekly.rawValue

        case "caffeine_daily":
            let total = profile.coffeeCupsDaily + profile.teaCupsDaily + profile.energyDrinksDaily
            if total >= 4 { return "high" }
            if total >= 2 { return "moderate" }
            if total >= 1 { return "low" }
            return "none"

        case "sex":
            return profile.sex.rawValue

        case "age_range":
            return ageBracket(profile.age)

        case "baseline_sleep":
            return baselineBracket(profile.baselineSleep)

        case "baseline_energy":
            return baselineBracket(profile.baselineEnergy)

        case "baseline_clarity":
            return baselineBracket(profile.baselineClarity)

        case "baseline_mood":
            return baselineBracket(profile.baselineMood)

        case "baseline_gut":
            return baselineBracket(profile.baselineGut)

        case "is_pregnant":
            return profile.isPregnant ? "true" : "false"

        case "is_breastfeeding":
            return profile.isBreastfeeding ? "true" : "false"

        default:
            return nil
        }
    }

    // MARK: - Helpers

    private static func ageBracket(_ age: Int) -> String {
        switch age {
        case ..<18: return "under_18"
        case 18..<30: return "18-29"
        case 30..<50: return "30-49"
        case 50..<65: return "50-64"
        default: return "65+"
        }
    }

    private static func baselineBracket(_ score: Int) -> String {
        switch score {
        case 0...3: return "low"
        case 4...6: return "moderate"
        default: return "high"
        }
    }

    private static func magnitudeToDelta(_ magnitude: String?, effect: String?) -> Int {
        let baseDelta: Int
        switch magnitude?.lowercased() {
        case "minor": baseDelta = 1
        case "moderate": baseDelta = 2
        case "major": baseDelta = 3
        default: baseDelta = 1
        }

        switch effect?.lowercased() {
        case "decrease": return -baseDelta
        case "increase": return baseDelta
        default: return 0
        }
    }
}
