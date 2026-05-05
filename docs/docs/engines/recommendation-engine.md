# Recommendation Engine

The deterministic core of the app. Takes a `UserProfile`, returns a `SupplementPlan` of up to 7 supplements with tiers, dosages, timing, copy, and interaction warnings.

**Source:** `Estus/Utilities/RecommendationEngine.swift`

## Inputs

```swift
RecommendationEngine(
    catalog: SupplementCatalog,         // pre-loaded indexes: supplements, goals, synergies, signals, exclusion groups
    drugInteractions: [DBDrugInteraction] = [],
    contraindications: [DBContraindication] = [],
    medications: [DBMedication] = [],   // user-relevant rows for interaction key lookup
    deepProfileModules: [DeepProfileModule] = []
)
```

The engine is constructed in three places:

- `OnboardingFlow.makeEngine()` — the main path (post-onboarding plan generation).
- `AppState.loadDemoData()` — demo bootstrap (catalog only, no medications).
- `AddSupplementSheet` — single-supplement dosage/score lookup via `buildPlanSupplement(...)`.

## `generatePlan(for:)` — the 9-step pipeline

This is the function. Every other engine method is a helper.

### Step 1 — Goal mapping

```swift
for goal in profile.healthGoals.map(\.rawValue) {
    for entry in catalog.goalMappings(for: goal) {
        candidateScores[entry.name] += entry.weight
        candidateGoalScores[entry.name] += entry.weight
    }
}
```

Two parallel dictionaries: `candidateScores` accumulates everything, `candidateGoalScores` only counts pure goal weights. The split matters at Step 3 — supplements added purely by safety boosts (without goal overlap) get filtered out unless force-added later.

### Step 1b — Personalization signal adjustments

```swift
let adjustments = PersonalizationScorer.evaluate(
    profile: profile,
    signals: catalog.allPersonalizationSignals,
    catalog: catalog
)
for adj in adjustments {
    candidateScores[adj.supplementName] += adj.delta
}
```

See [Personalization Scorer](personalization-scorer.md) for the field → condition → delta mechanics. Magnitudes: minor=±1, moderate=±2, major=±3.

### Step 1b2 — Safety rule score boosts

```swift
let safetyBoosts = SafetyRules.scoreBoosts(profile, deepProfileModules)
for (name, boost) in safetyBoosts {
    candidateScores[name] += boost
}
```

Currently boosts (not exclusions): PPI nutrient depletion (Mag +2, B Complex +2, Iron +1), birth control / HRT (Mag +2, B Complex +2, Zinc +1, CoQ10 +1), sleep onset (Melatonin +1 or +2), sleep maintenance (Mag +1 or +2), female iron exemptions (vegan +2, exercise 5+/wk +1, age 18–50 +1). See [Safety Rules](safety-rules.md).

### Step 1c — Dedup against current supplements

```swift
let dedupMatches = SupplementNameMatcher.match(
    userSupplements: profile.currentSupplements, catalog: catalog
)
```

For each match:

- **`.exact`** or **`.commonName`** → remove from `candidateScores` entirely (user is already taking it).
- **`.formVariant`** → keep but stash in `formVariantMatches`. Later (Step 5), the engine prepends a "form upgrade" note to `whyInYourPlan`.
- **`.partial`** → no action; flagged for the user to review.

See [Supplement Name Matcher](supplement-name-matcher.md).

### Step 2 — Interaction filter

```swift
let interactionKeys = collectInteractionKeys(from: profile)
let filterResult = filterByInteractions(...)
```

`filterByInteractions` produces:

- `excluded: Set<String>` — names removed entirely.
- `warnings: [UUID: [DBDrugInteraction]]` — non-fatal warnings to attach.
- `removedInteractions: [UUID: [DBDrugInteraction]]` — explanation for each exclusion.

What it filters:

