# Check-In Insight Generator

Picks the single most relevant insight to surface after a daily check-in. Walks 9 ranked rules and returns the first match that hasn't been shown recently. Outputs a `CheckInInsight` struct that the Today screen renders inline; persisted entries are also converted into `Insight` records for the Insights tab.

**Source:** `Estus/Utilities/CheckInInsightGenerator.swift`

## Inputs

```swift
struct Context {
    let todayScores: [WellnessDimension: Int]
    let baselines: [WellnessDimension: Int]
    let trailingAverages: [WellnessDimension: Double]
    let recentCheckIns: [DailyCheckIn]      // excluding today
    let streak: UserStreak
    let supplementsTakenToday: [(name: String, id: UUID)]
    let plan: SupplementPlan?
    let recentlyShownKeys: Set<String>      // last 5 from RecentInsightTracker
    let catalog: SupplementCatalog?
}
```

## Output

```swift
struct CheckInInsight {
    let key: String              // stable identifier for freshness filtering
    let message: String
    let icon: String             // SF Symbol
    let accentColor: Color
    let dimension: WellnessDimension?
}
```

## Freshness filter

`RecentInsightTracker` stores up to 5 recently shown insight keys in `UserDefaults["recentInsightKeys"]`. The generator skips any rule whose returned `key` is in `context.recentlyShownKeys` — except the generic fallback (keys prefixed `generic_`), which always wins if reached.

If every rule's result is filtered, the function force-returns the generic fallback. The user always sees *something*.

## Rule order (first non-filtered match wins)

### 1. `personalBest` — key `pb_{dimension}`
**Fires when** there are ≥3 prior check-ins AND today's score for some dimension exceeds the historical max for that dimension AND it's the highest of today's dimensions.

Message: *"Personal best! Your {dimension} hit X/10 — your highest ever."* Icon: trophy.fill.

### 2. `supplementConsistency` — key `supp_{name_slug}_{milestone}`
**Fires when** any supplement taken today has a consecutive-days streak hitting one of the milestones [3, 5, 7, 14, 21, 30]. Picks the highest milestone reached.

Walks `recentCheckIns` (already in DESC order from storage), counts consecutive days the supplement was logged with `taken == true`, including today.

Message: *"You've been consistent with {name} for {milestone} days. {kb.notes}"* (catalog notes appended if available). Icon: pills.fill.

### 3. `aboveBaseline` — key `above_baseline_{dimension}`
**Fires when** any dimension's today score is **≥ baseline + 2 points**. Picks the largest delta.

Message: *"Your {dimension} is X points above your baseline today. Nice start!"* Icon: arrow.up.right.

### 4. `aboveTrailingAverage` — key `above_avg_{dimension}`
**Fires when** any dimension's today score is **≥ 7-day average + 1.5 points**. Picks the largest delta.

Message: *"Your {dimension} is running above your 7-day average today."* Icon: chart.line.uptrend.xyaxis.

### 5. `consecutiveImprovement` — key `improving_{dimension}_{run}`
**Fires when** a dimension has been monotonically increasing for ≥3 consecutive days (today included). Walks `recentCheckIns` ascending from today and stops at the first non-decrease.

Message: *"Your {dimension} has been climbing for X days straight."* Icon: arrow.up.forward.

> The implementation has a subtle quirk: `if score < previousScore { run += 1 }` — meaning it counts days where the *prior* day was lower than today, walking backwards. That's effectively "today is higher than each of the previous N days as you go back," not strictly monotonic. If you change this, update the message wording too.

### 6. `fullAdherence` — key `full_adherence`
**Fires when** the plan has ≥2 supplements AND every plan supplement appears in `supplementsTakenToday` (matched by `id`).

Message: *"Perfect adherence — you took everything today!"* Icon: checkmark.seal.fill.

### 7. `supplementFunFact` — key `fun_fact_{name_slug}_{index}`
**Fires when** any supplement taken today has fun-fact entries in `supplementFunFacts`. Selects `index = recentCheckIns.count % facts.count` (deterministic rotation).

Message: the fun fact verbatim. Icon: brain.head.profile.

`supplementFunFacts` is a static dictionary defined in this file. Currently 16 supplements with 3 facts each. To add: add an entry to `Self.supplementFunFacts`.

### 8. `supplementTip` — key `supp_tip_{name_slug}`
**Fires when** any supplement taken today has `notes` populated in the catalog (which is most of them; `notes` carries timing/absorption guidance).

Message: *"{name} tip: {kb.notes}"* Icon: lightbulb.fill.

### 9. `genericFallback` — key `generic_{index}`
Always available. Picks `index = recentCheckIns.count % pool.count` from a 6-line pool:

```
"Every check-in teaches us something new about your body."
"Tracking is the first step to optimization."
"Your data is building a clearer picture every day."
"Small daily signals add up to big insights."
"The best supplement plan is the one you actually track."
"You showed up today. That matters."
```

Icon: sparkle.

## Where it's called

The Today flow (`TodayViewModel`) constructs the context after the user submits their wellbeing sliders, calls `generator.generate(from: context)`, and assigns the result to `completionInsight` for the celebration UI. After surfacing it, `RecentInsightTracker.record(insight.key)` is called to enforce the freshness filter on the next check-in.

The same `CheckInInsight` is also converted into an `Insight` record (different model, persisted via `LocalStorageService.saveInsights`) so it appears in the Insights tab feed.

## Cross-references

- [Daily Check-In](../flows/daily-check-in.md) — when this generator runs.
- [Insights & Timeline](../flows/insights-timeline.md) — how check-in insights become persistent feed items.
- [Text Generation](../cross-cutting/text-generation.md) — overview of where copy lives across the app.
