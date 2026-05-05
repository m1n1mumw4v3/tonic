# Safety Rules

Hard-coded conditional guardrails that exclude or warn on supplements based on the user's medications, sex, age, exercise level, or deep-profile responses. Also generates score boosts for "defensive" nutrients.

**Source:** `Estus/Utilities/SafetyRules.swift`

## Shape

```swift
struct SafetyRule {
    let id: String
    let description: String
    let condition: (UserProfile, [DeepProfileModule]) -> Bool
    let excludeSupplements: [String]   // hard exclusions
    let warnSupplements: [String]      // soft warnings (appended to interactionNote)
    let warningMessage: String
}

enum SafetyRules {
    static let allRules: [SafetyRule] = [
        ssriSerotonergicRule,
        diabeticBloodSugarRule,
        ppiNutrientDepletionRule,
        ironMaleGuardrailRule,
    ]
}
```

## The four rules

### 1. `ssri_serotonergic` — SSRI + serotonergic supplements

**Fires when** the profile lists an SSRI/SNRI by name OR the deep-profile `stressNervousSystem` module's `psych_medications` response is non-empty (and not "none").

**SSRI names matched** (lowercase, exact):
`sertraline, zoloft, escitalopram, lexapro, fluoxetine, prozac, citalopram, celexa, paroxetine, paxil, venlafaxine, effexor, duloxetine, cymbalta, trazodone`.

**Effect:** currently empty `excludeSupplements` and `warnSupplements` — placeholder for 5-HTP and St. John's Wort, neither of which are in the catalog yet. The rule is wired up so adding either will immediately exclude/warn.

Warning message: *"You're taking an SSRI or similar medication. Some serotonergic supplements have been excluded or flagged to reduce the risk of serotonin syndrome."*

### 2. `diabetic_blood_sugar` — Diabetes meds + Berberine

**Fires when** profile lists a diabetes medication OR deep-profile `labWorkBiomarkers.lab_blood_sugar` is `"diabetic"` or `"prediabetic"`.

**Diabetes names matched** (lowercase, exact):
`metformin, glipizide, glyburide, insulin, jardiance, empagliflozin, farxiga, dapagliflozin, ozempic, semaglutide, trulicity, dulaglutide, mounjaro, tirzepatide, januvia, sitagliptin, pioglitazone`.

**Effect:** warns on `Berberine` (does not exclude). Warning: *"Berberine can lower blood sugar. If you're on diabetes medication, monitor your glucose closely and consult your doctor before adding berberine."*

### 3. `ppi_nutrient_depletion` — PPIs deplete minerals

**Fires when** profile lists a PPI medication OR deep-profile `gutHealth.gut_ppi_usage == "yes_currently"`.

**PPI names matched:** `omeprazole, prilosec, pantoprazole, protonix, esomeprazole, nexium, lansoprazole, prevacid, rabeprazole, aciphex, dexlansoprazole, dexilant`.

**Effect:** **score boosts only** (no exclusions, no warnings). See `scoreBoosts(...)` below.

### 4. `iron_male_guardrail` — Males don't need iron unless…

**Fires when** `profile.sex == .male` AND **none** of the exemptions apply:

- diet is `vegan` or `vegetarian`
- exercise is `fivePlus` per week
- deep-profile `labWorkBiomarkers.lab_iron_ferritin == "currently_low"`

**Effect:** excludes `Iron`. No warning message (silent exclusion).

## Score boosts (`scoreBoosts`)

Returns `[supplementName: Int]` independent of warnings/exclusions.

### From `ppi_nutrient_depletion`
- Magnesium Glycinate: +2
- Vitamin B Complex: +2
- Iron: +1

### From birth control / HRT
*Triggered by deep-profile `hormonalMetabolic.hormonal_birth_control_hrt ∈ {birth_control, hrt}`.*

- Magnesium Glycinate: +2
- Vitamin B Complex: +2
- Zinc: +1
- CoQ10: +1

### From sleep deep-profile
*From `sleepCircadian` module.*

| Response field | Value | Boost |
|---|---|---|
| `sleep_onset_latency` | `40_60` or `over_60` | Melatonin +2 |
| `sleep_onset_latency` | `20_40` | Melatonin +1 |
| `sleep_wake_frequency` | `three_plus` | Magnesium Glycinate +2 |
| `sleep_wake_frequency` | `twice` | Magnesium Glycinate +1 |

### Female iron boosts
*Only when `profile.sex == .female`.*

- Vegan or vegetarian: Iron +2
- Exercise `fivePlus`: Iron +1
- Age 18–50 inclusive: Iron +1

These can stack — a 28-year-old vegan female with intense exercise gets Iron +4.

## Where rules are applied

| Phase | What runs | Effect |
|---|---|---|
| `generatePlan` Step 1b2 | `scoreBoosts(profile, deepProfileModules)` | Adds to `candidateScores`. |
| `generatePlan` Step 2 (`filterByInteractions`) | `for rule in allRules where rule.condition(...)` → add `excludeSupplements` to excluded set | Hard removal from candidates. |
| `generatePlan` 2nd pass (interaction notes) | `for rule in allRules where rule.condition(...)` → if supplement in `warnSupplements`, append `warningMessage` to its `interactionNote` | Visible warning text. |

## Editing / adding a rule

1. Add a new `private static let myRule = SafetyRule(...)` in this file.
2. Append it to `allRules`.
3. If it changes scoring, add a new branch to `scoreBoosts(...)`.
4. If the rule depends on a new deep-profile question, ensure that question is present in the relevant `Estus/Features/DeepProfile/Modules/*.swift` module — otherwise the response key won't exist and the rule will silently never fire.
5. Update [Recommendation Engine](recommendation-engine.md), [Scoring Pipeline](../cross-cutting/scoring-pipeline.md), and this page.

## Cross-references

- [Recommendation Engine](recommendation-engine.md) — pipeline integration points.
- [Interaction Checking](../cross-cutting/interaction-checking.md) — how safety rules layer on top of drug-interaction key matching.
- [Scoring Pipeline](../cross-cutting/scoring-pipeline.md) — how `scoreBoosts` combines with goal weights and personalization deltas.
