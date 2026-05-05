# Text Generation

Where every piece of generated copy lives. The app composes user-facing strings from at least four different files; this page is the map. Use it when you need to find or change a phrase and don't want to grep blindly.

## The fields and their sources

### On `PlanSupplement`

| Field | Where it's built | Mostly from |
|---|---|---|
| `whyInYourPlan` | `RecommendationEngine.generateWhyInYourPlan` | `goalDescriptors` + `narrativeOpeners` (engine), or `boostWhyTemplates` (engine) when no goal overlap |
| `dosageRationale` | `RecommendationEngine.generateDosageRationale` | `Supplement.dosageRationale` (KB/Supabase) + legacy weight/sex/age clauses + signal `rationale` |
| `expectedTimeline` | passthrough | `Supplement.expectedTimeline` (KB / Supabase `onsetDescription`) |
| `whatToLookFor` | `RecommendationEngine.resolveWhatToLookFor` | `Supplement.whatToLookFor` template (KB) + placeholder substitutions + `signalCopyMap` (engine) |
| `formAndBioavailability` | passthrough | `Supplement.formAndBioavailability` (KB / Supabase `defaultForm`) |
| `interactionNote` | `RecommendationEngine.generateInteractionNote` | `catalog.synergies` + interaction warnings + safety rule warnings + multivitamin special case |
| `interactionWarnings` | `RecommendationEngine` (Step 5 mapping from `DBDrugInteraction`) | Supabase `drug_interactions` |
| `formUpgradeNote` | `SupplementNameMatcher.formUpgradeMessages` (engine fallback) | Hardcoded per form |
| `evidenceDisplay` | `EvidenceLevel.displayText` | enum extension |
| `researchNote` | passthrough | `Supplement.notes` (KB `notes` / Supabase `timingRationale`) |

### On `SupplementPlan`

| Field | Where it's built |
|---|---|
| `aiReasoning` | `RecommendationEngine.generatePlanSummary` (3-sentence composer) |

### On `CheckInInsight` / `Insight`

| Source | Where it's built |
|---|---|
| Daily check-in insight messages (9 rules) | `CheckInInsightGenerator` |
| Supplement fun facts | `CheckInInsightGenerator.supplementFunFacts` (static dict) |
| Generic fallback messages | `CheckInInsightGenerator.genericMessages` (static array) |

## Engine static templates

Inside `RecommendationEngine.swift`:

### `goalDescriptors: [String: String]`
Goal raw value → human phrase. Used by `generateWhyInYourPlan` and `generatePlanSummary.coreSentence`.

```
sleep → "sleep quality"
energy → "daily energy"
focus → "mental clarity and focus"
stress_anxiety → "stress management"
gut_health → "digestive health"
immune_support → "immune function"
muscle_recovery → "exercise recovery"
skin_hair_nails → "skin, hair, and nail health"
longevity → "long-term health"
heart_health → "cardiovascular health"
```

### `narrativeOpeners: [String: String]`
Supplement name → opener phrase. Used by `generateWhyInYourPlan` when the supplement has goal overlap. Examples:

```
"Magnesium Glycinate" → "Magnesium glycinate is one of the most effective natural supports for"
"Vitamin D3 + K2"     → "Vitamin D3 paired with K2 plays a foundational role in"
"Omega-3 (EPA/DHA)"   → "Omega-3 fatty acids are among the most well-researched supplements for"
...
```

If a supplement isn't in `narrativeOpeners`, fallback is `"\(name) supports"`.

### `boostWhyTemplates: [String: [String: String]]`
Signal type → supplement name → why-sentence. Used by `generateWhyInYourPlan` **only when the supplement has no goal overlap** (it was added by personalization or safety boost). Signal types covered:

```
birth_control, hrt, ppi, high_stress, heavy_alcohol, vegan_diet,
sleep_onset, sleep_maintenance, low_sleep_baseline, low_energy_baseline,
age_50_plus
```

### `signalCopyMap: [String: [String: String]]`
Signal type → supplement name → "what to look for" sentence. Used by `resolveWhatToLookFor`, which appends up to 2 of these (sorted by signal magnitude descending). Same signal types as above.

