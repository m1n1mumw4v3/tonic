# Supplement Name Matcher

Fuzzy-matches the strings users type for "supplements I'm currently taking" against the catalog. Drives two behaviors during plan generation: (1) deduplicating already-taken supplements, and (2) detecting form upgrades (e.g., user takes magnesium oxide → recommend magnesium glycinate with a note).

**Source:** `Estus/Utilities/SupplementNameMatcher.swift`

## API

```swift
SupplementNameMatcher.match(
    userSupplements: [String], catalog: SupplementCatalog
) -> [MatchResult]

struct MatchResult {
    let catalogName: String
    let matchType: MatchType   // exact | commonName | formVariant | partial
    let userInputName: String  // raw input, preserved for upgrade messages
}
```

Each user input is matched at most once; once a catalog entry is matched, it won't be matched again by a later input.

## Match priority (per input)

For each input string, attempt in order; first hit wins:

1. **`.exact`** — input lowercased equals `supplement.name.lowercased()`.
2. **`.commonName`** — input matches one of `supplement.commonNames` (lowercased).
3. **`.formVariant`** — input contains a key from `formVariantMap`. Skipped if input also exactly equals the catalog name (then it's already an exact match).
4. **`.partial`** — `supplement.name.contains(input)` OR `input.contains(supplement.name)`.

If none match, the input is dropped (no result).

## `formVariantMap`

Base compound substring → catalog supplement name. Currently:

| Substring | Maps to |
|---|---|
| `magnesium` | Magnesium Glycinate |
| `vitamin d`, `vitamin d3` | Vitamin D3 + K2 |
| `omega 3`, `omega-3` | Omega-3 (EPA/DHA) |
| `coq10`, `ubiquinol`, `ubiquinone` | CoQ10 |
| `ashwagandha` | Ashwagandha KSM-66 |
| `rhodiola` | Rhodiola Rosea |
| `iron` | Iron |
| `zinc` | Zinc |
| `vitamin c` | Vitamin C |
| `vitamin b`, `b complex`, `b12`, `b-12` | Vitamin B Complex |
| `biotin` | Biotin |
| `collagen` | Collagen Peptides |
| `creatine` | Creatine Monohydrate |
| `melatonin` | Melatonin |
| `nac`, `n-acetyl cysteine` | NAC |
| `berberine` | Berberine |
| `lion's mane`, `lions mane` | Lion's Mane |
| `tart cherry` | Tart Cherry Extract |
| `whey protein`, `whey`, `protein powder` | Whey Protein Isolate |
| `pea protein`, `plant protein` | Plant Protein Blend |
| `probiotics`, `probiotic` | Probiotics |
| `l-theanine`, `theanine` | L-Theanine |

## `formUpgradeMessages`

Specific user-input strings → upgrade explanation. If the user's input matches a key here, the engine uses that exact message; otherwise it falls back to a generic *"You're currently taking X. We've recommended Y — a more bioavailable form."*

| Input substring | Upgrade message |
|---|---|
| `magnesium oxide` | "You're currently taking magnesium oxide. We've recommended magnesium glycinate instead — it's better absorbed with fewer GI side effects." |
| `magnesium citrate` | "You're currently taking magnesium citrate. We've recommended magnesium glycinate — it's gentler on digestion and well-suited for sleep support." |
| `vitamin d2` | "You're currently taking vitamin D2. We've recommended D3 + K2 instead — D3 is 87% more effective at raising blood levels, and K2 directs calcium to bones." |
| `fish oil` | "You're already taking fish oil. We've ensured Omega-3 dosing accounts for your current intake." |
| `ubiquinone` | "You're taking ubiquinone (standard CoQ10). We've recommended ubiquinol — the active form that's 2-3x better absorbed." |
| `iron sulfate`, `ferrous sulfate` | "You're taking [form]. We've recommended iron bisglycinate — it's 4x better absorbed with fewer GI side effects." |

## How the engine consumes match results

In `RecommendationEngine.generatePlan` Step 1c:

```swift
switch match.matchType {
case .exact, .commonName:
    candidateScores.removeValue(forKey: match.catalogName)   // user already takes it; remove
case .formVariant:
    formVariantMatches[match.catalogName] = match            // keep, attach upgrade note in Step 5
case .partial:
    break                                                     // keep without action; user reviews
}
```

In Step 5, if `formVariantMatches[supplement.name]` exists, the engine prepends an upgrade note to `whyInYourPlan` (concatenated, not separate field — but `formUpgradeNote` is also stored on `PlanSupplement` for UI consumption).

## Adding a new supplement to the matcher

When you add a new supplement to the catalog:

1. If users might type other names, add aliases to the supplement's `commonNames` (handled in the KB / Supabase row, not here).
2. If the supplement has multiple forms (oxide vs. glycinate), add a `formVariantMap` entry for the base compound.
3. If a specific form should trigger a tailored upgrade message, add a `formUpgradeMessages` entry.

## Cross-references

- [Recommendation Engine](recommendation-engine.md) — Step 1c and Step 5.
- [Supplement Catalog](../knowledge-bases/supplement-catalog.md) — `allSupplements`, `commonNames`, `supplement(named:)`.
