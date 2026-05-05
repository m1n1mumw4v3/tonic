# Interaction Checking

How a medication a user selects during onboarding ends up filtering or warning on supplements in the plan. This logic spans 4 files and 2 distinct mechanisms (key-based DB matching + hardcoded rule conditions). This page is the only place where the whole flow is laid out together.

## The two mechanisms

| Mechanism | Source of truth | Effect | Where it runs |
|---|---|---|---|
| **Key-based** | Supabase `drug_interactions` rows | exclude / warn / clear | `SupplementCatalog.checkInteractions` |
| **Rule-based** | Hardcoded `SafetyRules.allRules` conditions | exclude / warn / score-boost | `SafetyRules` (consulted by engine) |

Both run during `RecommendationEngine.generatePlan`. They overlap intentionally — the key-based path is data-driven and grows with Supabase; the rule-based path encodes case logic that can't be expressed as simple matches (e.g., "iron only excluded for males without specific risk factors").

## Key-based flow

### 1. UI: medication picker (`MedicationsScreen`)

The user picks medications. Picks come from one of two sources:

- **Supabase row** (`DBMedication`) — selected via the picker, persisted as a `UUID` in `profile.medicationIds`.
- **Custom string** — typed in by the user, stored in `profile.medications` (and possibly `profile.customMedications`).

The static [`MedicationKnowledgeBase`](../knowledge-bases/medication-kb.md) is **only** the UI fallback for the picker if Supabase is unavailable — it does not feed the engine.

### 2. Collect interaction keys (`SupplementCatalog.collectInteractionKeys`)

```swift
func collectInteractionKeys(medicationIds: [UUID], medications: [DBMedication]) -> Set<String> {
    let selected = medications.filter { medicationIds.contains($0.id) }
    return Set(selected.flatMap { $0.interactionKeys })
}
```

Each `DBMedication` row has an `interactionKeys: [String]` — typically the drug class plus the generic name. For example, omeprazole might have keys `["proton_pump_inhibitor", "omeprazole"]`.

The user's full set of keys is the union across selected medications.

> Custom-typed medications **don't contribute interaction keys** — they're not joined to any `DBMedication`. They only fire rule-based safety logic via `profile.medications.contains { ssriNames.contains(...) }` style matching.

### 3. Per-supplement check (`SupplementCatalog.checkInteractions`)

For each candidate supplement:

```swift
let matches = allInteractions.filter {
    $0.supplementId == thisId &&
    userInteractionKeys.contains($0.drugOrClass)
}
```

Then return:
- `.clear` if no matches.
- `.remove(matches)` if any match has `action == .avoid`.
- `.keepWithWarnings(matches)` otherwise.

### 4. Engine application (`filterByInteractions`)

`RecommendationEngine.filterByInteractions` walks every candidate name through `checkInteractions` and accumulates:

- `excluded: Set<String>` — supplements to drop from the plan.
- `warnings: [UUID: [DBDrugInteraction]]` — warnings to attach to surviving supplements.

The same function also applies:

- **Allergies** — fish/shellfish → exclude Omega-3 (EPA/DHA); dairy/milk/lactose → exclude Whey Protein Isolate.
- **Diet** — vegan/vegetarian → exclude Whey Protein Isolate.
- **Pregnancy/breastfeeding** — exclude Ashwagandha KSM-66, Berberine.
- **Absolute contraindications** — `DBContraindication.severity == .absolute`.
- **Safety rules** — calls `SafetyRules.allRules`, applies `excludeSupplements` for any rule whose condition fires.

### 5. Warnings → text (`generateInteractionNote`)

In Step 5's second pass, surviving supplements get `interactionNote` text built from their warnings:

| `action` | Sentence template |
|---|---|
| `separate_timing` | "Take separately from {drug} — {mechanism}." |
| `monitor` | "Monitor when taking with {drug} — {mechanism}." |
| `adjust_dose` | "Dose may need adjustment due to {drug} — {mechanism}." |
| (other) | "{mechanism}." |

If no warnings exist for a supplement but the user has medications, the engine runs `checkInteractions` again as a safety net so the note can say "No conflicts with your current medications" definitively.

If the user has *no* medications at all, the note says "No medication interactions to flag."

## Rule-based flow

Triggered by `SafetyRules.allRules`. Each rule has a closure `condition: (UserProfile, [DeepProfileModule]) -> Bool`. See [Safety Rules](../engines/safety-rules.md) for the four current rules and their match logic.

The engine consults the rules in two places:

- **Step 2 (`filterByInteractions`)** — `excludeSupplements` get added to the excluded set.
- **Second pass (interaction notes)** — `warnSupplements` cause `warningMessage` to be appended to the supplement's `interactionNote`.

The rules also feed score boosts via `SafetyRules.scoreBoosts(...)` at Step 1b2 — see [Scoring Pipeline](scoring-pipeline.md). Scoring isn't really "interaction checking" but the same rule conditions drive both, so changing one means thinking about the other.

## Multivitamin overlap (special case)

In the second pass, the engine checks specifically for `Iron` in the plan plus a multivitamin in `profile.currentSupplements` (substring match against `multivitamin / multi-vitamin / multi vitamin / centrum / one a day`) and appends:

> "Your multivitamin likely contains some iron. Consider checking the label before adding a standalone supplement."

This is hardcoded in the engine, not in `SafetyRules`. It bridges interaction-style logic (warning about a specific combination) without going through the formal rule infrastructure.

## Why two mechanisms

- **Key-based** scales: the Supabase `drug_interactions` table can be updated without an app release.
- **Rule-based** handles complex conditional logic (e.g., "iron male unless any of three exemptions") that can't be expressed as simple drug-class joins.

The two mechanisms can stack on the same supplement. Example: Iron for a male diabetic on omeprazole:
1. Iron-male guardrail (rule) excludes Iron *unless* exemption applies.
2. PPI safety rule **boosts** Iron via score (would re-add it if exclusion didn't fire first).
3. Drug-interaction key matching might add a warning if Iron + omeprazole has a key-based interaction row.

Order of evaluation matters. Exclusion always wins over warning/boost.

## Editing checklist

If you add a new medication that should affect supplements:

- **Preferred path:** add a row to Supabase `medications` with appropriate `interactionKeys`, plus rows in `drug_interactions` linking those keys to specific supplements. No code change needed.
- **Rule-based path:** if the logic is conditional (only for users meeting some criterion), add it to `SafetyRules.allRules`. Update [Safety Rules](../engines/safety-rules.md) and this page.
- **String-match path:** if you want to match the user-typed medication string for non-Supabase users, add the name to a list in `SafetyRules` (SSRI, PPI, diabetes lists are all there).

## Cross-references

- [Recommendation Engine](../engines/recommendation-engine.md) — Step 2 and second-pass note generation.
- [Safety Rules](../engines/safety-rules.md) — rule-based mechanism details.
- [Supplement Catalog](../knowledge-bases/supplement-catalog.md) — `checkInteractions` and `collectInteractionKeys`.
- [Medication KB](../knowledge-bases/medication-kb.md) — UI fallback.
