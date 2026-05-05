# Supplement Catalog

The runtime, indexed view of supplement data. Every engine and most view-models query through it. Owned by `AppState`, populated once at app launch from Supabase (or static fallback), then read-only for the session.

**Source:** `Estus/Services/SupplementCatalog.swift`

## Shape

`@Observable class SupplementCatalog` with two populate methods (`populate(...)` for Supabase, `populateFromStatic()` for fallback) and a wide query API.

### Internal indexes

| Index | Type | Built from |
|---|---|---|
| `supplementsByName` | `[String: Supplement]` | `Supplement.name` |
| `supplementsById` | `[UUID: Supplement]` | `Supplement.id` |
| `dbSupplementsByName`, `dbSupplementsById` | DBSupplement equivalents | Supabase rows (or synthesized for static path) |
| `goalMap` | `[String: [GoalSupplementEntry]]` | Goal raw value → ranked supplement entries |
| `categoryIndex` | `[String: [Supplement]]` | Group by `Supplement.category` |
| `synergies` | `[String: [(partner, mechanism)]]` | Bidirectional pairings (auto-mirrored when DB row says `directionality == "bidirectional"`) |
| `exclusionGroupIndex` | `[String: [(name, priority)]]` | Mutually-exclusive forms; sorted by priority asc |
| `signalsBySupplementId` | `[UUID: [SupabasePersonalizationSignal]]` | Personalization signals indexed by target supplement |
| `signalsByField` | `[String: [SupabasePersonalizationSignal]]` | Same signals indexed by `profileField` |
| `allPersonalizationSignals` | `[SupabasePersonalizationSignal]` | Flat list for `PersonalizationScorer.evaluate` |

### Public properties

- `allSupplements: [Supplement]` — flat list (read-only).
- `isLoaded: Bool`, `loadError: Error?` — load state.
- `synergies` (re-exposed for engine use).
- `exclusionGroups` (re-exposed for engine use).
- `allPersonalizationSignals` (re-exposed for engine use).
- `goalSupplementMap` (re-exposed).
- `supplementsByCategory: [(category, label, supplements)]` — ordered for display, label resolved via `categoryLabel(for:)`.

## Query API

```swift
supplement(named: String) -> Supplement?
supplement(byId: UUID) -> Supplement?
dbSupplement(named: String) -> DBSupplement?
weight(for: String, goal: String) -> Int                    // 0 if not mapped
goalMappings(for: String) -> [GoalSupplementEntry]
supplements(for: String) -> [Supplement]                    // resolves names through index
exclusionGroupPeers(for: String) -> [String]                // group siblings (excluding self)
personalizationSignals(for: UUID) -> [...]                  // signals targeting this supplement
personalizationSignals(forField: String) -> [...]           // signals reading this profile field
doseRange(for: String) -> (low, high, limit)?               // DB first, KB fallback
```

## Populate paths

### `populate(supplements:goalMaps:synergyPairings:personalizationSignals:)`

The primary path. Called by `AppState.loadSupplementCatalog()` after a successful Supabase fetch. Builds all indexes from raw DB types. Note:

- Goal mappings: each `DBSupplementGoalMap` has `weightInt: Int` already parsed.
- Synergies: `directionality == "bidirectional"` causes the entry to be added in both directions.
- Exclusion groups: pulled from `SupplementKnowledgeBase.exclusionGroups` (static) — there's no Supabase table for this yet.

### `populateFromStatic()`

The fallback path. Builds indexes from `SupplementKnowledgeBase.allSupplements`, `goalSupplementMap`, hardcoded synergy literals (defined inline in this method, not in the KB file), and `personalizationSignals` from the static KB.

It also synthesizes `DBSupplement` records for each static supplement (using the supplement's evidence level → confidence string) so the dose-range lookup path works uniformly.

Both methods overwrite all indexes atomically — there's no mutation API once populated.

## `doseRange(for:)`

```swift
func doseRange(for supplementName: String) -> (low: Double, high: Double, limit: Double?)?
```

Returns the dosage range used by `RecommendationEngine.adjustDosage` to clamp the final dosage. Lookup order:

1. Try DB: `dbSupplementsByName[name]` → if `doseRangeLow` and `doseRangeHigh` parse to >0, return `(low, high, limit?)` where `limit` comes from `upperTolerableLimit`.
2. Fall back to `SupplementKnowledgeBase.doseRanges[name]`.

`parseDoseString(_:)` handles units: g→×1000, mcg/ug→÷1000, mg/IU/plain pass through. Returns 0 on parse failure (caller treats as "no clamp").

## `checkInteractions(...)` — interaction decision

The single decision point for whether a candidate supplement should be excluded, warned, or cleared given the user's selected medications.

```swift
func checkInteractions(
    supplementId: UUID,
    userInteractionKeys: Set<String>,
    allInteractions: [DBDrugInteraction]
) -> InteractionDecision

enum InteractionDecision {
    case remove([DBDrugInteraction])
    case keepWithWarnings([DBDrugInteraction])
    case clear
}
```

Logic:

1. Filter `allInteractions` to entries where `supplementId == thisId` AND `drugOrClass ∈ userInteractionKeys`.
2. Empty → `.clear`.
3. Any matched interaction has `action == .avoid` → `.remove(matches)`.
4. Else → `.keepWithWarnings(matches)`.

`collectInteractionKeys(medicationIds:medications:)` flattens `interactionKeys` from the user's selected `DBMedication` records into a `Set<String>`. Called once per `generatePlan`.

## Category labels

`categoryLabel(for: String)` translates raw category keys to display labels:

`mineral → "Minerals"`, `vitamin → "Vitamins"`, `fatty_acid → "Fatty Acids"`, `adaptogen → "Adaptogens"`, `amino_acid → "Amino Acids"`, `probiotic → "Probiotics"`, `coenzyme → "Coenzymes"`, `protein → "Proteins"`, `mushroom → "Mushrooms"`, `hormone → "Hormones"`, `plant_extract → "Plant Extracts"`, `fruit_extract → "Fruit Extracts"`, fallback `key.capitalized`.

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) — primary consumer.
- [Personalization Scorer](../engines/personalization-scorer.md) — reads `allPersonalizationSignals` and resolves IDs via `supplement(byId:)`.
- [Knowledge Base Mapper](knowledge-base-mapper.md) — auxiliary mapper for the same data shape.
- [Interaction Checking](../cross-cutting/interaction-checking.md) — full picture of `checkInteractions`'s role.
