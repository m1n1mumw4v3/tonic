# Supplement Knowledge Base (Static)

The hardcoded reference data used as a fallback when Supabase is unavailable. Holds canonical metadata for ~30 supplements: dosage, timing, evidence, benefits, onset timelines, phase content, exclusion groups, personalization signals, daily tips, and the goal → supplement weight map.

**Source:** `Estus/Utilities/SupplementKnowledgeBase.swift`

## When this is used

In production, the Supabase tables `supplements`, `supplement_goal_map`, `supplement_synergies`, `drug_interactions`, `personalization_signals`, etc., are the source of truth — `KnowledgeBaseMapper` converts those rows into the same shapes defined here.

The static KB is the fallback path. `AppState.loadSupplementCatalog()` calls `populateFromStatic()` when:

- Supabase returns 0 supplements (RLS / anon key misconfig)
- The fetch throws
- Demo mode is active (`AppState.loadDemoData()`)

## Schemas

### `Supplement`

```swift
struct Supplement: Identifiable, Hashable {
    let id: UUID
    let name: String
    let commonNames: [String]
    let category: String
    let commonDosageRange: String       // "300 – 500 mg"
    let recommendedDosageMg: Double     // 300
    let displayDose: String?            // "300mg" or "1x daily" or "30B CFU"
    let recommendedTiming: SupplementTiming
    let benefits: [String]
    let contraindications: [String]
    let drugInteractions: [String]      // pre-computed keyword list
    let notes: String                   // appears as supplement tip in check-in insights
    let dosageRationale: String
    let expectedTimeline: String
    let whatToLookFor: String           // template with {caffeine_note}, {stress_note}, {exercise_note}
    let formAndBioavailability: String
    let evidenceLevel: EvidenceLevel    // strong | moderate | emerging
}
```

### `EvidenceLevel`

| Case | Display | Source mapping |
|---|---|---|
| `strong` | "Strong evidence" | DB `synthesisConfidence == "high"` |
| `moderate` | "Moderate evidence" | DB `"moderate"` |
| `emerging` | "Emerging evidence" | DB `"low"` |

### `GoalSupplementEntry`

```swift
struct GoalSupplementEntry {
    let name: String
    let weight: Int   // typically 1–5
}
```

## Top-level static data

| Property | Type | Notes |
|---|---|---|
| `allSupplements` | `[Supplement]` | The ~30 entries. |
| `goalSupplementMap` | `[String: [GoalSupplementEntry]]` | Goal raw value → ranked supplement entries. |
| `onsetTimelines` | `[String: (min, max, description)]` | Days until effects expected; consumed by phase computation. |
| `phaseContent` | `[String: [SupplementPhase: SupplementPhaseContent]]` | Per-supplement copy for early/accumulation/onset/steady-state phases. |
| `exclusionGroups` | `[ExclusionGroupEntry]` | Mutually-exclusive forms of the same compound. |
| `personalizationSignals` | `[SupabasePersonalizationSignal]` | Static fallback; same schema as Supabase. |
| `doseRanges` | `[String: (low, high, limit)]` | Numeric dose clamps used by `RecommendationEngine.adjustDosage`. |
| `dailyTips` | `[String]` | Pool of timing/absorption tips. |
| `goalToDimension` | `[String: WellnessDimension]` | Maps goal raw values to a primary wellness dimension (used by Insights timeline). |

## Phase content + onset

Two helpers used by the Insights timeline:

- `phaseDurations(for:)` — returns `(early: Int, accumulation: Int, onset: Int)` durations in days.
- `phaseContentFor(supplement:phase:)` — returns the `SupplementPhaseContent` (title + body) for a given phase.

`SupplementPhaseState.compute(daysOnPlan:durations:)` (in a separate file) figures out the current phase from these values.

## Exclusion groups

Each entry is `(groupKey, supplementName, priority)`. The catalog turns this into a `[groupKey: [(name, priority)]]` index. During plan generation Step 2b, only the highest-scored member of each present group survives; ties go to lowest priority number.

Example groups (illustrative — confirm by reading the file):

- "Vitamin D form" → D2 vs. D3+K2
- "Magnesium form" → multiple Mag forms
- "Iron form" → multiple Iron forms

## Static synergies (mirrored at runtime)

The static synergies live inside `SupplementCatalog.populateFromStatic()` (not in this KB file). They mirror the Supabase `synergies` table for the static path.

## Daily tips

Used by the Today screen's discovery card rotation. The catalog's mapper appends timing rationales for any DB supplement not present in `allSupplements` so new Supabase entries surface their tips automatically.

## Personalization signals (static)

Each entry follows the `SupabasePersonalizationSignal` shape. They're indexed by both `supplementId` and `profileField` when the catalog populates. Examples include: vegan diet → boost B12/D3/Iron, exercise 5+/week → boost Iron (women) / Creatine, age 50+ → boost CoQ10 / Collagen, etc.

When a Supabase signal exists for the same `(profileField, condition, supplementId)` tuple, **Supabase wins** because `populate(...)` overwrites — `populateFromStatic` is a separate code path.

## Editing

When adding a supplement to this file:

1. Add a `Supplement(...)` to `allSupplements`.
2. Add to `goalSupplementMap` for every goal it serves with an integer weight.
3. Add to `onsetTimelines` and `phaseContent`.
4. Add to `exclusionGroups` if it has form variants.
5. Add a `formVariantMap` entry in [`SupplementNameMatcher`](../engines/supplement-name-matcher.md) if users might type alternate forms.
6. Add fun facts in [`CheckInInsightGenerator.supplementFunFacts`](../engines/check-in-insight-generator.md) (optional, but improves the post-check-in copy).
7. If the supplement should fire safety boosts/exclusions for some user condition, update [`SafetyRules`](../engines/safety-rules.md).

After changes: `xcodegen generate` is **not** required (this file already exists). But if you split the KB across files, regenerate.

## Cross-references

- [Knowledge Base Mapper](knowledge-base-mapper.md) — translates Supabase rows to the same `Supplement` shape.
- [Supplement Catalog](supplement-catalog.md) — the runtime indexed view that everything else queries.
- [Recommendation Engine](../engines/recommendation-engine.md) — the primary consumer.
- [Insights & Timeline](../flows/insights-timeline.md) — uses `phaseDurations`, `phaseContent`, `onsetTimelines`, `goalToDimension`.
