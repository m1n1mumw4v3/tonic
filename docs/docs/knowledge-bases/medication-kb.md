# Medication Knowledge Base (Static)

A curated registry of common medications used as the UI fallback for the medication picker during onboarding. **Not** consulted by the recommendation engine for interaction checking — that path uses the Supabase `medications` table (`DBMedication`) and its `interactionKeys` field.

**Source:** `Estus/Utilities/MedicationKnowledgeBase.swift`

## Schema

```swift
struct Medication {
    let name: String
    let category: String
    let genericName: String?
    let drugClass: String?
    let isCommon: Bool
}
```

## Contents

| Property | Type | Notes |
|---|---|---|
| `allMedications` | `[Medication]` | ~100 entries across 12 categories. |
| `commonMedications` | `[Medication]` | Top 7 by frequency: Levothyroxine, Lisinopril, Metformin, Atorvastatin, Omeprazole, Sertraline, Amlodipine. |
| `categoryPills` | `[(category, label, emoji)]` | 12 categories with display chips. |
| `medicationsByCategory` | `[String: [Medication]]` | Grouped + alphabetical within each. |

### Categories (12)

Blood Pressure · Antidepressants · Cholesterol · Thyroid · Blood Thinners · Sleep · Diabetes · ADHD · Stomach & Acid · Pain · Hormonal · Immune

## Search helpers

- `search(query:)` — case-insensitive substring match against name + genericName.
- `searchGrouped(query:)` — same, but returns `[(category, [Medication])]` for sectioned UI lists.
- `exactMatch(for:)` — exact name match (used for resolving display labels of typed-in medications).

## Where it's consumed

- `MedicationsScreen` and `MedicationPickerSheet` (`Estus/Features/Onboarding/Screens/`) — render the picker, the category chips, and search.
- Custom-typed medications still flow into `profile.medications` as raw strings.

## Where it's *not* consumed

- `RecommendationEngine` reads `profile.medicationIds: [UUID]` from Supabase-backed selections, then resolves them via `medications: [DBMedication]` (passed in at construction). Each `DBMedication` carries `interactionKeys: [String]` which match `DBDrugInteraction.drugOrClass`.
- `SafetyRules` matches profile.medications strings against hardcoded name lists (SSRI, PPI, diabetes) — it does **not** consult this static KB.

If Supabase fails to load medications, the picker degrades gracefully to showing the static list, but the user's selections won't have `medicationIds` (because no UUIDs were assigned), and the engine will only use string-match-based safety rules — drug-interaction key matching won't fire. This is the only meaningful behavioral difference.

## Editing

To add a medication:

1. Add a `Medication(...)` entry to `allMedications`.
2. Mark `isCommon: true` if it's frequent enough to surface in the top-7.
3. Make sure the `category` matches one in `categoryPills` exactly.

If the medication should drive interaction warnings or safety-rule exclusions, the relevant updates are:

- Add it to a `SafetyRules` rule's name list (e.g., the SSRI list).
- Add a row to the Supabase `medications` table with the right `interactionKeys` so the engine's key-based matching fires.

## Cross-references

- [Onboarding](../flows/onboarding.md) — medication picker screens.
- [Safety Rules](../engines/safety-rules.md) — how rule-based safety logic uses string matching.
- [Interaction Checking](../cross-cutting/interaction-checking.md) — full picture of how a medication ends up filtering supplements.
