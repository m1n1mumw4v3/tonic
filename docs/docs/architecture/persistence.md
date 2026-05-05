# Persistence

User data is persisted to `UserDefaults` via `LocalStorageService`, which conforms to the abstract `DataStore` protocol. The protocol is the seam where Supabase will swap in for milestone M3+.

**Sources:** `Estus/Services/DataStore.swift`, `Estus/Services/LocalStorageService.swift`

## `DataStore` protocol

```swift
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

    func saveDeepProfileModule(_ module: DeepProfileModule) throws
    func getDeepProfileModules() throws -> [DeepProfileModule]
    func deleteDeepProfileModule(_ moduleId: DeepProfileModuleType) throws
}
```

A default extension provides `getCheckIns()` (no limit) so callers can opt into "give me everything."

## `LocalStorageService` — the M1/M2 implementation

Backed by `UserDefaults.standard`. Each method JSON-encodes/decodes via stored `JSONEncoder`/`JSONDecoder` instances.

### Storage keys

| Key | Stores |
|---|---|
| `estus_user_profile` | `UserProfile` |
| `estus_active_plan` | `SupplementPlan` |
| `estus_check_ins` | `[DailyCheckIn]` |
| `estus_streak` | `UserStreak` |
| `estus_insights` | `[Insight]` |
| `estus_deep_profile` | `[DeepProfileModule]` |
| `estus_onboarding_complete` | `Bool` (set directly by `AppState`'s `didSet`, not via this service) |

### Notable behaviors

- **Check-in dedup:** `saveCheckIn` finds an existing entry on the same calendar day and replaces it; otherwise appends. Then filters to the last 90 days before writing back. This means there's exactly one check-in per day.
- **Sort order:** `getCheckIns(limit:)` always returns in descending date order (most recent first).
- **Today's check-in:** `getTodayCheckIn()` is implemented as `getCheckIns(limit: 7).first { isDateInToday($0.checkInDate) }` — the 7-record limit is just an optimization.
- **Deep profile dedup:** `saveDeepProfileModule` replaces by `moduleId`, so re-completing the Sleep module overwrites the prior response.

### Lossy-decode safety net

`SupplementPlan` and `PlanSupplement` use custom `init(from:)` decoders that *skip* individual supplements that fail to decode rather than failing the whole plan. This protects users from being locked out by schema changes that affect only some entries.

`UserStreak` and `DailyCheckIn` similarly use `decodeIfPresent` so that adding new fields doesn't break existing data.

## Lifecycle

### Save
- **Onboarding completion** (`OnboardingFlow.completeOnboarding()` and `dismissPaywall()`) saves both profile and plan.
- **Today screen** writes the day's check-in any time the user toggles a supplement or submits wellbeing sliders.
- **Plan management** (`PlanViewModel`) writes back when supplements are added/removed/restored.
- **Insights** save whenever the engine appends a new generated insight.
- **HealthKit sync** updates `currentUser.healthMetrics` and re-saves the profile.

### Restore
`AppState.restoreSessionIfNeeded()` reads everything in sequence at app launch. Each step is wrapped in `do/catch` and logs a warning on decode failure rather than aborting. After the loads, two consistency checks fire:

1. If profile + plan both exist → flip `isOnboardingComplete = true`.
2. If `isOnboardingComplete` is true but profile or plan is missing → reset onboarding (treat the user as fresh).

### Sign-out
`AppState.signOut()` clears in-memory state, then removes the seven `estus_*` keys from `UserDefaults`. The supplement catalog is preserved because it's reference data.

## What persists *not* via `DataStore`

- `RecentInsightTracker` (in `CheckInInsightGenerator.swift`) writes to `UserDefaults["recentInsightKeys"]` directly to track the last 5 shown insight keys for freshness filtering.
- `isOnboardingComplete` writes to `UserDefaults["estus_onboarding_complete"]` directly via `didSet` on `AppState`.

These are conscious shortcuts — they're tiny scalar/array values that don't justify a `DataStore` method. If the persistence layer migrates to Supabase, they should move too.

## Cross-references

- [State Management](state-management.md) — how `AppState` calls into `LocalStorageService`.
- [Data Models](data-models.md) — `Codable` shapes that get encoded/decoded.