1. **Drug interactions (key-based):** for each candidate, `catalog.checkInteractions(supplementId, userInteractionKeys, allInteractions)` returns one of:
    - `.remove(matches)` if any interaction has `action == .avoid`.
    - `.keepWithWarnings(matches)` if interactions exist but none are avoid-level.
    - `.clear` otherwise.
2. **Absolute contraindications.**
3. **Allergies.** Hardcoded for now: fish/shellfish → exclude `Omega-3 (EPA/DHA)`. Dairy/milk/lactose → exclude `Whey Protein Isolate`.
4. **Diet exclusions.** Vegan/vegetarian → exclude `Whey Protein Isolate`.
5. **Pregnancy / breastfeeding.** Exclude `Ashwagandha KSM-66` and `Berberine`.
6. **Safety rules.** Iterates `SafetyRules.allRules` and pulls each rule's `excludeSupplements` if its condition fires (currently Iron-male, when no exemption applies).

### Step 2b — Exclusion group resolution

```swift
for (_, members) in catalog.exclusionGroups { ... }
```

Exclusion groups (defined in `SupplementKnowledgeBase.exclusionGroups`) prevent recommending two forms of the same compound. For each group present in the candidates, keep the highest-scored member; tiebreak by lowest priority number.

### Step 3 — Goal-overlap filter

```swift
let goalFiltered = filteredCandidates.filter { candidateGoalScores[$0.key] > 0 }
```

Drops supplements that only got into the candidate set via personalization or safety boosts (no goal overlap). They can still be re-added by `addIfMissing` for forced cases (vegan B12/D3, birth control B Complex, PPI B Complex).

After filtering, sort descending by score with alphabetical name tiebreak.

### Step 4 — Tier-aware selection (max 7)

`selectTierAware` walks the ranked list and assigns provisional tiers based on score:

- **core** if score ≥ 5
- **targeted** if score ≥ 3
- **supporting** if score < 3

Selection rules:

1. Take all Core (capped by 7-total).
2. Fill with Targeted up to 7 total.
3. **If Core+Targeted < 5** → fill remaining slots with Supporting.
   **Else** → allow at most 1 Supporting.

Then **forced additions** via `addIfMissing` (idempotent, respects exclusions):

| Condition | Force-added |
|---|---|
| `dietType == .vegan \|\| .vegetarian` | `Vitamin B Complex`, `Vitamin D3 + K2` |
| Hormonal birth control or HRT (from deep profile) | `Vitamin B Complex` |
| PPI use (medication list or `gut_ppi_usage == "yes_currently"`) | `Vitamin B Complex` |

PPI medication names (lower-cased, exact match):
`omeprazole, prilosec, pantoprazole, protonix, esomeprazole, nexium, lansoprazole, prevacid, rabeprazole, aciphex, dexlansoprazole, dexilant`.

### Step 5 — Build PlanSupplements

For each selected supplement (`enumerated`, index used as initial `sortOrder`):