### `timingConflicts: [(a, b, reason)]`
Mineral conflict pairs and the reason text used in `resolveTimingConflicts` for the "Take ≥2h apart" notes.

## KB / Supabase static templates

Inside `SupplementKnowledgeBase.swift`:

| Field | Notes |
|---|---|
| `Supplement.dosageRationale` | Base text for `generateDosageRationale`. Engine appends signal/legacy clauses. |
| `Supplement.whatToLookFor` | Template with `{caffeine_note}`, `{stress_note}`, `{exercise_note}` placeholders. Engine substitutes per profile. |
| `Supplement.expectedTimeline` | Used as-is. |
| `Supplement.formAndBioavailability` | Used as-is. |
| `Supplement.notes` | Surfaces as supplement tip in check-in insights AND as `researchNote`. |
| `phaseContent[name][phase]` | Per-phase text for the Insights timeline. Each phase has `title`, `body`. |
| `dailyTips: [String]` | Pool of timing/absorption tips for Today screen rotation. |

When a supplement is loaded from Supabase, the same fields populate from `DBSupplement` columns (`onsetDescription`, `timingRationale`, `defaultForm`, etc.) — see [Knowledge Base Mapper](../knowledge-bases/knowledge-base-mapper.md). Two fields blend KB + Supabase:

- **`displayDose`** — prefers KB's polished string, falls back to DB.
- **`whatToLookFor`** — prefers DB mechanism `goalRelevance`, falls back to KB.

## Plan summary composition

`RecommendationEngine.generatePlanSummary` composes `plan.aiReasoning` from up to 3 sentences:

1. **Core sentence** (always present): "Your plan is built around X and Y as your foundation for [goalPhrase]." Picks top 2 Core supplements (or top 2 by score) and top 2 user goals → `goalDescriptors`.
2. **Lifestyle sentence** (optional): first match in priority ladder — caffeine+L-Theanine, high-stress+Ashwagandha, active+Creatine, active+Whey/Plant Protein, vegan+B/D3, low-sleep+Mag.
3. **Tip sentence** (optional, skips topics already covered): Mag bedtime tip, Mag+D3 synergy, Ashwagandha consistency, Omega-3 with food, Probiotics empty stomach, generic consistency.

The `usedTopics` set tracks "stress / exercise / diet / sleep / caffeine" to prevent the tip sentence from repeating themes.

## Check-in insight templates

See [Check-In Insight Generator](../engines/check-in-insight-generator.md) for the 9 rules and their message formats. Notable:

- **Personal best** message: `"Personal best! Your {dim} hit X/10 — your highest ever."`
- **Consistency** message includes `kb.notes` appended verbatim.
- **Fun fact** message is the fact verbatim from `supplementFunFacts`.
- **Tip** message is `"{name} tip: {kb.notes}"`.
- **Generic fallback pool** is a 6-line array.

## Onboarding generated copy

There's no template-driven copy in onboarding to speak of — most strings are hardcoded in each `*Screen.swift` file. The only generative output is `viewModel.generatedPlan`, whose content is built by the engine.

## When to add a new template

- A new copy line for an existing field (e.g., another why-sentence for a new signal type) → add to the right dict in `RecommendationEngine.swift`. Update [Recommendation Engine](../engines/recommendation-engine.md) and this page if the dict structure changes.
- A new field on `PlanSupplement` → update [Data Models](../architecture/data-models.md), the engine to populate it, and any UI rendering it.
- A new check-in insight rule → add to `CheckInInsightGenerator.rules` and update [Check-In Insight Generator](../engines/check-in-insight-generator.md).
- A new `goalDescriptors` entry → add to engine; update [Recommendation Engine](../engines/recommendation-engine.md) and this page if the goal is also new (then `HealthGoal` in [Data Models](../architecture/data-models.md) needs a case too).

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) — the bulk of template definitions.
- [Check-In Insight Generator](../engines/check-in-insight-generator.md) — daily insight templates.
- [Supplement KB](../knowledge-bases/supplement-kb.md) — base-level template fields.
- [Knowledge Base Mapper](../knowledge-bases/knowledge-base-mapper.md) — KB / Supabase blend logic.
