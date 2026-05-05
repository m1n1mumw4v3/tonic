# Onboarding Fields → Plan

This page is a plain-English walkthrough of every question we ask during onboarding and exactly how (or whether) the answer ends up shaping the supplement plan.

Each entry follows the same shape:

- **What we ask**
- **How it shapes the plan** — the actual mechanism, in plain language
- **The literal numbers/names** when there's branching or a threshold
- **Source** — file and roughly where the logic lives

If a field is captured but never read by the recommendation pipeline, it's marked **Not used in plan**.

---

## How the plan is built (one-paragraph context)

Goals fan out into a list of candidate supplements, each candidate gets a score from goal weights plus personalization "signals" plus safety boosts, then candidates are filtered by allergies, medications, pregnancy, and a few diet/sex guardrails. After filtering, the engine picks the top scorers (capped at 7), force-adds a handful of supplements when certain conditions fire (e.g., vegan → B Complex), and adjusts dosages by age, sex, and weight. So when a field "matters," it does so by either **adding score**, **excluding a supplement**, **forcing a supplement in**, or **changing a dosage**.

---

## 1. First name

- **What we ask:** Your first name.
- **How it shapes the plan:** **Not used in plan.** Display only — we use it in greetings and copy.
- **Source:** `NameScreen.swift`; stored on `UserProfile.firstName` and never read by `RecommendationEngine`.

## 2. Date of birth (used as age)

- **What we ask:** Your date of birth. We convert this to a whole-number age.
- **How it shapes the plan:** Three distinct effects.
    1. **Age 50 and over** fires a personalization signal that adds a boost (and a "why this is in your plan" sentence) for **CoQ10** and **Collagen Peptides**, so they're more likely to land in the final plan and get a more relevant blurb.
    2. **Age over 65** trims the dose of **Rhodiola Rosea** and **CoQ10** to **75%** of the standard amount.
    3. **For females, age 18–50** adds **+1** to the score for **Iron** (combined with other female-iron rules below).
- **Source:** `AgeScreen.swift`; logic in `RecommendationEngine.swift` (legacy dose rules around line 1071, fired-signal collection around line 645) and `SafetyRules.swift` lines 214–215.

## 3. Sex (biological)

- **What we ask:** Male, Female, Intersex, or Prefer Not to Say.
- **How it shapes the plan:**
    - **Female** is the trigger for several iron-related rules (see Iron in age, diet, and exercise sections). The recommended **Iron dose** is set to **27 mg** for females.
    - **Male** is set to **8 mg** for Iron *if* iron makes it into the plan, but males are also screened out of iron entirely by a guardrail rule unless they have one of three exemptions: vegan/vegetarian diet, exercising 5+ times a week, or a confirmed low-ferritin lab in the deep profile.
    - **Sex other than Male** unlocks the pregnancy/breastfeeding/HRT screen. Males skip it entirely.
- **Source:** `SexScreen.swift`; `RecommendationEngine.swift` lines 1078–1082; `SafetyRules.swift` lines 132–160 (male iron guardrail) and 207–217 (female iron boosts).

## 4. Pregnancy / trying to conceive

- **What we ask:** Yes/no toggle (only shown if sex is not Male).
- **How it shapes the plan:** If **yes**, we **exclude Ashwagandha KSM-66** and **Berberine** from the plan entirely.
- **Source:** `PregnancyScreen.swift`; `RecommendationEngine.swift` lines 982–986.

## 5. Currently breastfeeding

- **What we ask:** Yes/no toggle (only shown if sex is not Male).
- **How it shapes the plan:** Same as pregnancy — **excludes Ashwagandha KSM-66** and **Berberine**.
- **Source:** `PregnancyScreen.swift`; `RecommendationEngine.swift` lines 982–986.

## 6. Perimenopause / menopause

- **What we ask:** Yes/no toggle (only shown if sex is not Male).
- **How it shapes the plan:** **Captured but currently has no direct effect** on the deterministic recommendation pipeline. It's stored on the profile and is intended to drive Supabase-loaded personalization signals once those are configured for this condition.
- **Source:** `PregnancyScreen.swift`; field stored as `UserProfile.isPerimenopausal`.

## 7. On hormonal birth control / on HRT

- **What we ask:** Two yes/no toggles (only shown if sex is not Male).
- **How it shapes the plan:** When confirmed (today this is primarily set via the Hormonal & Metabolic deep profile module — the onboarding toggles are currently captured for context but the pipeline reads from deep profile responses):
    - **Force-adds Vitamin B Complex** to the plan if it isn't already there.
    - **Boosts the score** of Magnesium Glycinate by **+2**, Vitamin B Complex by **+2**, Zinc by **+1**, and CoQ10 by **+1** so they're far more likely to make the cut.
    - Replaces the generic "why is this in your plan" copy with hormone-specific copy ("Hormonal birth control can deplete B6, B12, and folate…", etc.).
