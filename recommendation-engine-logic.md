# Recommendation Engine Logic

How user data flows through the engine to produce a personalized supplement plan.

---

## Architecture Overview

The engine is composed of four cooperating modules, all deterministic and local (no API calls during recommendation):

| Module | Role |
|--------|------|
| **SupplementCatalog** | Central data source — indexes all supplement metadata, goal mappings, synergies, exclusion groups, personalization signals, and dose ranges. Loads from Supabase or falls back to a static `SupplementKnowledgeBase`. |
| **PersonalizationScorer** | Evaluates Supabase personalization signals against the user's profile to produce per-supplement score adjustments and dosage modifiers. |
| **SafetyRules** | Enforces drug-class safety rules (SSRI, diabetes, PPI) — excludes supplements, attaches warnings, and applies conditional score boosts. Reads both the base profile and deep profile modules. |
| **SupplementNameMatcher** | Matches user-entered current supplements against the catalog using 4-tier fuzzy matching (exact, common name, form variant, partial) to deduplicate and suggest form upgrades. |

---

## How the Plan Gets Built (High-Level Flow)

1. **Score supplements** based on health goals (evidence-weighted goal map)
2. **Apply personalization signal adjustments** (lifestyle, baseline wellness, demographics)
3. **Apply safety rule score boosts** (e.g., PPI users get boosted minerals)
4. **Deduplicate against current supplements** (skip what the user already takes)
5. **Filter unsafe supplements** (medication interactions, allergies, pregnancy, diet, safety rules, contraindications)
6. **Deduplicate exclusion groups** (e.g., only one protein source)
7. **Filter out boost-only filler** (remove supplements with zero goal overlap)
8. **Tier-aware selection** (Core first, then Targeted, then Supporting; max 7)
9. **Force-add contextual supplements** (vegan diet, birth control/HRT, PPI)
10. **Adjust dosages** (personalization signals, then legacy rules, then clamp to safe range)
11. **Generate personalized text** (why it's in your plan, dosage rationale, what to expect)
12. **Assign tiers** (Core / Targeted / Supporting, with minimum quality guarantee)
13. **Generate interaction notes, safety warnings, and multivitamin overlap checks**
14. **Resolve timing conflicts** (mineral absorption pairs get separated)
15. **Write an AI-style summary** of the plan

---

## Step 1: Goal-Based Scoring

Health goals are the **primary driver** of what ends up in the plan. Each goal maps to a set of supplements with an evidence weight:

| Weight | Meaning |
|--------|---------|
| 3 | Strong evidence (meta-analyses, 3+ clinical trials) |
| 2 | Moderate evidence (limited trials, mixed results) |
| 1 | Emerging evidence (mechanistic/preclinical) |

When a user selects multiple goals, scores **stack**. A supplement that maps to several of the user's goals accumulates a higher total score and is more likely to make the cut.

### Goal -> Supplement Mappings

**Sleep**
- Magnesium Glycinate (3), L-Theanine (2), Melatonin (2), Tart Cherry (1)

**Energy**
- Vitamin B Complex (3), CoQ10 (2), Iron (2), Vitamin D3+K2 (2), Rhodiola (2)

**Focus**
- Omega-3 (3), L-Theanine (2), Lion's Mane (2), B Complex (1)

**Stress & Anxiety**
- Ashwagandha (2), L-Theanine (2), Magnesium (2), Rhodiola (2)

**Gut Health**
- Probiotics (3), Berberine (2), Collagen (1), Zinc (1)

**Immune Support**
- Vitamin D3+K2 (3), Vitamin C (2), Zinc (2), NAC (1)

**Muscle Recovery**
- Creatine (3), Whey Protein (3), Magnesium (2), Plant Protein (2), Omega-3 (2), D3+K2 (2), Tart Cherry (1)

**Skin, Hair & Nails**
- Collagen (3), Biotin (2), Vitamin C (1), Zinc (1)

**Longevity**
- Omega-3 (3), D3+K2 (2), CoQ10 (2), NAC (2)

**Heart Health**
- CoQ10 (3), Omega-3 (3), Magnesium (2), D3+K2 (2), Berberine (1)

**Example:** A user who picks Sleep + Stress & Anxiety -> Magnesium scores 3+2 = 5, L-Theanine scores 2+2 = 4, Ashwagandha scores 0+2 = 2.

---

## Step 2: Personalization Signal Adjustments

After base goal scoring, `PersonalizationScorer` evaluates Supabase-defined signals against the user's profile. Each signal specifies a `profileField`, a `condition` to match, an `effect` (increase/decrease), and a `magnitude`.

### Profile Fields Evaluated

| Field Key | Source | How It's Read |
|-----------|--------|---------------|
| `diet_type` | Onboarding | Enum value (e.g., "vegan", "keto") |
| `exercise_frequency` | Onboarding | Enum value (e.g., "threeToFour") |
| `stress_level` | Onboarding | Enum value (e.g., "high") |
| `alcohol_weekly` | Onboarding | Enum value (e.g., "fourToSeven") |
| `sex` | Onboarding | Enum value (e.g., "female") |
| `caffeine_level` | Computed | Sums coffee + tea + energy drinks: "high" (4+), "moderate" (2-3), "low" (1), "none" (0) |
| `age_bracket` | Computed | "under_18", "18-29", "30-49", "50-64", "65+" |
| `baseline_sleep` | Onboarding | Bucketed: "low" (0-3), "moderate" (4-6), "high" (7+) |
| `baseline_energy` | Onboarding | Same bucketing as above |
| `baseline_clarity` | Onboarding | Same bucketing as above |
| `baseline_mood` | Onboarding | Same bucketing as above |
| `baseline_gut` | Onboarding | Same bucketing as above |
| `is_pregnant` | Onboarding | "true" / "false" |
| `is_breastfeeding` | Onboarding | "true" / "false" |

### Magnitude -> Score Delta

| Magnitude | Delta |
|-----------|-------|
| minor | +/- 1 |
| moderate | +/- 2 |
| major | +/- 3 |
| (missing) | +/- 1 |

This means personalization signals can now cause supplements to be promoted or demoted in the ranking — lifestyle factors affect **selection**, not just copy.

---

## Step 3: Safety Rule Score Boosts

`SafetyRules` can also add score boosts based on drug-nutrient depletion logic. Currently:

| Condition | Supplement Boosted | Boost |
|-----------|-------------------|-------|
| User takes a PPI (omeprazole, pantoprazole, etc.) | Magnesium Glycinate | +2 |
| User takes a PPI | Vitamin B Complex | +2 |
| User takes a PPI | Iron | +1 |

This ensures supplements that compensate for medication-induced deficiencies are more likely to make the cut.

---

## Step 4: Current Supplement Deduplication

The engine now cross-references the user's `currentSupplements` list against the catalog using `SupplementNameMatcher`. This prevents recommending something the user already takes.

### Match Types (in priority order)

| Match Type | Behavior | Example |
|------------|----------|---------|
| **Exact** | Supplement removed from candidates | "Magnesium Glycinate" matches catalog exactly |
| **Common name** | Supplement removed from candidates | "Fish Oil" matches Omega-3 (EPA/DHA) via `commonNames` |
| **Form variant** | Kept in plan with upgrade note | "Magnesium oxide" -> recommends Magnesium Glycinate with form upgrade message |
| **Partial** | Kept in plan, flagged for review | Substring match in either direction |

### Form Upgrade Messages

When a user takes an inferior form, the engine recommends the better form and prepends a message to the "Why It's In Your Plan" text:

- **Magnesium oxide/citrate** -> "We've recommended Magnesium Glycinate — the glycinate form is better absorbed and gentler on digestion."
- **Vitamin D2** -> "We've recommended Vitamin D3 + K2 — D3 is 87% more effective than D2, and K2 helps direct calcium to your bones."
- **Ubiquinone (CoQ10)** -> "We've recommended the ubiquinol form — it's 2-3x better absorbed than ubiquinone."
- **Iron sulfate/ferrous sulfate** -> "We've recommended iron bisglycinate — it's up to 4x better absorbed with significantly fewer GI side effects."
- **Fish oil (generic)** -> Dosing note that accounts for current intake.

---

## Step 5: Safety Filtering (Exclusions)

Before ranking, the engine removes supplements that aren't safe for this user. This now combines multiple filtering layers.

### 5a: Key-Based Drug Interaction Checking

Medications are mapped to **interaction keys** via the Supabase knowledge base (or the static `MedicationKnowledgeBase` as fallback). Each supplement also declares which interaction keys it conflicts with. The catalog's `checkInteractions()` returns one of:

| Decision | Meaning |
|----------|---------|
| `.remove` | Absolute contraindication — supplement dropped entirely |
| `.keepWithWarnings` | Supplement stays with visible warnings (mechanism, severity, recommended action) |
| `.clear` | No interaction |

Warning actions include: `separateTiming`, `monitor`, `adjustDose`, `avoid`.

### 5b: Database Contraindications

Absolute contraindications from the Supabase `contraindications` table also trigger removal.

### 5c: Allergy Exclusions

| Allergy | Supplement Removed |
|---------|-------------------|
| Fish or Shellfish | Omega-3 (EPA/DHA) |
| Dairy, Milk, or Lactose | Whey Protein Isolate |

### 5d: Pregnancy / Breastfeeding Exclusions

If the user is pregnant or breastfeeding, these are removed:
- Ashwagandha KSM-66
- Berberine

### 5e: Diet-Based Exclusions

If the user is **vegan or vegetarian**:
- Whey Protein Isolate is removed
- (Vitamin B Complex and Vitamin D3+K2 are force-added later in Step 9)

### 5f: Safety Rule Exclusions (Drug-Class Rules)

`SafetyRules` defines three drug-class rules that check both medications and deep profile responses:

**1. SSRI / Serotonergic Rule**
- **Triggers when:** User takes an SSRI-class medication (sertraline/Zoloft, escitalopram/Lexapro, fluoxetine/Prozac, citalopram/Celexa, paroxetine/Paxil, venlafaxine/Effexor, duloxetine/Cymbalta, trazodone) OR reported psychiatric medications in the Stress & Nervous System deep profile module.
- **Excludes:** None currently (5-HTP, St. John's Wort not in catalog)
- **Warns:** None currently
- **Note:** Infrastructure is in place — exclusions will activate when serotonergic supplements are added.

**2. Diabetic / Blood Sugar Rule**
- **Triggers when:** User takes diabetes medication (metformin, glipizide, glyburide, insulin, Jardiance, Farxiga, Ozempic, Trulicity, Mounjaro, Januvia, pioglitazone) OR indicated diabetic status in the Lab Work deep profile module.
- **Excludes:** None
- **Warns:** Berberine — "Berberine can lower blood sugar. Monitor glucose closely..."

**3. PPI / Nutrient Depletion Rule**
- **Triggers when:** User takes a proton pump inhibitor (omeprazole/Prilosec, pantoprazole/Protonix, esomeprazole/Nexium, lansoprazole/Prevacid, rabeprazole/AcipheX, dexlansoprazole/Dexilant).
- **Excludes:** None (boosts instead — see Step 3)
- **Warns:** None
- **Effect:** Score boosts for depleted nutrients.

---

## Step 6: Exclusion Group Deduplication

Some supplements occupy the same functional slot. The engine only keeps the highest-scoring one from each group:

| Group | Supplements | Tiebreak |
|-------|------------|----------|
| Protein | Whey Protein Isolate, Plant Protein Blend | Lower priority number wins ties |

If both proteins scored equally, Whey wins (lower priority number) — unless it was already excluded by diet/allergy, in which case Plant Protein takes its place.

---

## Step 7: Goal Overlap Filtering

After exclusion group dedup, the engine filters out **boost-only filler** — supplements whose score came entirely from personalization signals or safety boosts but have **zero goal overlap** with the user's selected health goals.

This prevents scenarios where a signal boost (e.g., PPI → Iron +1) causes a supplement with no goal connection to enter the plan as low-value filler. Supplements that genuinely belong despite no goal overlap (vegan B Complex, birth control B Complex, PPI B Complex) are handled by explicit force-adds in Step 9.

---

## Step 8: Tier-Aware Selection

Instead of a simple top-N with category caps, the engine uses **tier-aware selection** that prioritizes high-evidence supplements:

1. **Assign provisional tiers** based on score: Core (≥5), Targeted (≥3), Supporting (<3)
2. **Select all Core** candidates first (up to the max of 7)
3. **Fill remaining slots with Targeted** candidates
4. **Add Supporting** candidates:
   - If Core + Targeted < 5 total, fill freely up to 7
   - If Core + Targeted ≥ 5, allow **at most 1** Supporting supplement
5. Sort by score within each tier, alphabetically for ties

This ensures the plan is anchored by high-evidence supplements rather than diluted by low-scoring fillers. Max plan size is **7 supplements**.

---

## Step 9: Contextual Force-Adds

After tier-aware selection, the engine force-adds supplements that are essential for specific user contexts, even if they didn't score high enough to make the cut naturally. Force-adds respect the exclusion list (won't add something that was safety-filtered).

| Condition | Source | Supplement Force-Added |
|-----------|--------|----------------------|
| Vegan or vegetarian diet | Onboarding | Vitamin B Complex, Vitamin D3 + K2 |
| Hormonal birth control | Deep profile (Hormonal & Metabolic module) | Vitamin B Complex |
| Hormone replacement therapy (HRT) | Deep profile (Hormonal & Metabolic module) | Vitamin B Complex |
| Takes a PPI | Onboarding medications OR deep profile (Gut Health module) | Vitamin B Complex |

---

## Step 10: Dosage Adjustments

Dosage adjustment is now a **3-layer system**:

### Layer 1: Personalization Signal Dose Adjustments

The engine reads signals from `SupplementCatalog.personalizationSignals(for:)` and adjusts dosages based on profile matches:

| Magnitude | Multiplier (increase) | Multiplier (decrease) |
|-----------|----------------------|----------------------|
| minor | 1.15x | 0.87x |
| moderate | 1.25x | 0.80x |
| major | 1.50x | 0.67x |

The signal's `rationale` field is appended to the dosage rationale text (e.g., "Adjusted to upper range: ...").

### Layer 2: Legacy Hardcoded Rules (Safety Net)

These fire after signals and act as a fallback until all rules are expressed as signals:

| Condition | Supplement | Adjustment |
|-----------|-----------|------------|
| Age > 65 | Rhodiola, CoQ10 | Reduce dose by 25% |
| Weight > 200 lbs | Vitamin D3+K2 | Set to 4,000 IU |
| Female | Iron | Set to 27mg (RDA for women) |
| Male | Iron | Set to 8mg (RDA for men) |

### Layer 3: Clamp to Knowledge Base Safe Range

After all adjustments, the final dosage is clamped to the supplement's safe range from the knowledge base:
- `low` <= dosage <= `high` (from `doseRangeLow` / `doseRangeHigh`)
- dosage <= `upperTolerableLimit` (if defined)

This prevents personalization signals from pushing a dosage outside clinically safe bounds.

---

## Step 11: Personalized Text Generation

For each supplement in the plan, the engine generates three pieces of copy:

### "Why It's In Your Plan"

A narrative opener specific to each supplement, connected to the user's matched goals. Goals are sorted by weight so the strongest benefit leads the sentence.

> *"Magnesium glycinate is one of the most effective natural supports for sleep quality — one of your top goals."*

If the supplement was included due to diet (vegan/vegetarian force-add) and has no goal overlap:
> *"Vitamin B Complex helps cover nutritional gaps common in a vegan diet, supporting overall energy and immune health."*

**Boost-only supplements** (force-added via birth control, HRT, PPI, or contextual signals without goal overlap) get specific templates from `boostWhyTemplates` instead of the generic fallback. The engine looks up the highest-magnitude fired signal for the supplement and uses its template:

| Signal Type | Supplement | Example Copy |
|-------------|-----------|-------------|
| `birth_control` | Vitamin B Complex | "Hormonal birth control can deplete B6, B12, and folate — B Complex helps replenish these essential nutrients." |
| `hrt` | Vitamin B Complex | "Hormone replacement therapy increases demand for B vitamins, supporting energy and cognitive clarity." |
| `ppi` | Vitamin B Complex | "PPIs impair B12 absorption over time — B Complex helps maintain healthy levels and energy." |
| `ppi` | Magnesium Glycinate | "Long-term PPI use reduces magnesium absorption — supplementation helps prevent deficiency." |
| `ppi` | Iron | "PPIs reduce stomach acid needed for iron absorption — supplementation supports healthy iron stores." |
| `high_stress` | Ashwagandha KSM-66 | "Given your elevated stress levels, Ashwagandha helps support stress resilience and balance." |
| `heavy_alcohol` | Vitamin B Complex | "Alcohol depletes B vitamins, especially B1 and folate — B Complex helps replenish stores." |
| `heavy_alcohol` | NAC | "NAC supports glutathione production, which is heavily taxed by alcohol metabolism." |
| `vegan_diet` | Iron | "Plant-based iron is less bioavailable — supplementation helps maintain healthy iron levels on a vegan diet." |
| `sleep_onset` | Melatonin | "Based on your difficulty falling asleep, low-dose melatonin helps reset your sleep onset timing." |
| `sleep_maintenance` | Magnesium Glycinate | "Based on your nighttime waking pattern, magnesium glycinate supports sleep continuity." |
| `low_sleep_baseline` | Magnesium Glycinate | "With sleep being a challenge, magnesium glycinate supports better sleep onset and continuity." |
| `low_energy_baseline` | CoQ10 | "Low baseline energy suggests your cells may benefit from CoQ10's mitochondrial support." |
| `age_50_plus` | CoQ10 | "Natural CoQ10 production declines with age — supplementation supports sustained energy." |
| `age_50_plus` | Collagen Peptides | "Collagen production decreases significantly after 50 — supplementation supports skin and joint health." |

If no boost template matches, the fallback is: *"[Supplement name] was included based on your overall health profile."*

If the user takes an inferior form (form variant match), the form upgrade message is prepended:
> *"We've recommended Magnesium Glycinate — the glycinate form is better absorbed and gentler on digestion. Magnesium glycinate is one of the most effective natural supports for..."*

### "Dosage Rationale"

Science-backed explanation of the dosage from the knowledge base, plus adjustment context from legacy rules and personalization signals.

> *"400mg — the upper end of clinically studied range."*
> *"Adjusted to 4,000 IU based on your body weight."*
> *"Adjusted to upper range: higher demands during periods of elevated physical activity."*

### "What To Look For" (Expected Results)

Template-based text with two layers of personalization:

**Layer 1: Placeholder substitutions** from the base template:
- `{caffeine_note}` — If any daily caffeine > 0: adds caffeine + supplement synergy note
- `{stress_note}` — If stress is high/very high: adds stress-specific benefit framing
- `{exercise_note}` — If exercise is 3+/week: adds exercise recovery context

> *"Better sleep onset and fewer nighttime wake-ups, especially if you pair it with your morning caffeine. Reduced muscle tension after workouts."*

**Layer 2: Signal-based personalized copy** — After placeholder resolution, the engine appends up to 2 contextual sentences from `signalCopyMap`, matched by fired signals sorted by magnitude. This provides deeper personalization based on diet, medications, deep profile responses, age, and baseline wellness:

| Signal Type | Example Supplements | Example Copy |
|-------------|-------------------|-------------|
| `vegan_diet` | B Complex, D3+K2, Iron | "On a plant-based diet, methylated B12 is especially important since it's not found in plant foods." |
| `heavy_alcohol` | B Complex, NAC, Magnesium, Zinc | "Alcohol depletes B vitamins, especially B1 and folate — consistent supplementation helps replenish stores." |
| `birth_control` | B Complex, Magnesium | "Hormonal birth control can deplete B6, B12, and folate — watch for improved energy and mood stability." |
| `hrt` | B Complex, Magnesium | "HRT can increase demand for B vitamins — watch for improvements in energy and cognitive clarity." |
| `ppi` | Magnesium, B Complex, Iron | "PPIs reduce magnesium absorption over time — supplementation helps prevent deficiency." |
| `sleep_onset` | Melatonin | "Based on your reported difficulty falling asleep, low-dose melatonin may help reset your sleep onset timing." |
| `sleep_maintenance` | Magnesium | "Based on your nighttime waking pattern, magnesium glycinate may help improve sleep continuity." |
| `age_50_plus` | CoQ10, Collagen | "Natural CoQ10 production declines with age — you may notice improved sustained energy." |
| `low_sleep_baseline` | Magnesium, Melatonin | "Given your current sleep quality, improvements in sleep onset and continuity may be especially noticeable." |
| `low_energy_baseline` | B Complex, CoQ10 | "With your current energy levels, B vitamin support for energy metabolism may be especially noticeable." |
| `high_stress` | Ashwagandha, L-Theanine, Magnesium | "Given your high stress levels, you may notice reduced anxiety and improved stress resilience within 2-4 weeks." |

### Additional Enriched Fields

Each plan supplement also carries:
- **`expectedTimeline`** — How long until results (e.g., "2-4 weeks for sleep improvements")
- **`formAndBioavailability`** — Form guidance (e.g., "Glycinate form is preferred for better absorption")
- **`evidenceLevel`** — Strong / Moderate / Emerging with display text
- **`interactionWarnings`** — Structured warning data (drug, severity, mechanism, action)
- **`formUpgradeNote`** — If user takes an inferior form

---

## Step 12: Tier Assignment

Each supplement is assigned a tier based on its accumulated score (goal weights + personalization signal adjustments):

| Tier | Score Threshold | Meaning |
|------|----------------|---------|
| **Core** | >= 5 | Highest impact for this user's profile |
| **Targeted** | >= 3 | Strong support for specific goals |
| **Supporting** | < 3 | Complementary additions |

### Minimum Quality Guarantee

If fewer than 2 supplements land in Core or Targeted tiers, the engine **promotes** the top-scoring Supporting supplements to Targeted. This ensures every plan has at least 2 visibly high-tier supplements, even for users with narrow goal selections.

---

## Step 13: Interaction Notes & Safety Warnings

After tier assignment, the engine generates an `interactionNote` for each supplement in a second pass (since it needs to know the full supplement list for synergy detection).

### Synergy Detection

When two supplements that work well together both end up in the plan, the engine notes the synergy:

- **L-Theanine + Caffeine** (from profile, not plan) -> "Pairs well with your daily caffeine — promotes calm focus, smooths out jitters."
- **Magnesium Glycinate + Vitamin D3+K2** -> "Pairs well with Vitamin D3 + K2 in your plan — magnesium aids vitamin D activation."
- **Vitamin C + Iron** -> "Pairs well with Iron in your plan — enhances iron absorption by up to 6x."
- **Vitamin C + Collagen** -> "Pairs well with Collagen Peptides in your plan — required for collagen synthesis."
- **Vitamin C + NAC** -> "Pairs well with NAC in your plan — supports glutathione recycling."
- **CoQ10 + Omega-3** -> "Pairs well with Omega-3 in your plan — combined cardiovascular support."
- **Creatine + Whey/Plant Protein** -> "Pairs well with Whey Protein Isolate in your plan — maximizes muscle protein synthesis."
- **Creatine + Omega-3** -> "Pairs well with Omega-3 in your plan — combined recovery support."

### Medication Interaction Notes

If the user takes medications:
- Supplements with warnings get specific notes: "Take separately from [drug] — [mechanism]." / "Monitor when taking with [drug]." / "Dose may need adjustment due to [drug]."
- Supplements without conflicts get: "No conflicts with your current medications."

If the user takes no medications: "No medication interactions to flag."

### Safety Rule Warnings

SafetyRules warnings are appended to the interaction note for supplements in the `warnSupplements` list:
- Diabetic rule on Berberine: "Berberine can lower blood sugar. Monitor glucose closely..."

### Multivitamin Iron Overlap Detection

If Iron is in the plan and the user's `currentSupplements` list contains a multivitamin (detected via keywords: "multivitamin", "multi-vitamin", "centrum", "one a day"), a note is appended: *"Your multivitamin likely contains some iron. Consider checking the label before adding a standalone supplement."*

---

## Step 14: Timing Conflict Resolution

After interaction notes, the engine checks for **mineral absorption conflicts** — pairs of supplements that compete for the same absorption pathway when taken at the same time.

### Conflict Pairs

| Supplement A | Supplement B | Reason |
|-------------|-------------|--------|
| Iron | Zinc | Compete for the DMT-1 transporter |
| Iron | Calcium | Calcium inhibits iron absorption |
| Zinc | Calcium | Compete for absorption |
| Magnesium Glycinate | Iron | Magnesium reduces iron absorption |

### Resolution Logic

When both supplements in a conflict pair are in the plan **and share the same timing**:

1. The **lower-scored** supplement is identified as the one to move
2. If it has `emptyStomach` timing (e.g., Iron), timing is **not changed** — instead a spacing note is added: *"Iron and zinc compete for the DMT-1 transporter. Take at least 2 hours apart from Zinc."*
3. Otherwise, timing is shifted to the **opposite time of day** (morning → evening, evening → morning) with an explanation: *"Timing adjusted to evening to avoid absorption conflict with Iron. Magnesium reduces iron absorption. Take at least 2 hours apart."*

### Final Sort Order

After timing conflicts are resolved, the plan is sorted by:
1. **Tier** (Core → Targeted → Supporting)
2. **Timing** within each tier (morning → with food → empty stomach → afternoon → evening → bedtime)

---

## Step 15: AI Summary

The engine builds a 1-3 sentence summary using a topic-tracking system to avoid repetition.

**Sentence 1 — Foundation:** Names the top 1-2 core-tier supplements and the user's top goals.
> *"Your plan is built around Magnesium Glycinate and Vitamin D3+K2 as your foundation for sleep quality and daily energy."*

**Sentence 2 — Lifestyle Insight:** Picks the most relevant lifestyle factor (in priority order):
1. Caffeine + L-Theanine in plan -> coffee/focus message
2. High stress + Ashwagandha in plan -> stress relief message
3. Active exercise + Creatine in plan -> recovery message
4. Active exercise + Whey or Plant Protein (no Creatine) -> protein/recovery message
5. Vegan/vegetarian + B Complex or D3+K2 -> nutrient gap message
6. Low baseline sleep (<=4) + Magnesium -> sleep message

**Sentence 3 — Actionable Tip:** A practical usage tip, chosen to avoid the topic already covered by the lifestyle sentence:
- Magnesium timing (if sleep not already covered)
- Magnesium + D3 synergy (if diet not already covered)
- Ashwagandha consistency note (if stress not already covered)
- Omega-3 with food tip
- Probiotics empty stomach tip
- General consistency fallback

---

## How Each Onboarding Question Influences the Plan

### Questions That Directly Influence Supplement Selection

| Screen | Question | How It's Used |
|--------|----------|---------------|
| **Health Goals** | Pick up to 4 goals | **Primary driver.** Maps directly to supplement scoring via evidence-weighted goal map. This is the single most important input. |
| **Medications** | Current medications | **Safety filter.** Maps medication IDs to interaction keys. Supplements with matching interactions are removed or flagged with warnings. Also triggers safety rules (SSRI, diabetic, PPI). |
| **Allergies** | Known allergens | **Safety filter.** Fish/shellfish -> removes Omega-3. Dairy -> removes Whey Protein. |
| **Diet Type** | Dietary pattern | Vegan/vegetarian -> removes Whey Protein. Also triggers force-adds (B Complex, D3+K2) in Step 9. Evaluated by personalization signals for all diet types. |
| **Pregnancy / Breastfeeding** | Pregnancy status | **Safety filter.** Removes Ashwagandha and Berberine. Only shown to female users. |
| **Current Supplements** | What they already take | **Deduplication.** Exact and common-name matches are removed from candidates. Form variants trigger upgrade recommendations with explanatory notes. |

### Questions That Influence Scoring (via Personalization Signals)

| Screen | Question | How It's Used |
|--------|----------|---------------|
| **Exercise** | Workout frequency | Evaluated by personalization signals — can boost or demote supplements based on activity level. |
| **Stress Level** | Self-reported stress | Evaluated by personalization signals — can boost adaptogens and calming supplements. |
| **Caffeine** | Daily coffee/tea/energy drink intake | Computed into caffeine level (high/moderate/low/none). Evaluated by signals. |
| **Alcohol** | Weekly drinks | Evaluated by personalization signals. |
| **Baseline Wellness** | Sleep/Energy/Clarity/Mood/Gut (0-10) | Bucketed into low/moderate/high. Evaluated by personalization signals — low baseline scores can boost relevant supplements. |

### Questions That Influence Dosage

| Screen | Question | How It's Used |
|--------|----------|---------------|
| **Sex** | Biological sex | Iron dosage: 27mg for women, 8mg for men. Also gates pregnancy screen visibility. Evaluated by personalization signals for other dosage adjustments. |
| **Weight** | Body weight | Weight > 200 lbs -> Vitamin D3+K2 bumped to 4,000 IU. |
| **Age** | Date of birth | Age > 65 -> 25% dose reduction for Rhodiola and CoQ10. Age bracket evaluated by personalization signals. |

### Questions That Influence Plan Copy & Summary

| Screen | Question | How It's Used |
|--------|----------|---------------|
| **Caffeine** | Daily intake | If any caffeine > 0: adds caffeine-specific notes to "What To Look For" text. Prioritizes L-Theanine + caffeine synergy messaging in AI summary. |
| **Stress Level** | Self-reported stress | If high/very high: adds stress-specific framing to "What To Look For" text. Prioritizes Ashwagandha messaging in AI summary. |
| **Exercise** | Workout frequency | If 3+/week: adds exercise recovery context to "What To Look For" text. Prioritizes Creatine/Protein messaging in AI summary. |
| **Baseline Wellness** | Baseline scores | Baseline sleep <= 4 -> Magnesium prioritized in AI summary. All scores stored for wellness tracking. |

### Questions That Currently Don't Influence the Plan

| Screen | Question | What It Collects | Why It's Not Used (Yet) |
|--------|----------|-----------------|------------------------|
| **Name** | First name | `firstName` | Personalization/UI only. Not fed into engine. |
| **HealthKit** | Connect Apple Health | `healthKitEnabled`, sleep/HR/HRV/steps data | Auto-fills sex if available (skips sex screen), but health metrics aren't used in recommendation logic yet. |
| **Height** | Height in inches/cm | `heightInches` | Stored but not used. No BMI-based logic exists. |
| **Notifications** | Reminder preferences | Reminder times/enabled | UX feature only. |
| **Account Creation** | Email/auth provider | Auth data | Authentication only. |
| **Welcome / Value Props** | (Informational screens) | Nothing | No data collected. |

---

## Deep Profile: How It Influences the Plan

The deep profile system consists of **9 optional modules** that users can complete after onboarding to provide deeper health data. Each module asks 7-10 targeted questions.

### Current State

Deep profile data feeds into the recommendation engine through **safety rules**, **force-adds**, and **contextual copy**:

**Safety rules (selection & warnings):**
- **Stress & Nervous System module:** If the user reports taking psychiatric medications (SSRIs, etc.), the SSRI safety rule triggers — preparing the engine to exclude serotonergic supplements when they're added to the catalog.
- **Lab Work & Biomarkers module:** If the user indicates diabetic status, the diabetic safety rule triggers — adding a warning to Berberine about blood sugar monitoring.

**Force-adds (selection):**
- **Hormonal & Metabolic module:** If the user reports taking hormonal birth control or HRT, Vitamin B Complex is force-added to the plan.
- **Gut Health module:** If the user reports current PPI usage, Vitamin B Complex is force-added to the plan.

**Fired signals (copy personalization):**
- **Sleep & Circadian module:** Sleep onset latency and night waking frequency drive personalized "Why It's In Your Plan" and "What To Look For" copy for Melatonin and Magnesium.
- **Hormonal & Metabolic module:** Birth control/HRT status drives personalized copy for B Complex and Magnesium.
- **Gut Health module:** PPI usage drives personalized copy for Magnesium, B Complex, and Iron.

Beyond these active connections, the remaining deep profile answers are stored but do not yet feed back into supplement selection or dosage logic.

### What Each Module Collects (and How It Could Further Influence the Plan)

#### 1. Sleep & Circadian
**Questions:** Bedtime, wake time, time to fall asleep, night waking frequency, sleep quality perception, shift work, restless legs, bedroom temperature, last caffeine timing, racing thoughts.

**Currently used:** Sleep onset latency (20-40min → moderate signal, 40-60min/60+ → strong signal) drives personalized copy for Melatonin. Night waking frequency (2+/night) drives personalized copy for Magnesium Glycinate.

**Potential further influence:** Could refine sleep supplement selection — e.g., racing thoughts -> L-Theanine; restless legs -> Iron/Magnesium. Shift workers might benefit from different timing recommendations.

#### 2. Stress & Nervous System
**Questions:** Physical stress symptoms (headaches, jaw clenching, tension, racing heart, shallow breathing), anxiety frequency, caffeine sensitivity, panic attacks, psychiatric medications (SSRIs, benzos, etc.), emotional resilience, chronic muscle tension, burnout level.

**Currently used:** Psychiatric medication responses trigger the SSRI safety rule.

**Potential further influence:** Could refine adaptogen selection — burnout -> Rhodiola over Ashwagandha; panic attacks + benzodiazepines -> avoid certain interactions; caffeine sensitivity -> stronger L-Theanine emphasis.

#### 3. Gut Health
**Questions:** Stool pattern, bloating frequency, food sensitivities (dairy, gluten, FODMAPs, histamine, soy), antibiotic history, post-meal symptoms, diagnosed conditions (IBS, IBD, GERD, celiac, SIBO), acid reflux, PPI usage, fiber intake, nausea.

**Currently used:** PPI usage response ("yes_currently") triggers force-add of Vitamin B Complex and drives personalized copy for Magnesium, B Complex, and Iron.

**Potential further influence:** Could drive probiotic strain specificity, Berberine adjustments for IBS/IBD, digestive enzyme additions. GERD could affect timing recommendations.

#### 4. Cognitive Function
**Questions:** Focus duration, brain fog frequency, memory changes, distractibility, ADHD diagnosis/suspicion, sleep hours, peak sharpness time, caffeine reliance for mental performance.

**Potential influence:** Could prioritize nootropics — ADHD -> specific Lion's Mane / Omega-3 emphasis; brain fog -> B Complex priority; peak sharpness timing -> adjust when to take focus supplements.

#### 5. Hormonal & Metabolic
**Questions:** Energy dip timing, cold sensitivity, blood sugar stability. **Female-only:** menstrual regularity, PMS severity, birth control/HRT. **Male 30+:** low testosterone signs. Both: libido level.

**Currently used:** Birth control/HRT response triggers force-add of Vitamin B Complex and drives personalized "Why It's In Your Plan" and "What To Look For" copy for B Complex and Magnesium.

**Potential further influence:** Blood sugar instability -> Berberine priority; PMS severity -> Magnesium dose increase; low testosterone signs -> Zinc emphasis; cold sensitivity (thyroid indicator) could affect Ashwagandha recommendation.

#### 6. Musculoskeletal Recovery
**Questions:** Exercise intensity, recovery quality, soreness patterns, joint health.

**Potential influence:** Could adjust Creatine/Protein/Omega-3/Collagen priority and dosage based on recovery needs and joint issues.

#### 7. Environment & Exposures
**Questions:** Toxin exposure, air quality, occupational hazards.

**Potential influence:** Could prioritize NAC and antioxidant support (Vitamin C, CoQ10) for users with high environmental exposure.

#### 8. Lab Work & Biomarkers
**Questions:** Recent lab results — vitamin D levels, iron/ferritin, blood sugar markers, etc.

**Currently used:** Diabetic status triggers the diabetic safety rule (Berberine warning).

**Potential further influence:** This is the highest-impact future module. Actual lab values could drive precise dosage adjustments — e.g., vitamin D at 20 ng/mL -> 4,000 IU; ferritin low -> iron inclusion regardless of goals; fasting glucose elevated -> Berberine emphasis.

#### 9. Skin, Hair & Nails
**Questions:** Skin conditions, hair loss/thinning, nail brittleness.

**Potential influence:** Could prioritize Collagen + Biotin + Zinc + Vitamin C combinations and adjust dosages based on symptom severity.

### Conditional Questions in Deep Profile

Some deep profile questions only appear based on the user's base profile:
- **Menstrual cycle, PMS, birth control** -> only shown to female users
- **Low testosterone signs** -> only shown to male users age 30+

---

## The 22 Supplements in the System

For reference, here's every supplement the engine can recommend, along with its category, evidence level, and recommended timing:

| Supplement | Category | Evidence | Default Dose | Timing |
|-----------|----------|----------|-------------|--------|
| Magnesium Glycinate | Mineral | Strong | 400mg | Evening |
| Vitamin D3 + K2 | Vitamin | Strong | 2,000 IU | Morning |
| Omega-3 (EPA/DHA) | Fatty Acid | Strong | 1,000mg | Morning (with food) |
| Ashwagandha KSM-66 | Adaptogen | Moderate | 600mg | Evening |
| L-Theanine | Amino Acid | Moderate | 200mg | Morning |
| Vitamin B Complex | Vitamin | Strong | 1x daily | Morning |
| Probiotics | Probiotic | Strong | 30B CFU | Empty Stomach |
| Zinc | Mineral | Moderate | 25mg | Evening |
| Vitamin C | Vitamin | Strong | 1,000mg | Morning |
| CoQ10 (Ubiquinol) | Coenzyme | Strong | 200mg | Morning |
| Creatine Monohydrate | Amino Acid | Strong | 5g | Morning |
| Collagen Peptides | Protein | Moderate | 10g | Morning |
| Lion's Mane | Mushroom | Emerging | 1,000mg | Morning |
| Rhodiola Rosea | Adaptogen | Moderate | 400mg | Morning |
| Melatonin | Hormone | Strong | 1mg | Bedtime |
| Biotin | Vitamin | Moderate | 5,000mcg | Morning |
| Iron | Mineral | Strong | 18mg | Empty Stomach |
| NAC | Amino Acid | Moderate | 600mg | Morning |
| Berberine | Plant Extract | Moderate | 500mg | With Food |
| Tart Cherry Extract | Fruit Extract | Emerging | 500mg | Evening |
| Whey Protein Isolate | Protein | Strong | 25g | Morning |
| Plant Protein Blend | Protein | Moderate | 25g | Morning |

---

## Key Gaps and Observations

1. **Goals still dominate selection, by design.** The goal overlap filter (Step 7) now explicitly requires supplements to have at least one goal connection to enter the plan organically. Personalization signals affect ranking within that set, and contextual force-adds (Step 9) handle the exceptions. This makes the plan more predictable and goal-anchored.

2. **Personalization signals are data-driven but depend on Supabase content.** The engine evaluates whatever signals exist in the database — the set of conditions, effects, and magnitudes is configurable without code changes. However, the quality and coverage of the signals determines how much personalization actually happens.

3. **Deep profile is increasingly connected.** SafetyRules read deep profile for SSRI and diabetic detection. Hormonal & Metabolic drives birth control/HRT force-adds. Gut Health drives PPI force-adds. Sleep & Circadian drives personalized copy. The remaining modules (Cognitive Function, Musculoskeletal Recovery, Environment & Exposures, Skin/Hair/Nails) are collected but don't yet influence the engine.

4. **Force-adds now cover three contexts.** Vegan/vegetarian diet, hormonal birth control/HRT, and PPI usage all trigger contextual force-adds with specific "Why It's In Your Plan" copy. This ensures nutrient-depletion scenarios are always addressed.

5. **Timing conflicts are now resolved.** Mineral pairs that compete for absorption (Iron/Zinc, Iron/Calcium, Zinc/Calcium, Magnesium/Iron) are automatically separated to different times of day with explanatory notes.

6. **Tier system has a quality floor.** The minimum quality guarantee (Step 12) ensures every plan has at least 2 Core or Targeted supplements, even for narrow goal selections.

7. **Diet logic is still limited to vegan/vegetarian for exclusions/force-adds.** Other diet types (keto, paleo, mediterranean, etc.) may be evaluated by personalization signals if configured in Supabase, but have no hardcoded logic.

8. **No feedback loop.** Daily wellness check-in scores (sleep, energy, clarity, mood, gut) are tracked but never used to adjust or rerank the plan over time.

9. **Height is still unused.** Stored but never referenced by the engine or personalization signals.
