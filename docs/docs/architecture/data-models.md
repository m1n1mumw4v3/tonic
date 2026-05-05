# Data Models

Every model is `Codable` and lives in `Estus/Models/`. This page is a quick reference for the field shapes; for the *behavior* that operates on these models, follow the cross-references.

## `UserProfile`

**File:** `Estus/Models/UserProfile.swift`

The single object that drives every recommendation. Built by `OnboardingViewModel.buildUserProfile()` and then read by `RecommendationEngine`, `PersonalizationScorer`, `SafetyRules`, `SupplementNameMatcher`, and most view-models.

| Group | Fields |
|---|---|
| Identifiers | `id: UUID`, `userId: UUID?` (Supabase), `createdAt`, `updatedAt` |
| Basics | `firstName`, `age`, `dateOfBirth`, `sex` (`Sex` enum), `isPregnant`, `isBreastfeeding`, `isPerimenopausal`, `isOnHormonalBirthControl`, `isOnHRT`, `heightInches`, `weightLbs` |
| Goals | `healthGoals: [HealthGoal]` (max 4) |
| Current usage | `currentSupplements: [String]`, `takingSupplements: Bool` |
| Health | `allergies: [String]`, `medications: [String]`, `takingMedications: Bool`, `medicationIds: [UUID]`, `customMedications: [String]` |
| Lifestyle | `dietType`, `exerciseFrequency`, `coffeeCupsDaily`, `teaCupsDaily`, `energyDrinksDaily`, `sodaCupsDaily`, `alcoholWeekly`, `stressLevel` |
| Baselines (0–10) | `baselineSleep`, `baselineEnergy`, `baselineClarity`, `baselineMood`, `baselineGut` |
| HealthKit | `healthKitEnabled`, `healthMetrics: HealthMetrics?` |
| Notifications | `morningReminderEnabled`, `eveningReminderEnabled`, `morningReminderTime`, `eveningReminderTime` |

### Key enums

- **`Sex`**: `male`, `female`, `intersex`, `prefer_not_to_say`. Drives Iron-male guardrail and dosage rules.
- **`HealthGoal`**: 10 cases: `sleep`, `energy`, `stress_anxiety`, `focus`, `gut_health`, `immune_support`, `muscle_recovery`, `skin_hair_nails`, `heart_health`, `longevity`. Each has `label`, `icon`, `accentColor`, `chipColor`, `shortLabel`. `rawValue` is the key used in `goalSupplementMap`.
- **`DietType`**: `omnivore`, `vegetarian`, `vegan`, `keto`, `paleo`, `pescatarian`, `halal`, `mediterranean`, `low_carb`, `other`.
- **`ExerciseFrequency`**: `none`, `oneToTwo`, `threeToFour`, `fivePlus`.
- **`AlcoholIntake`**: `none`, `oneToThree`, `fourToSeven`, `eightPlus`.
- **`StressLevel`**: `none`, `low`, `moderate`, `high`, `veryHigh`.

## `SupplementPlan`

**File:** `Estus/Models/SupplementPlan.swift`

The output of `RecommendationEngine.generatePlan(for:)`.

```swift
struct SupplementPlan: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var createdAt: Date
    var isActive: Bool
    var version: Int                 // bumped on add/remove
    var aiReasoning: String?         // 2–3 sentence summary built by engine
    var supplements: [PlanSupplement]
}
```

The custom `init(from:)` does a **lossy decode** of `supplements` — if a single `PlanSupplement` fails to decode, it is skipped rather than failing the whole plan. This is intentional for forward/backward compat.

## `PlanSupplement`

```swift
struct PlanSupplement: Codable, Identifiable, Hashable {
    // identity
    var id: UUID
    var planId: UUID?
    var supplementId: UUID?

    // display
    var name: String
    var dosage: String              // human-readable, e.g. "300mg" or "1x daily"
    var dosageMg: Double?           // numeric form (engine recommendation)
    var userOverriddenDosageMg: Double?  // user-set override; nil means "use recommendation"
    var timing: SupplementTiming
    var frequency: SupplementFrequency = .daily
    var category: String
    var sortOrder: Int

    // engine output
    var tier: SupplementTier = .supporting
    var matchedGoals: [String]
    var tierScore: Int              // serialized as "goalOverlapScore"
    var researchNote: String?
    var evidenceLevel: EvidenceLevel?
    var evidenceDisplay: String?

    // user state
    var isTaken: Bool
    var isIncluded: Bool            // toggle on Plan Reveal screen
    var isRemoved: Bool             // soft-delete from Plan tab

    // enriched copy
    var whyInYourPlan: String?
    var dosageRationale: String?
    var expectedTimeline: String?
    var whatToLookFor: String?
    var formAndBioavailability: String?
    var interactionNote: String?
    var interactionWarnings: [InteractionWarning]?
    var formUpgradeNote: String?
    var reasoning: String?
}
```