- **Source:** `PregnancyScreen.swift` (capture); logic in `RecommendationEngine.swift` lines 129–134 and `SafetyRules.swift` lines 175–183; copy templates in `RecommendationEngine.swift` lines 363–371.

## 8. Height

- **What we ask:** Feet/inches or centimeters.
- **How it shapes the plan:** **Not used in plan.** Stored only.
- **Source:** `HeightScreen.swift`; field is `UserProfile.heightInches` and is never read by the engine.

## 9. Weight

- **What we ask:** Pounds or kilograms.
- **How it shapes the plan:** One rule. **Above 200 lb**, the **Vitamin D3 + K2 dose is bumped to 4000 IU** (from the standard 2000 IU). Used nowhere else.
- **Source:** `WeightScreen.swift`; `RecommendationEngine.swift` lines 1085–1089.

## 10. Health goals (pick up to 4)

This is the single biggest driver of which supplements you see.

- **What we ask:** Up to four from: Energy, Sleep, Stress & Anxiety, Mental Clarity & Focus, Gut Health, Immune Support, Muscle Recovery, Skin/Hair/Nails, Heart Health, Longevity.
- **How it shapes the plan:**
    - Each goal maps to a list of supplements, each with an **evidence weight** (curated in the Knowledge Base Mapper / Supplement Catalog). For every goal you pick, every supplement that addresses that goal gets that weight added to its score.
    - A supplement that scores **zero across your goals** is filtered out before final selection — it can only re-enter the plan via a force-add (vegan, birth control, PPI, etc.).
    - The two highest-tier supplements that match your goals become the "core" of your plan summary copy ("Your plan is built around X and Y as your foundation for energy and stress management.")
    - Goals also drive the per-supplement "why is this in your plan" sentence — we lead with the goal that has the strongest evidence link to that supplement.
- **Source:** `GoalsScreen.swift`; `RecommendationEngine.swift` lines 33–43, 110–112, 162–168, 1163–1175.

## 11. Supplements you're already taking

