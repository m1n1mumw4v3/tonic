# Scoring Pipeline

How a single supplement's score gets built end-to-end. The score determines tier (core/targeted/supporting), which determines whether it makes the plan and how prominently it's displayed. The logic is split across three files; this page is the only place where the pieces sit next to each other.

## Final formula

```
final_score(supplement, profile) =
      Σ goal_weight(supplement, goal)                  ← step 1, RecommendationEngine
    + Σ personalization_delta(profile, signal)         ← step 1b, PersonalizationScorer
    + Σ safety_boost(profile, deepProfileModules)      ← step 1b2, SafetyRules
    [filtered by interaction/exclusion gates]          ← step 2/2b, RecommendationEngine
    [filtered by goal-overlap > 0]                     ← step 3, RecommendationEngine
```

After the steps above, the engine assigns tiers from the final score:

- `score >= 5` → **core**
- `score >= 3` → **targeted**
- `score < 3` → **supporting**

With a minimum-quality guarantee: if Core+Targeted < 2, the top-scoring Supporting(s) get promoted to Targeted.

## Worked example

Consider a 28-year-old vegan female user with goals `[sleep, energy]`, on hormonal birth control, baseline sleep 4. Suppose the goal map gives:

| Supplement | sleep | energy | goal-only score |
|---|---|---|---|
| Magnesium Glycinate | 4 | 0 | 4 |
| Vitamin B Complex | 0 | 4 | 4 |

### Step 1 — goal weights
`candidateScores = [Mag: 4, B Complex: 4]`
`candidateGoalScores = [Mag: 4, B Complex: 4]`

### Step 1b — personalization signals
`PersonalizationScorer.evaluate(profile, signals, catalog)`:

- `diet_type == vegan` signal targeting **B Complex**, magnitude moderate, increase → `delta = +2`.
- `baseline_sleep == low` signal targeting **Magnesium Glycinate**, minor, increase → `delta = +1`.

`candidateScores = [Mag: 5, B Complex: 6]`

### Step 1b2 — safety boosts
`SafetyRules.scoreBoosts`:

- Birth control / HRT (from deep-profile or hormonal flag) → Mag +2, B Complex +2, Zinc +1, CoQ10 +1.
- `low_sleep_baseline` is **not** a safety rule — it lives only in the engine's `boostWhyTemplates` and `signalCopyMap` for *text generation*, not scoring. Don't confuse the two.

After: `candidateScores = [Mag: 7, B Complex: 8, Zinc: 1, CoQ10: 1]`

### Step 1c — dedup
If she's already taking magnesium oxide (form variant), Mag stays in but gets a form-upgrade note attached at Step 5.

### Step 2/2b — interaction filter
Drug interactions (key-based) and exclusion groups apply. Iron male guardrail is irrelevant (she's female). Pregnancy/breastfeeding flags are irrelevant unless set.

### Step 3 — goal-overlap filter
`candidateGoalScores` is `[Mag: 4, B Complex: 4]` (boosts from 1b/1b2 didn't update it). So Zinc and CoQ10 are dropped — they were boost-only with no goal overlap.

`filteredCandidates = [Mag: 7, B Complex: 8]`

### Step 4 — tier-aware selection
Both Mag (7) and B Complex (8) are ≥5 → both **core**. Selected: `[B Complex, Mag]`.

Force-adds for vegan: B Complex already in, D3+K2 added (with whatever score it has from goal mapping; if 0, joins as supporting). Force-add for birth control: B Complex already in.

### Step 5 — `tierScore` computation per supplement

Inside the `selected.enumerated().map` loop:

```swift
let weightedScore = matched.reduce(0) { sum, goalKey in
    sum + catalog.weight(for: supplement.name, goal: goalKey)
}
```

This is **goal weight only** — no personalization or safety. Then later, in `assignTiers`, this `tierScore` is used:

```swift
if score >= 5 → .core
else if score >= 3 → .targeted
else → .supporting
```

> **Important:** `tierScore` ≠ `candidateScores`. The candidate score (used during selection) includes personalization + safety; the persisted `tierScore` is goal-only. This is so the user-facing tier badge reflects "evidence for your goals" rather than "boosts for your conditions."

For our example:
- Mag tierScore = 4 (sleep goal weight) → **targeted**
- B Complex tierScore = 4 (energy goal weight) → **targeted**

So even though both had high candidate scores (7 and 8), they end up tagged as Targeted, not Core. The min-quality guarantee already has 2 high-tier supplements so no promotion occurs.

> If you're surprised by tier assignments in the UI, this is usually why. The selection happens against `candidateScores`; the tier badge reflects `tierScore` which is goal-only. That distinction is intentional — but easy to miss.

## Where each piece lives

| Step | Function | File |
|---|---|---|
| Goal weights | `catalog.goalMappings(for:)` and `catalog.weight(for:goal:)` | `SupplementCatalog.swift` |
| Goal mapping data | `goalSupplementMap` populate | `SupplementKnowledgeBase.swift` (static) or Supabase via `KnowledgeBaseMapper.swift` |
| Personalization signals | `PersonalizationScorer.evaluate` | `PersonalizationScorer.swift` |
| Profile field mapping | `PersonalizationScorer.profileValue(field:profile:)` | same |
| Magnitude → delta | `magnitudeToDelta` | same |
| Safety boosts | `SafetyRules.scoreBoosts(profile:deepProfileModules:)` | `SafetyRules.swift` |
| Selection thresholds (5/3) and max (7) | `selectTierAware` | `RecommendationEngine.swift` |
| Final tier assignment + promotion | `assignTiers` | same |
| `buildPlanSupplement` (single-add path) | uses same components | same |

## Ratchet checklist when changing scoring

If you tweak any of these, audit the wiki:

- [ ] Tier thresholds (5 / 3) → update [Recommendation Engine](../engines/recommendation-engine.md), [Data Models](../architecture/data-models.md) (the SupplementTier table), and this page.
- [ ] Magnitude multipliers (1, 2, 3) → update [Personalization Scorer](../engines/personalization-scorer.md) and this page.
- [ ] Max plan size (7) or supporting cap (1 above 5 high-tier) → update [Recommendation Engine](../engines/recommendation-engine.md) and this page.
- [ ] Safety boost amounts → update [Safety Rules](../engines/safety-rules.md) and this page.
- [ ] Goal-overlap filter (Step 3) — if you change what passes through, this page's example may break.

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) — full pipeline.
- [Personalization Scorer](../engines/personalization-scorer.md) — Step 1b deep dive.
- [Safety Rules](../engines/safety-rules.md) — Step 1b2 deep dive.
- [Supplement Catalog](../knowledge-bases/supplement-catalog.md) — the indexes that feed Step 1.
