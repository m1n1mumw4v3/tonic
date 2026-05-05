# Knowledge Base Mapper

The bridge between Supabase row shapes and the in-memory `Supplement` / goal-map / interaction shapes the engine expects. Everything that flows from Supabase passes through this mapper before reaching the catalog.

**Source:** `Estus/Services/KnowledgeBaseMapper.swift`

## Inputs / Outputs

```swift
KnowledgeBaseMapper.map(_ snapshot: KnowledgeBaseSnapshot) -> MappedKnowledgeBase

struct KnowledgeBaseSnapshot {                    // Supabase fetch result
    let supplements: [SupabaseSupplement]
    let goalMaps: [SupabaseGoalMap]
    let drugInteractions: [SupabaseDrugInteraction]
    let contraindications: [SupabaseContraindication]
    let mechanisms: [SupabaseMechanism]
    // ...
}

struct MappedKnowledgeBase {
    let supplements: [Supplement]
    let goalSupplementMap: [String: [GoalSupplementEntry]]
    let knownDrugInteractions: [String: [String]]   // drug/class → [supplement names]
    let onsetTimelines: [String: (min: Int, max: Int, description: String)]
    let dailyTips: [String]
}
```

## Steps

### 1. ID → name lookup

Builds a `[UUID: String]` from `snapshot.supplements` first, since several other tables join by `supplementId` and need a name out the other side.

### 2. `mapSupplements` — DBSupplement → Supplement

For each row:

| Field on `Supplement` | Source / transformation |
|---|---|
| `recommendedTiming` | `timeOfDay` string mapped to `SupplementTiming` (defaults to `.morning` on missing/unknown). |
| `evidenceLevel` | `synthesisConfidence`: `"high" → .strong`, `"moderate" → .moderate`, `"low" → .emerging`. |
| `drugInteractions` | Collect `drugOrClass` values from `snapshot.drugInteractions` where `supplementId == s.id`. |
| `contraindications` | Collect `condition` values from `snapshot.contraindications` where `supplementId == s.id`. |
| `commonDosageRange` | `"\(doseRangeLow) – \(doseRangeHigh)"` if both present, else `defaultDose`. |
| `recommendedDosageMg` | Parse digits from `defaultDose` → `Double`. Falls back to `0` (engine clamps via `doseRange`). |
| `benefits` | `[primaryAction]` if present, else `[]`. |
| `formAndBioavailability` | `defaultForm` or `""`. |
| `expectedTimeline` | `onsetDescription` or `""`. |
| `displayDose` | Prefer the **hardcoded KB's** `displayDose` (so polished strings like "1x daily" survive); fall back to DB `defaultDose`. |
| `notes` | `timingRationale` or `""`. |
| `whatToLookFor` | Try DB mechanism `goalRelevance` joined with `". "`; fall back to hardcoded KB's `whatToLookFor`. |

The hardcoded KB acts as a fallback within the mapper itself for `displayDose` and `whatToLookFor`. This is intentional: those are the two fields where curated copy beats raw DB strings.

### 3. `mapGoalSupplementMap`

For each `SupabaseGoalMap` row, resolve the supplement name and append `(name, weight)` to `result[goal]`. Weights are stored as strings in the DB and parsed (`Int(entry.weight) ?? 1`).

After collection, each goal's entries are sorted descending by weight.

### 4. `mapDrugInteractions`

For each row, append the supplement name under `result[drugOrClass]`. Then dedup each list. The result is a reverse lookup: "given this drug/class, which supplements does it touch?" — used by some legacy code paths and diagnostics. The engine's primary interaction path uses `SupplementCatalog.checkInteractions(...)` which queries the raw `[DBDrugInteraction]` array directly.

### 5. `mapOnsetTimelines`

Starts with `SupplementKnowledgeBase.onsetTimelines` as the base map, then overlays DB data:

- If `onsetMinDays` and `onsetMaxDays` are populated → use DB description (or `"X–Y days"` if missing).
- If timeline is missing for a new DB-only supplement → default to `(7, 28, onsetDescription ?? "Results may vary")`.

So a supplement present in both KB and DB will use **DB onset** if both fields are populated, otherwise the static value.

### 6. `mapDailyTips`

Keeps `SupplementKnowledgeBase.dailyTips` as a baseline, then appends `"\(name): \(timingRationale)"` for any DB supplement **not** present in the static KB. New Supabase entries automatically surface their tips.

## Why the static KB is still consulted

The mapper deliberately blends static + DB content for three fields where curated copy outperforms raw schema:

1. `displayDose` (e.g., "30B CFU" for Probiotics, "1x daily" for B Complex)
2. `whatToLookFor` (templates with `{caffeine_note}` etc.)
3. `dailyTips` (writer's polish)

The cleanest path forward is to migrate these into the Supabase schema, but the blend is fine for now — and the mapper is the only place that needs to know about it.

## Where it runs

`AppState.loadSupplementCatalog()` calls `SupplementService.loadCatalog()` to fetch the snapshot, but the **mapper itself is not invoked there** — `SupplementCatalog.populate(...)` consumes raw Supabase types. The mapper is used in places that need a flattened `MappedKnowledgeBase`, primarily diagnostics, demo bootstrap, and any code path that wants the cross-cutting "ID → name" denormalization.

> If you're tracing why a supplement appears in the catalog with a particular dose or evidence level, the answer is usually in `DBSupplement.toSupplement(benefits:)` (called by `SupplementCatalog.populate`), not here. This mapper is for the auxiliary path.

## Cross-references

- [Supplement Catalog](supplement-catalog.md) — the primary consumer of Supabase data.
- [Supplement KB](supplement-kb.md) — the static side that the mapper falls back to.
- [Recommendation Engine](../engines/recommendation-engine.md) — eventual consumer of the mapped data.