- **What we ask:** Multi-select from the catalog plus a free-text "other" field.
- **How it shapes the plan:**
    - **Anything you already take is removed from the candidate list** so we don't double-recommend it. Matching is fuzzy: exact name, common name, and brand variants all count.
    - If the match is a **form variant** (e.g., you take magnesium oxide, we'd recommend magnesium glycinate), we keep our recommendation but flag it as a potential upgrade.
    - If you're taking a **multivitamin** *and* iron is in your plan, we add a note warning to check the multivitamin's iron content to avoid stacking.
- **Source:** `CurrentSuppsScreen.swift`; `RecommendationEngine.swift` lines 62–76 (dedup) and 242–252 (multivitamin overlap).

## 12. Current medications

This is the **safety-critical** input. Five medication classes change the plan.

- **What we ask:** Multi-select from a Supabase-backed medication picker plus a free-text custom list.
- **How it shapes the plan:**
    - **Drug-interaction filter:** We collect interaction "keys" from your medications (e.g., `ssri`, `ppi`, `diabetes_med`) and check every candidate supplement against the curated interaction table. Each supplement comes back as **excluded** (removed from plan), **kept with a warning** (shown in the plan UI), or **clear**.
    - **SSRIs** (Zoloft, Lexapro, Prozac, Celexa, Paxil, Effexor, Cymbalta, trazodone, and their generics): the SSRI rule fires. The intent is to exclude serotonergic supplements like 5-HTP and St. John's Wort, though as of today those aren't in the catalog yet — so the rule currently mostly serves as scaffolding. If you do add 5-HTP via the manual sheet, the SSRI signal is the gate.
    - **Diabetes meds** (metformin, insulin, Ozempic, Mounjaro, Jardiance, Januvia, etc.): adds a **warning to Berberine** because both lower blood sugar.
    - **PPIs** (omeprazole/Prilosec, Nexium, pantoprazole, lansoprazole, etc.): big deal. **Force-adds Vitamin B Complex.** **Boosts** Magnesium Glycinate (+2), Vitamin B Complex (+2), and Iron (+1). Replaces the generic "why" copy with PPI-specific copy.
    - **Custom typed medications** are matched against the same name lists, so typing "omeprazole" works the same as picking it from the list.
- **Source:** `MedicationsScreen.swift`; `RecommendationEngine.swift` lines 79–86 (interaction filter), 137–143 (PPI force-add); `SafetyRules.swift` lines 27–127.

## 13. Allergies

- **What we ask:** Multi-select from Shellfish, Soy, Gluten, Dairy, Tree Nuts, Fish, Eggs, Peanuts, plus a free-text "other".
- **How it shapes the plan:**
    - **Fish or shellfish** → **excludes Omega-3 (EPA/DHA)**.
    - **Dairy / milk / lactose** → **excludes Whey Protein Isolate**.
    - Other allergies are stored but don't currently exclude anything in the catalog (no peanut/soy-derived supplements in the active catalog).
- **Source:** `AllergiesScreen.swift`; `RecommendationEngine.swift` lines 968–975.

## 14. Diet type

- **What we ask:** Omnivore, Vegetarian, Vegan, Keto, Paleo, Pescatarian, Halal, Mediterranean, Low-Carb, Other.
- **How it shapes the plan:**
    - **Vegan or Vegetarian:**
        - **Force-adds Vitamin B Complex and Vitamin D3 + K2** if not already excluded.
        - **Excludes Whey Protein Isolate** (Plant Protein Blend takes its place if protein matters for the goals).
        - **Iron** gets a **+2 score boost for females** and exempts males from the iron guardrail.
        - Replaces "why" copy for B Complex / D3 / Iron with vegan-specific phrasing.
    - **Keto, Paleo, Pescatarian, Halal, Mediterranean, Low-Carb, Other:** stored but currently no hardcoded effect on the plan.
- **Source:** `DietScreen.swift`; `RecommendationEngine.swift` lines 124–127, 414–416, 977–980; `SafetyRules.swift` lines 138–140 and 207–209.

## 15. Exercise frequency

- **What we ask:** None / 1–2× / 3–4× / 5+× per week.
- **How it shapes the plan:**
    - **5+ per week:** for males, exempts them from the iron guardrail (so iron can come in if goals justify it). For females, adds **+1 to Iron's score**.
    - **3–4× or 5+ per week** counts as "active" — if Creatine, Whey Protein, or Plant Protein land in the plan, we swap the lifestyle sentence in the plan summary to a recovery-flavored line ("With your active exercise routine, Creatine will support your recovery…").
- **Source:** `ExerciseScreen.swift`; `RecommendationEngine.swift` lines 1182, 1199–1213; `SafetyRules.swift` lines 142, 211–212.

## 16. Daily caffeine (coffee, tea, energy drinks, soda)

- **What we ask:** Four separate counters — cups of coffee, cups of tea, energy drinks, sodas.
- **How it shapes the plan:**
    - If **any** of coffee/tea/energy drinks is greater than 0 **and** L-Theanine is in the plan, we use the caffeine-specific lifestyle sentence ("Since you drink coffee daily, we've included L-Theanine to smooth out the energy and keep your focus steady.")
    - The same flag inserts ", especially if you pair it with your morning caffeine" into "what to look for" copy when relevant.
    - The counts themselves don't currently move scores or doses — they're consumed as a single boolean for copy. (Soda count is captured but not part of the caffeine boolean.)
- **Source:** `CaffeineScreen.swift`; `RecommendationEngine.swift` lines 1180, 1187–1189, 676–679.

## 17. Weekly alcohol

- **What we ask:** None / 1–3 / 4–7 / 8+ drinks per week.
- **How it shapes the plan:**
    - Only the **8+ bracket** ("heavy alcohol") fires a real plan effect. When it fires, supplements that depletion-research links to alcohol get the heavy-alcohol "why" copy *if they're already candidates*: **Vitamin B Complex**, **NAC**, **Magnesium Glycinate**, **Zinc**.
    - 1–3 and 4–7 are stored but don't currently change the plan.
- **Source:** `AlcoholScreen.swift`; `RecommendationEngine.swift` lines 587, 599–603, 382–387.

## 18. Stress level

- **What we ask:** None / Low / Moderate / High / Very High.
- **How it shapes the plan:**
    - **High or Very High** fires the high-stress signal. If **Ashwagandha KSM-66**, **L-Theanine**, or **Magnesium Glycinate** are candidates, they get stress-specific "why" copy.
    - If Ashwagandha is in the plan and stress is High/Very High, the lifestyle sentence in the plan summary becomes the Ashwagandha line ("With your stress running high, Ashwagandha is here to help take the edge off…").
    - None / Low / Moderate are stored but don't currently move scores.
- **Source:** `StressScreen.swift`; `RecommendationEngine.swift` lines 588, 663–667, 377–381, 1193–1195.

## 19. Baseline sleep (0–10 slider)

- **What we ask:** "How is your sleep quality right now?" — slider 0–10.
- **How it shapes the plan:**
    - **4 or below** is "low sleep baseline." If **Magnesium Glycinate** or **Melatonin** are candidates, they get low-sleep-specific "why" copy.
    - If Magnesium Glycinate is in the plan and baseline sleep is ≤ 4, the plan summary's lifestyle sentence becomes the magnesium-and-sleep line.
    - Higher numbers don't currently move scores.
- **Source:** `BaselineScreen.swift`; `RecommendationEngine.swift` lines 589, 651–655, 397–399, 1184, 1222–1226.

## 20. Baseline energy (0–10 slider)

- **What we ask:** "How's your daily energy?" — slider 0–10.
- **How it shapes the plan:**
    - **4 or below** is "low energy baseline." If **Vitamin B Complex** or **CoQ10** are candidates, they get low-energy-specific "why" copy.
    - Higher numbers don't currently move scores.
- **Source:** `BaselineScreen.swift`; `RecommendationEngine.swift` lines 590, 657–661, 401–403.

## 21. Baseline mental clarity / mood / gut (three more 0–10 sliders)

- **What we ask:** Three more sliders on the same baseline screen.
- **How it shapes the plan:** **Captured but no hardcoded effect today.** They're bucketed into low/moderate/high so Supabase-loaded personalization signals can target them, but no signal is currently configured against them. Adding such a signal would let them tune scores or doses without a code change.
- **Source:** `BaselineScreen.swift`; `PersonalizationScorer.swift` lines 84–91, 116–122.

## 22. Apple Health integration

- **What we ask:** Toggle to authorize HealthKit and pull metrics like sleep and heart rate.
- **How it shapes the plan:** **Not used in plan today.** The toggle and the resulting `HealthMetrics` payload are stored but no recommendation rule reads them.
- **Source:** `HealthKitScreen.swift`.

## 23. Morning / evening reminder times

- **What we ask:** Two toggles + time pickers for daily reminders.
- **How it shapes the plan:** **Not used in plan.** They're for local notifications only.
- **Source:** `NotificationReminderScreen.swift`.

---

## Quick-reference table

| Field | Affects plan? | Mechanism in one line |
|---|---|---|
| First name | No | Display only. |
| Age | Yes | Dose cuts >65 (CoQ10, Rhodiola); CoQ10 + Collagen boost ≥50; female iron boost 18–50. |
| Sex | Yes | Iron dose; pregnancy screen gating; female iron boosts; male iron guardrail. |
| Pregnant / trying | Yes | Excludes Ashwagandha + Berberine. |
| Breastfeeding | Yes | Excludes Ashwagandha + Berberine. |
| Perimenopause | No (today) | Stored for future signals. |
| Birth control / HRT | Yes | Force-adds B Complex; boosts B Complex, Magnesium, Zinc, CoQ10. |
| Height | No | Stored only. |
| Weight | Partially | >200 lb bumps Vitamin D3 to 4000 IU. |
| Health goals | **Yes — primary** | Drive every candidate score; supplements with zero goal overlap are dropped. |
| Current supplements | Yes | Dedup; form-variant flags; multivitamin/iron warning. |
| Medications | **Yes — safety** | Drug interactions; PPI force-add + boosts; SSRI/diabetes warnings. |
| Allergies | Yes | Fish/shellfish → no Omega-3; dairy → no Whey. |
| Diet type | Yes | Vegan/vegetarian: force-add B Complex + D3, drop Whey, boost Iron, copy. |
| Exercise frequency | Yes | 5+× boosts iron / exempts males; 3+× swaps copy for protein/creatine. |
| Caffeine (coffee/tea/energy) | Yes (copy) | Triggers L-Theanine line in summary; modifies "what to look for". |
| Caffeine (soda) | No | Stored only. |
| Alcohol | Yes (only 8+) | Heavy-alcohol "why" copy for B Complex, NAC, Magnesium, Zinc. |
| Stress | Yes (only High/Very High) | High-stress "why" + Ashwagandha summary line. |
| Baseline sleep (≤4) | Yes | Low-sleep "why" + magnesium summary line. |
| Baseline energy (≤4) | Yes | Low-energy "why" for B Complex / CoQ10. |
| Baseline clarity / mood / gut | No (today) | Bucketed but no signal wired up. |
| HealthKit toggle | No | Stored only. |
| Reminder times | No | Notifications only. |

---

## Things to keep in mind

- **"Boost" doesn't guarantee inclusion.** It just makes a supplement more competitive in the top-7 selection. A supplement still needs goal overlap (or a force-add rule) to land in the plan.
- **"Force-add" only fires after the top-7 selection.** B Complex via vegan/PPI/birth-control gets stitched in even if it didn't win on score.
- **Hardcoded thresholds are intentionally few.** Most of the future personalization is meant to flow through Supabase-loaded `personalization_signals`, so adding a new trigger doesn't require shipping code. The fields marked "stored but no hardcoded effect" are the ones waiting for a signal to be configured.
- **Deep Profile vs. onboarding for hormonal/PPI/sleep/labs.** Onboarding captures the surface-level toggles, but several boost rules read the more detailed answer from the corresponding Deep Profile module if it's filled in. The two paths converge at the same boost map.