1. **Dosage** via `adjustDosage` (see below) → numeric `dosageMg`.
2. **Format** numeric → display string via `formatDosage` (mg / IU / g / "1x daily" for B-Complex / "30B CFU" for Probiotics).
3. **Timing** = `supplement.recommendedTiming` (no per-user adjustment yet — `resolveTiming` is a passthrough, conflict resolution happens later).
4. **Matched goals & weighted score:** intersect user goals with this supplement's goal mappings; sum weights.
5. **Interaction warnings:** carried forward from `filterResult.warnings[supplement.id]`, mapped into `[InteractionWarning]`.
6. **Form upgrade note:** if there was a `formVariantMatches` entry, look up the message in `SupplementNameMatcher.formUpgradeMessages`; otherwise build a generic "you're taking X, we recommend Y — more bioavailable" string.
7. **`whyInYourPlan`:** `generateWhyInYourPlan` → see [text generation](#text-generation-tour).
8. **`dosageRationale`:** base from supplement + legacy weight/sex/age clauses + signal-based one-line append.
9. **`whatToLookFor`:** `resolveWhatToLookFor` substitutes `{caffeine_note}`, `{stress_note}`, `{exercise_note}` placeholders, then appends up to 2 signal-driven copy snippets sorted by magnitude.

After building all `PlanSupplement`s, **`assignTiers`** runs to set `tier` from `tierScore`:

- ≥5 → `.core`, ≥3 → `.targeted`, else `.supporting`.
- **Min quality guarantee:** if Core+Targeted count < 2, promote the top-scoring Supporting(s) to Targeted until there are at least 2 high-tier supplements.

### Second pass — Interaction notes

For each plan supplement, `generateInteractionNote` builds `interactionNote`:

1. **Synergies** from `catalog.synergies[supplement.name]`. Caffeine synergies fire only if the profile has any caffeine intake (coffee/tea/energy drink). Other synergies fire only if the partner is also in the plan.
2. **Medication warnings.** If `interactionWarnings` are populated, format per `action`:
    - `separate_timing` → "Take separately from X — mechanism."
    - `monitor` → "Monitor when taking with X — mechanism."
    - `adjust_dose` → "Dose may need adjustment due to X — mechanism."
   If no pre-populated warnings but the user has medications, run `catalog.checkInteractions` again as a safety net (`.clear` → "No conflicts," `.keepWithWarnings` → append each mechanism).
3. **Safety rule warnings.** Iterate `SafetyRules.allRules`; if a rule's condition fires AND it lists this supplement in `warnSupplements`, append `rule.warningMessage`.
4. **Multivitamin overlap:** for `Iron`, scan `profile.currentSupplements` for `multivitamin / multi-vitamin / multi vitamin / centrum / one a day` and append a label-check reminder if a hit is found.

### Timing conflict resolution (mineral pairs)

`resolveTimingConflicts` walks four pairs:

| Pair | Reason |
|---|---|
| Iron — Zinc | "Iron and zinc compete for the DMT-1 transporter" |
| Iron — Calcium | "Calcium inhibits iron absorption" |
| Zinc — Calcium | "Zinc and calcium compete for absorption" |
| Magnesium Glycinate — Iron | "Magnesium reduces iron absorption" |

For each pair where both are in the plan and both share a timing:

- If the lower-scored supplement has `emptyStomach` timing (typical for Iron), don't move it — append a "take ≥2h apart" note.
- Otherwise, shift it to the opposite time of day (morning ↔ evening, afternoon → evening, bedtime → morning) and append a timing-adjustment note.

The lower-scored supplement is the one moved; ties go to the first by index.

### Final sort & sortOrder

Sort by `tier.sortOrder` (core/targeted/supporting), then `timing.sortOrder` (emptyStomach/morning/withFood/afternoon/evening/bedtime). Reassign `sortOrder` to the final index.

### Plan summary (`aiReasoning`)

`generatePlanSummary` composes up to three sentences (joined with spaces):

1. **Core sentence.** "Your plan is built around X and Y as your foundation for [goal phrase]." Uses top 2 Core supplements (or top 2 by score if no Core); maps top 2 user goals to descriptors from `goalDescriptors`.
2. **Lifestyle sentence (optional).** First match wins from a priority ladder:
    - Caffeine + L-Theanine
    - High stress + Ashwagandha KSM-66
    - Active exercise + Creatine Monohydrate
    - Active exercise + Whey/Plant Protein (without Creatine)
    - Vegan/vegetarian + B Complex or D3+K2
    - Low sleep baseline + Magnesium Glycinate
3. **Tip sentence (optional).** Skips topics already covered. Falls through:
    - Magnesium → "30 minutes before bed" tip
    - Magnesium + D3+K2 → synergy tip
    - Ashwagandha → "2-4 weeks" consistency tip
    - Omega-3 → "with a meal containing fat" tip
    - Probiotics → "empty stomach in the morning" tip
    - Generic consistency tip

## Dosage adjustment (`adjustDosage`)

```swift
func adjustDosage(baseDosage: Double, supplement: Supplement, profile: UserProfile) -> Double
```

Three layers, applied in order:

1. **Personalization signals.** For each signal where `profileValue == condition`:
    - `magnitude` → multiplier: minor=1.15, moderate=1.25, major=1.5.
    - `effect == "increase"` → multiply, `decrease` → divide. Other effects are no-op.
2. **Legacy hardcoded rules** (`applyLegacyDosageRules`):
    - Age > 65 + (Rhodiola Rosea or CoQ10) → ×0.75.
    - Female + Iron → 27 mg (women of reproductive age).
    - Male + Iron → 8 mg.
    - Weight > 200 lbs + Vitamin D3 + K2 → 4000 IU.
3. **Clamp** to safe range from `catalog.doseRange(for:)` (low/high/limit). DB ranges win over static.

## Text generation tour

The engine is the source of static templates for several copy fields:

- **`goalDescriptors`** (file-scoped): goal raw value → human phrase ("sleep" → "sleep quality").
- **`narrativeOpeners`**: supplement → opener phrase ("Magnesium glycinate is one of the most effective natural supports for"). Used in `generateWhyInYourPlan` when the supplement has goal overlap.
- **`boostWhyTemplates`** (signal type → supplement → why-sentence): used when a supplement has no goal overlap but was added by a fired signal (e.g., birth control adds B Complex).
- **`signalCopyMap`** (signal type → supplement → look-for sentence): appended to `whatToLookFor` for top 2 fired signals by magnitude.

Fired signals are computed by `collectFiredSignals` based on profile + deep-profile responses:

| Signal type | Triggers when… | Affects supplements |
|---|---|---|
| `vegan_diet` | dietType is vegan or vegetarian | B Complex, D3+K2, Iron |
| `heavy_alcohol` | alcoholWeekly == eightPlus | B Complex, NAC, Magnesium Glycinate, Zinc |
| `birth_control` / `hrt` | deep-profile `hormonal_birth_control_hrt` | B Complex, Magnesium Glycinate |
| `ppi` | PPI medication or `gut_ppi_usage == yes_currently` | Magnesium Glycinate, B Complex, Iron |
| `sleep_onset` | `sleep_onset_latency` ∈ {20_40, 40_60, over_60} | Melatonin |
| `sleep_maintenance` | `sleep_wake_frequency` ∈ {twice, three_plus} | Magnesium Glycinate |
| `age_50_plus` | age ≥ 50 | CoQ10, Collagen Peptides |
| `low_sleep_baseline` | baselineSleep ≤ 4 | Magnesium Glycinate, Melatonin |
| `low_energy_baseline` | baselineEnergy ≤ 4 | B Complex, CoQ10 |
| `high_stress` | stressLevel ∈ {high, veryHigh} | Ashwagandha KSM-66, L-Theanine, Magnesium Glycinate |

Each fired signal carries a magnitude (2 or 3) used to sort which copy lines appear when multiple fire.

For the broader picture of where copy lives across files, see [Text Generation](../cross-cutting/text-generation.md).

## `buildPlanSupplement(...)` — single-supplement path

Used by `AddSupplementSheet` so the user can add a supplement to an existing plan and get a tier/score/copy. Mirrors the per-supplement portion of Step 5: dosage adjust, weighted score, fired signals, why/dosageRationale/whatToLookFor, interaction note, then assigns tier via `assignTiers` over the existing list + the new entry.

## Cross-references

- [Personalization Scorer](personalization-scorer.md) — Step 1b.
- [Safety Rules](safety-rules.md) — Steps 1b2 and 2 (exclusions and warnings).
- [Supplement Name Matcher](supplement-name-matcher.md) — Step 1c.
- [Supplement Catalog](../knowledge-bases/supplement-catalog.md) — the indexes the engine queries.
- [Scoring Pipeline](../cross-cutting/scoring-pipeline.md) — end-to-end trace of one supplement's score.
- [Interaction Checking](../cross-cutting/interaction-checking.md) — how Step 2 fits into the broader interaction flow.
