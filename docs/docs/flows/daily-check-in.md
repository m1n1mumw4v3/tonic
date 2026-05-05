# Daily Check-In

The Today tab is where the user logs supplements and submits the 5-dimension wellbeing slider. The check-in is a single `DailyCheckIn` record per calendar day; supplement logging and wellbeing submission can happen separately and at different times.

**Sources:** `Estus/Features/Today/TodayViewModel.swift`, `Estus/Features/Today/TodayScreen.swift`

## Day phases

`TodayPhase` enum returned by `TodayViewModel.currentPhase(appState:)`:

- `.morning` — midnight to 4:59 PM AND `!appState.isDayComplete`.
- `.evening` — 5:00 PM onward AND `!appState.isDayComplete`.
- `.complete` — `appState.isDayComplete` (every active supplement logged AND wellbeing submitted).

The 17:00 cutoff is a hard-coded hour boundary in `currentPhase`.

## Supplement logging

### State
`supplementStates: [UUID: Bool]` keyed by `PlanSupplement.id`. Initialized from today's existing check-in on `load(appState:)` (so re-opens preserve toggles).

### Timing buckets

- `amTimings`: `emptyStomach`, `morning`, `withFood`.
- `pmTimings`: `afternoon`, `evening`, `bedtime`.

These drive the AM/PM tray UI segmentation. The `amComplete` and `pmComplete` computed properties watch for tray-level completion to fire `amJustCompleted` / `pmJustCompleted` celebration animations.

### Toggling

`toggleSupplement(_:appState:)` flips state, runs `detectTrayCompletions()`, sets `allJustCompleted` if all are taken, then **persists immediately** via `persistSupplementLog(appState:)` which writes/updates today's `DailyCheckIn` through `LocalStorageService.saveCheckIn`.

`takeAll(plan:appState:)` cascades takes with a 60ms stagger and a haptic per supplement, ending with a single persist call.

`takeAllByIDs(_:appState:)` is a partial variant for AM-only or PM-only "take all" buttons.

## Wellbeing check-in (5 sliders)

Triggered by the evening prompt. The user submits scores 0–10 for sleep / energy / clarity / mood / gut.

Defaults are pre-loaded from the most recent `DailyCheckIn` (or baselines if no check-ins exist) in `loadWellbeingDefaults`. This makes nightly check-ins faster.

`trailingAverages: [WellnessDimension: Double]` shows recent-week reference values next to each slider as orientation.

On submit:

1. `appState.todayCheckIn` is updated with the 5 scores and `wellbeingCompleted = true`.
2. The streak is recorded via `appState.streak.recordCheckIn(on: now)`.
3. `LocalStorageService.saveCheckIn(...)` persists.
4. `LocalStorageService.saveStreak(...)` persists.
5. The check-in insight generator runs (see below), produces a `CheckInInsight`, sets `completionInsight`, and the recent-keys tracker records it.
6. The Insight model variant is appended to `appState.insights` and persisted.

## Insight generation post-submit

The `CheckInInsightGenerator.Context` is built from:

- `todayScores` — the just-submitted 5 dimensions.
- `baselines` — from `appState.currentUser.baseline*`.
- `trailingAverages` — already loaded into `TodayViewModel.trailingAverages`.
- `recentCheckIns` — `appState.recentCheckIns` excluding today.
- `streak` — post-record streak.
- `supplementsTakenToday` — from `supplementStates` filtered to taken, joined with plan supplements for names.
- `plan` — `appState.activePlan`.
- `recentlyShownKeys` — `RecentInsightTracker.recentKeys()`.
- `catalog` — `appState.supplementCatalog`.

The 9-rule walk produces a single `CheckInInsight`. See [Check-In Insight Generator](../engines/check-in-insight-generator.md).

## Yesterday retroactive

`loadYesterdayState(appState:)` shows a "yesterday" section if yesterday's check-in had unlogged supplements, allowing retroactive logging. `yesterdaySupplementStates` mirrors the today UI but writes to yesterday's check-in record on toggle.

## Streak forgiveness

The streak system (in `UserStreak.recordCheckIn`) preserves the streak if the user missed exactly one day, once per calendar week. See [Data Models](../architecture/data-models.md#userstreak).

## Persistence

Every supplement toggle and wellbeing submit calls `LocalStorageService.saveCheckIn` immediately. Same-day re-saves merge by date — there is exactly one `DailyCheckIn` per calendar day. Old check-ins (>90 days) are dropped on each save.

## Computed properties on TodayViewModel

- `allTaken`, `amComplete`, `pmComplete` — derived from `supplementStates` over active (non-removed) plan supplements.
- `trailingOverallAverage` — average of all 5 dimensions' trailing averages, or `nil` if any dimension lacks a value.

## What's *not* in the check-in

- The Insights tab's chart data is built separately in `InsightsViewModel` from the same `appState.recentCheckIns`. No duplication.
- The supplement timeline (phases, deltas vs. baseline) is also `InsightsViewModel`'s job — see [Insights & Timeline](insights-timeline.md).

## Cross-references

- [Check-In Insight Generator](../engines/check-in-insight-generator.md) — post-submit copy.
- [Data Models](../architecture/data-models.md) — `DailyCheckIn`, `SupplementLog`, `UserStreak`.
- [Persistence](../architecture/persistence.md) — same-day merge, 90-day retention.
- [Insights & Timeline](insights-timeline.md) — how check-in data fuels longer-range analytics.
