# State Management

Estus uses Swift's Observation framework throughout. The contract is set at the root and propagated via `@Environment(AppState.self)`.

**Source:** `Estus/App/AppState.swift`

## `AppState` — the singleton-ish root

`AppState` is an `@Observable` class instantiated once in `EstusApp` and injected into the root view via `.environment(...)`. Every feature reads from it.

What it owns:

| Property | Purpose |
|---|---|
| `isOnboardingComplete` | Mirrored to `UserDefaults["estus_onboarding_complete"]` via `didSet`. |
| `isSubscribed` | RevenueCat subscription state (defaults to `true` for now). |
| `currentUser: UserProfile?` | The active profile. `nil` until onboarding finishes or restore succeeds. |
| `activePlan: SupplementPlan?` | The current plan. |
| `streak: UserStreak` | Streak counter. |
| `todayCheckIn: DailyCheckIn?` | Today's check-in if it exists; replaced (not appended) per day. |
| `recentCheckIns: [DailyCheckIn]` | Last 30 loaded from storage on session restore. |
| `insights: [Insight]` | Generated insights, persisted. |
| `authService` | Supabase auth wrapper. |
| `deepProfileService` | Owner of completed deep-profile modules (sleep, gut, hormonal, etc.). |
| `healthKitService` | HealthKit sync. |
| `supplementCatalog: SupplementCatalog` | The in-memory catalog used by the engine. Populated async at app launch. |
| `medications: [DBMedication]` | Supabase medications table, used for med picker + interaction key lookup. |
| `drugInteractions: [DBDrugInteraction]` | Supabase drug interactions table; passed into the engine. |
| `isRestoringSession: Bool` | Splash-screen guard. |
| `selectedTab`, `showSettings`, `showPaywall` | Navigation state. |

## Computed properties worth knowing

| Computed | What it returns |
|---|---|
| `userName` | `currentUser?.firstName ?? "there"` |
| `hasCheckedInToday` | True if `todayCheckIn` exists and its date is today. |
| `hasCompletedWellbeingToday` | True if `todayCheckIn?.wellbeingCompleted == true` (5 sliders submitted, not just supplement logging). |
| `todayWellbeingScore` | The averaged 0–10 wellbeing score for today. |
| `mostRecentWellbeingScore` | Most recent check-in where `wellbeingCompleted` is true. |
| `isDayComplete` | Both wellbeing submitted AND every active supplement logged as taken. |

## Lifecycle methods

### `loadSupplementCatalog()`
Async. Calls `SupplementService.loadCatalog()`. If Supabase returns 0 supplements (RLS misconfig) or throws, falls back to `populateFromStatic()`. Populates `drugInteractions` only on the success path.

### `loadMedications()`
Async. Fetches `DBMedication` records from Supabase. Logs success/failure. The medication picker UI degrades to `MedicationKnowledgeBase` static data on failure.

### `restoreSessionIfNeeded()`
Async, called once at app launch. Reads profile, plan, recent check-ins, today check-in, streak, insights, deep-profile modules from `LocalStorageService`. Auto-flips `isOnboardingComplete = true` if both profile and plan are present. If the flag was set but data is missing, resets to onboarding.

### `signOut()`
Clears all state and removes all `estus_*` keys from `UserDefaults`. Note: `supplementCatalog` is *not* cleared because it's reference data, not user data.

### `loadDemoData()`
Demo-mode bootstrap. Populates the catalog from static, builds a fake `UserProfile`, runs `engine.generatePlan` against it, generates 30 days of synthetic check-ins with progressive scores, and seeds three sample insights. Used for design reviews and previews.

## Observation patterns

- Views read with `@Environment(AppState.self) private var appState`.
- Mutations happen directly on properties — Observation handles re-rendering.
- View models that need to react to AppState changes either receive it via `load(appState:)` (capturing a reference) or read it inside computed properties.

## Why no `ObservableObject`

Swift's Observation framework is the modern replacement and is required by the codebase per `CLAUDE.md`. It's more granular (only views that actually read a property re-render) and avoids the property-wrapper noise of `@Published`/`@StateObject`. Don't reintroduce the old pattern.

## Cross-references

- [Persistence](persistence.md) — how `AppState` reads/writes via `LocalStorageService`.
- [Data Models](data-models.md) — what's in `UserProfile`, `SupplementPlan`, etc.
