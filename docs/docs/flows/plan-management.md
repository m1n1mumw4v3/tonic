# Plan Management

The Plan tab renders the active `SupplementPlan` and lets the user remove, restore, and add supplements after the plan was generated. There's no full re-generation on demand — adds happen one-at-a-time via `RecommendationEngine.buildPlanSupplement`.

**Sources:** `Estus/Features/Plan/PlanViewModel.swift`, `Estus/Features/Plan/PlanScreen.swift`, `Estus/Features/Plan/AddSupplementSheet.swift`

## State

`PlanViewModel` is `@Observable` and references `AppState` (set in `load(appState:)`). It exposes `activePlan` as a get/set passthrough to `appState.activePlan`, so writes mutate the source of truth.

```swift
var activePlan: SupplementPlan? {
    get { appState?.activePlan }
    set { appState?.activePlan = newValue }
}
```

## Computed groupings

| Group | Filter |
|---|---|
| `morningSupplements` | `!isRemoved && timing ∈ {morning, emptyStomach, withFood}` |
| `eveningSupplements` | `!isRemoved && timing ∈ {evening, bedtime, afternoon}` |
| `removedSupplements` | `isRemoved == true` |

These are recomputed on every read; no caching. Cheap because `supplements.count` is small (≤ 7 typically).

## Mutations

### `removeSupplement(_:)`
Sets `isRemoved = true` on the matching supplement. Caches the removed entry as `lastRemovedSupplement` for an undo affordance.

### `addSupplements(_:)`
Appends new `PlanSupplement`s, then re-sorts the entire list by `tier.sortOrder` then `timing.sortOrder`, reassigns `sortOrder` indices, and **bumps `plan.version`**. Used by `AddSupplementSheet` after the user picks one or more from the catalog.

### `undoRemoval()`
Restores `lastRemovedSupplement` if still present in the plan. Toast-driven.

### `restoreSupplement(_:)`
Clears `isRemoved` for an explicit supplement (different from undo: this is the "removed supplements" section's restore button).

### `setUserDosage(_:mg:)`
Sets `userOverriddenDosageMg` on a supplement. Pass `nil` to clear the override and revert to the engine's recommendation (`PlanSupplement.dosageMg`). Triggered from the inline `DosageRangeEditor` in the expanded supplement card on both Plan and Plan Reveal screens. The override survives `addSupplements`/`removeSupplement`/`restoreSupplement` because the engine isn't re-run — it only affects the single supplement's stored value, which round-trips through `LocalStorageService.savePlan`.

> **No automatic persistence to `LocalStorageService`** in these mutations as written — they mutate `appState.activePlan` in memory. Persistence happens lazily through other code paths that save the plan (e.g., Today view check-in saves don't touch the plan; you'd want to confirm/extend persistence if plan edits should survive an immediate app kill). Worth flagging when reviewing.

## Adding supplements — `AddSupplementSheet`

The sheet uses `RecommendationEngine.buildPlanSupplement(from:for:existingSupplements:)` to produce a `PlanSupplement` with proper tier, score, copy, and interaction note. This means added supplements get the same enrichment as engine-generated ones.

The sheet also calls `engine.findExcludedSupplements(profile:)` to surface a "not safe with your meds" warning on supplements the engine would have excluded.

## Product loading

Each `PlanSupplement` can have associated ranked products fetched from Supabase.

```swift
func loadProducts(for supplement: PlanSupplement)
```

Behavior:

- No-op if `supplementId == nil` (engine-generated supplements without a Supabase ID).
- No-op if already cached or loading.
- Otherwise inserts into `loadingProductIds`, fires an async `SupplementService.fetchProducts(forSupplementId:)`, and on completion writes `productsBySupplementId[supplementId] = fetched`.
- On error, writes an empty array (so the UI shows "no products" rather than an indefinite loading spinner).

`detailProductCache: [UUID: RankedProduct]` is a separate by-product-id cache used by `ProductDetailScreen` deep-links so products can be looked up across navigation without refetching.

## Plan version label

`planVersionLabel` returns `" · V2"` etc. only when `plan.version > 1`. The version increments on `addSupplements`, not on remove/restore — so users see version bumps when meaningfully expanding the plan.

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) — `buildPlanSupplement` for single-supplement adds.
- [Data Models](../architecture/data-models.md) — `SupplementPlan`, `PlanSupplement`, `SupplementTier`, `SupplementTiming`.
- [Persistence](../architecture/persistence.md) — how plan changes ultimately reach UserDefaults.