`PlanSupplement.effectiveDosageMg` returns `userOverriddenDosageMg ?? dosageMg`. Display surfaces (cards, today view) should prefer `effectiveDosageMg` so a user's saved dose isn't clobbered by the engine's original recommendation.

### Tier enum (`SupplementTier`)

| Case | Threshold (final `tierScore`) | Description | Icon |
|---|---|---|---|
| `core` | ≥ 5 | "Strongest evidence match across your goals and profile" | star.fill |
| `targeted` | ≥ 3 | "Good evidence for one or more of your specific goals" | scope |
| `supporting` | < 3 | "Lighter evidence, but may round out your plan" | plus.circle |

`sortOrder`: core=0, targeted=1, supporting=2.

### Timing enum (`SupplementTiming`)

`morning`, `afternoon`, `evening`, `bedtime`, `withFood`, `emptyStomach`. `sortOrder`: emptyStomach=0, morning=1, withFood=2, afternoon=3, evening=4, bedtime=5.

### `InteractionWarning`

```swift
struct InteractionWarning: Codable, Identifiable {
    let id: UUID
    let drugOrClass: String
    let interactionType: String
    let severity: String
    let mechanism: String
    let action: String   // separate_timing | monitor | adjust_dose | avoid
}
```

## `DailyCheckIn`

**File:** `Estus/Models/DailyCheckIn.swift`

```swift
struct DailyCheckIn: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var checkInDate: Date           // calendar day the check-in is FOR
    var createdAt: Date

    // 0–10 sliders
    var sleepScore: Int
    var energyScore: Int
    var clarityScore: Int
    var moodScore: Int
    var gutScore: Int

    // True only after the wellbeing sliders are submitted.
    // A check-in can exist with just supplement logs and wellbeingCompleted=false.
    var wellbeingCompleted: Bool

    var notes: String?
    var supplementLogs: [SupplementLog]

    var wellbeingScore: Double { /* avg of 5 dims via WellbeingScore.calculate */ }
}
```

`score(for: WellnessDimension)` is an extension that returns the right field for a given dimension — used by the insights and check-in insight generator.

### `SupplementLog`

```swift
struct SupplementLog: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var planSupplementId: UUID
    var loggedDate: Date
    var taken: Bool
    var loggedAt: Date
}
```

## `UserStreak`

```swift
struct UserStreak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastCheckInDate: Date?
    var missedYesterday: Bool
    var forgivenessUsedThisWeek: Date?
}
```

`recordCheckIn(on:)`:
- `daysDiff == 0` → no change (same-day re-check-in).
- `daysDiff == 1` → consecutive, increment streak, clear `missedYesterday`.
- `daysDiff == 2 && forgivenessUsedThisWeek == nil` → "forgiveness," still increment streak, mark `missedYesterday=true`, record forgiveness date for the week.
- `daysDiff > 2` (or 2 without forgiveness available) → streak broken, reset to 1.

Forgiveness regenerates each calendar week (week-of-year + year boundary).

## `WellnessDimension`

**File:** `Estus/Models/WellbeingScore.swift`

5 cases: `sleep`, `energy`, `clarity`, `mood`, `gut`. Each has `label`, `icon`, `color`, `lowLabel`, `highLabel`, `prompt`.

Used by the check-in sliders, insights, and the timeline view to map supplements → primary dimension via `SupplementKnowledgeBase.goalToDimension`.

## `Insight`

**File:** `Estus/Models/Insight.swift`

```swift
struct Insight: Codable, Identifiable {
    var id: UUID
    var userId: UUID?
    var createdAt: Date
    var type: InsightType   // correlation | trend | recommendation | milestone
    var title: String
    var body: String
    var dataPointsUsed: Int?
    var dimension: WellnessDimension?
    var isRead: Bool
    var isDismissed: Bool
}
```

There's a converter from `CheckInInsight` → `Insight`: the key prefix (`pb_`, `supp_`, `above_baseline_`, `improving_`, `fun_fact_`) determines `type` and title.

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) consumes `UserProfile` and produces `SupplementPlan`.
- [Daily Check-In](../flows/daily-check-in.md) shows how `DailyCheckIn` is captured.
- [Persistence](persistence.md) for how all of these get encoded to UserDefaults.
