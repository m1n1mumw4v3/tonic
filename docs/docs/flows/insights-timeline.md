# Insights & Timeline

The Insights tab shows two things: (1) wellbeing trends over a 7-day or 30-day window, and (2) a per-supplement timeline that maps each supplement to a wellness dimension and reports current phase + delta vs. baseline.

**Sources:** `Estus/Features/Insights/InsightsViewModel.swift`, `Estus/Features/Insights/InsightsScreen.swift`, `Estus/Utilities/SupplementKnowledgeBase.swift` (phase data)

## Period selector

`InsightsPeriod` enum: `.week` (7 days, "EEE" formatter) and `.month` (30 days, "d" formatter). The view-model's `load(appState:period:)` rebuilds everything period-scoped.

## `load(appState:period:)` outputs

| Property | What it is | Computed when |
|---|---|---|
| `currentStreak`, `longestStreak`, `totalCheckIns` | Counters from `appState.streak` and `recentCheckIns.count` | Always |
| `baselineScore` | Mean of all 5 baselines from `currentUser` | If profile exists |
| `periodData: [DayData]` | One per check-in in the period: `(score, dayLabel, date, isToday)` | If any check-ins exist |
| `periodAverage: Double?` | Average of period's `wellbeingScore` values | Same |
| `trendDirection: TrendInfo?` | Up / Down / Steady label (icon + label + color) | If period has ≥ 3 check-ins |
| `dimensionAverages: [DimensionAverage]` | Per-dimension average + change vs. earlier half | Always; `change` only if ≥ 4 check-ins |
| `adherencePercentage: String` | "%" of taken supplement logs across all check-ins | If any logs exist |

### Trend computation

```swift
halfCount = max(1, periodCheckIns.count / 2)
recentAvg = average(suffix(halfCount).wellbeingScore)
earlierAvg = average(prefix(halfCount).wellbeingScore)
diff = recentAvg - earlierAvg
```

Bands:

- `diff > 0.3` → "Trending up X.X pts from {periodLabel}" (positive color)
- `diff < -0.3` → "Down X.X pts from {periodLabel}" (negative color)
- otherwise → "Holding steady" (secondary color)

The `periodLabel` is `"last week"` for `.week` period and `"prior period"` for `.month`.

### Dimension averages

For each `WellnessDimension`:

- `average` = mean of period scores for that dimension.
- `change` = recent-half-avg minus earlier-half-avg, computed only if `periodCheckIns.count >= 4`. Otherwise `nil`.

## `loadTimeline(appState:)` — the supplement timeline

Independent from `load(appState:period:)`. Renders one card per active (non-removed) supplement.

For each supplement:

1. **Phase durations** from `SupplementKnowledgeBase.phaseDurations(for: name)`. If `nil`, the supplement is skipped (no phase data).
2. **Phase state** via `SupplementPhaseState.compute(daysOnPlan:durations:)`. Computes `currentPhase` ∈ `{early, accumulation, onset, steadyState}` and progress within the phase.
3. **Phase content** via `SupplementKnowledgeBase.phaseContentFor(supplement:phase:)`.
4. **Primary dimension** = first matched goal that maps to a dimension via `goalToDimension`, defaulting to `.energy`.
5. **Baseline score** = the user's matching baseline (from `currentUser.baseline*`), or 5.0 fallback.
6. **Current average** = mean of last 7 check-in scores for the primary dimension. **Computed only if `recentCheckIns.suffix(7).count >= 3`**, else `nil`.
7. **Delta vs. baseline** = `currentAverage - baselineScore`, also `nil` until enough data.

Cards are sorted ascending by `currentPhase` (so "earliest" supplements appear first), then by `tier.sortOrder` (core/targeted/supporting).

### `daysOnPlan`

```swift
daysOnPlan = max(0, calendar.dateComponents([.day],
    from: calendar.startOfDay(for: plan.createdAt),
    to: calendar.startOfDay(for: now)).day ?? 0)
```

So a plan created today reports 0 days on plan; everything's in the early phase.

### Timeline summary text

| Condition | Text |
|---|---|
| `inOnsetOrLater == 0` | "All supplements are in their early phases. Consistency is key right now." |
| `inOnsetOrLater == total` | "All supplements have reached onset or steady state." |
| Mixed | "{name} has the longest road ahead at {phase} phase." (last supplement still pre-onset) |

`inOnsetOrLater` counts cards where `phaseState.hasReachedOnset == true`.

## Early-state guard

`isEarlyState: Bool { checkInCount < 3 }` — exposed to the view so the UI can show different copy when there's not enough data to be confident about deltas.

## Where it runs

- The Insights tab calls `viewModel.load(appState:period:)` on appear and on period change.
- The same view (or a sibling) calls `loadTimeline(appState:)` to build the card stack.
- Insights are also rendered as a feed on the Today screen, sourced directly from `appState.insights` (which is populated by `CheckInInsightGenerator` post-check-in, not by this view-model).

## Cross-references

- [Daily Check-In](daily-check-in.md) — where the `recentCheckIns` data comes from.
- [Supplement KB](../knowledge-bases/supplement-kb.md) — `phaseDurations`, `phaseContent`, `onsetTimelines`, `goalToDimension`.
- [Data Models](../architecture/data-models.md) — `DailyCheckIn`, `WellnessDimension`, `SupplementPlan`.
