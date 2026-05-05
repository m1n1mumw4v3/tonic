# Personalization Scorer

Translates Supabase-defined personalization signals into score deltas applied to candidate supplements. Also provides the field-mapping helper that `RecommendationEngine.adjustDosage` reuses for dose multipliers.

**Source:** `Estus/Utilities/PersonalizationScorer.swift`

## Inputs / Outputs

```swift
PersonalizationScorer.evaluate(
    profile: UserProfile,
    signals: [SupabasePersonalizationSignal],
    catalog: SupplementCatalog
) -> [ScoreAdjustment]

struct ScoreAdjustment {
    let supplementName: String
    let delta: Int           // -3...+3
    let reason: String       // signal.rationale or fallback
}
```

A `SupabasePersonalizationSignal` (defined in the Supabase model layer) has:

- `profileField: String` — keyed lookup in `profileValue(field:profile:)`.
- `condition: String` — case-insensitive equality match against the profile value.
- `supplementId: UUID` — resolved to a name via `catalog.supplement(byId:)`.
- `magnitude: String?` — `"minor" | "moderate" | "major"`.
- `effect: String?` — `"increase" | "decrease"`.
- `rationale: String?` — free-form, surfaced in dosage rationale text.

When loaded from static fallback (`SupplementKnowledgeBase.personalizationSignals`), the same struct is used.

## Flow

For each signal in `catalog.allPersonalizationSignals`:

1. `profileValue = profileValue(field: signal.profileField, profile:)`. If `nil` (unknown field), skip.
2. Skip unless `profileValue.lowercased() == signal.condition.lowercased()`.
3. Resolve `supplementName = catalog.supplement(byId: signal.supplementId)?.name`. If missing, skip.
4. `delta = magnitudeToDelta(signal.magnitude, effect: signal.effect)`. Skip if 0.
5. Append a `ScoreAdjustment`.

## Field map

`profileValue(field:profile:)` (used by both this scorer and `adjustDosage`):

| `profileField` | Returns |
|---|---|
| `diet_type` | `profile.dietType.rawValue` (e.g. `vegan`, `vegetarian`, `omnivore`, …) |
| `exercise_frequency` | `profile.exerciseFrequency.rawValue` |
| `stress_level` | `profile.stressLevel.rawValue` |
| `alcohol_weekly` | `profile.alcoholWeekly.rawValue` |
| `caffeine_daily` | bucket: `"high"` (≥4 cups), `"moderate"` (≥2), `"low"` (≥1), `"none"` (0). Sums coffee + tea + energy drinks. |
| `sex` | `profile.sex.rawValue` |
| `age_range` | bracket: `under_18`, `18-29`, `30-49`, `50-64`, `65+` |
| `baseline_sleep`, `baseline_energy`, `baseline_clarity`, `baseline_mood`, `baseline_gut` | `"low"` (0–3), `"moderate"` (4–6), `"high"` (≥7) |
| `is_pregnant`, `is_breastfeeding` | `"true"` / `"false"` |
| anything else | `nil` (signal silently skipped) |

If you add a new field in Supabase, you must add a case here too — otherwise the signal will be a no-op and you'll have a hard time noticing.

## Magnitude → delta

```swift
magnitudeToDelta(magnitude, effect):
    base = minor → 1, moderate → 2, major → 3, default → 1
    return effect == "decrease" ? -base
         : effect == "increase" ? +base
         : 0
```

If `effect` is missing or unrecognized, the delta is 0 — meaning the signal is effectively disabled. This is intentional (better to skip than guess).

## Where it's called

- **`RecommendationEngine.generatePlan`**, Step 1b — applies score deltas to all candidates.
- **`RecommendationEngine.buildPlanSupplement`** — same logic for a single added supplement.
- **`RecommendationEngine.generateDosageRationale`** — reads matching signals to append a one-line "adjusted to upper/lower range" sentence.
- **`RecommendationEngine.adjustDosage`** — uses signal magnitudes as **dosage multipliers** (1.15/1.25/1.5), not score deltas. Same matching rules apply.

## Static-fallback signals

`SupplementKnowledgeBase.personalizationSignals` defines a static array of signals used when Supabase is unavailable. They use the same struct and same field names; the catalog indexes them at populate time.

## Cross-references

- [Recommendation Engine](recommendation-engine.md) — where signals get applied.
- [Scoring Pipeline](../cross-cutting/scoring-pipeline.md) — how signal deltas combine with goal weights and safety boosts.
- [Supplement Catalog](../knowledge-bases/supplement-catalog.md) — `allPersonalizationSignals`, `personalizationSignals(for:)`, `personalizationSignals(forField:)`.
