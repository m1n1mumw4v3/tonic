# Onboarding Flow

A 27-screen sequence that collects the user's profile, generates their first plan, and persists everything before showing the main tab UI. Two screens are conditionally skipped (`HealthKit` may auto-fill sex; pregnancy is skipped for males).

**Sources:** `Estus/Features/Onboarding/OnboardingFlow.swift`, `Estus/Features/Onboarding/OnboardingViewModel.swift`, `Estus/Features/Onboarding/Screens/*`

## Screen sequence

| Idx | Screen | Skip when |
|---|---|---|
| 0 | `WelcomeScreen` | — |
| 1 | `ValuePropProblemScreen` | — |
| 2 | `ValuePropComplexityScreen` | — |
| 3 | `ValuePropSolutionScreen` | — |
| 4 | `NameScreen` | — |
| 5 | `HealthKitScreen` | — |
| 6 | `AgeScreen` | — |
| 7 | `SexScreen` | `viewModel.healthKitProvidedSex` |
| 8 | `PregnancyScreen` | `viewModel.sex == .male` |
| 9 | `HeightScreen` | — |
| 10 | `WeightScreen` | — |
| 11 | `GoalsScreen` (max 4) | — |
| 12 | `CurrentSuppsScreen` | — |
| 13 | `MedicationsScreen` | — |
| 14 | `AllergiesScreen` | — |
| 15 | `DietScreen` | — |
| 16 | `ExerciseScreen` | — |
| 17 | `CaffeineScreen` | — |
| 18 | `AlcoholScreen` | — |
| 19 | `StressScreen` | — |
| 20 | `BaselineScreen` (5 sliders 0–10) | — |
| 21 | `NotificationReminderScreen` | — |
| 22 | `MedicalDisclaimerScreen` | — |
| 23 | `AIInterstitialScreen` | — |
| 24 | `PaywallScreen` | — |
| 25 | `PlanRevealScreen` | — |
| 26 | `AccountCreationScreen` | — |

The progress bar (`SpectrumBar`) hides on screens 0, 23–26, computing progress against the *active* screen list (post-skip).

## State container — `OnboardingViewModel`

`@Observable` class holding all answers as properties. Core sections:

- **Identity:** `firstName`, `dateOfBirth`, `age` (computed), `sex`, `isPregnant`, `isBreastfeeding`, `isPerimenopausal`, hormonal flags.
- **Body:** `heightFeet/heightInches/heightCm`, `weightLbs/weightKg`.
- **Goals:** `healthGoals: Set<HealthGoal>` (max 4 enforced in UI).
- **Existing supplements / meds / allergies:** Set<String> + `customMedicationsText` for free-form entries, plus `selectedMedicationIds: Set<UUID>` for picks from the Supabase medications table.
- **Lifestyle:** `dietType`, custom diet text, `exerciseFrequency`, caffeine cup counts, `alcoholWeekly`, `stressLevel`.
- **Baselines (0–10):** `baselineSleep/Energy/Clarity/Mood/Gut`.
- **HealthKit:** `healthKitEnabled`, `healthMetrics`, `healthKitProvidedSex` (drives screen 7 skip).
- **Notifications:** morning/evening reminder enabled + times.
- **Account:** `accountCreated`, `accountEmail`, `accountProvider`.
- **Generated state (set during the flow):** `generatedPlan: SupplementPlan?` (set at screen 23, read at screen 25).

`buildUserProfile()` assembles all of the above into a typed `UserProfile` struct.

## Plan generation point — screen 23

`AIInterstitialScreen` shows a loading state. When the user dismisses the interstitial:

```swift
private func onInterstitialComplete() {
    let profile = viewModel.buildUserProfile()
    let engine = makeEngine()
    let plan = engine.generatePlan(for: profile)
    viewModel.generatedPlan = plan
    nextScreen()
}

private func makeEngine() -> RecommendationEngine {
    RecommendationEngine(
        catalog: appState.supplementCatalog,
        drugInteractions: appState.drugInteractions,
        medications: appState.medications,
        deepProfileModules: Array(appState.deepProfileService.completedModules.values)
    )
}
```

So the engine runs **synchronously on the main thread** between screens 23 and 24. The catalog and medications are already loaded by `AppState.loadSupplementCatalog()` / `loadMedications()` during the splash. Deep profile modules at this point are typically empty during onboarding — they're collected later via the `DeepProfile` feature.

## Plan reveal — screen 25

`PlanRevealScreen` reads `viewModel.generatedPlan` and shows each `PlanSupplement` with a toggle (`isIncluded`). The user can disable any supplement before confirming.

Expanding a card reveals an inline `DosageRangeEditor` (when the supplement has a numeric `dosageMg` and `SupplementCatalog.doseRange(for:)` returns a low/high). The editor lets the user fine-tune the dose with a stepper or draggable thumb on a horizontal range bar; a status pill shows in/below/above-range, and a reset link clears the override. Edits write `userOverriddenDosageMg` directly on `viewModel.generatedPlan.supplements`, so any override the user sets during reveal is carried into `appState.activePlan` and persisted at completion.

## Completion paths

There are two paths that finalize onboarding — one through the paywall, one bypassing it. Both perform the same persistence steps.

### `dismissPaywall()` (skip subscription)

Triggered when the user dismisses the paywall on screen 24.

1. Build `UserProfile`, attach `userId` from `authService.supabaseUserId` if present.
2. Set `appState.currentUser = profile`.
3. If `viewModel.generatedPlan` exists, filter `supplements` to those with `isIncluded = true` (toggles from screen 25 don't apply yet because reveal hasn't been shown — but the included flag defaults to true so all are kept). Set `appState.activePlan`.
4. If somehow the plan is missing, regenerate fresh.
5. **Persist** profile and plan via `LocalStorageService`.
6. `NotificationService.scheduleNotifications(for: profile)`.
7. `appState.isOnboardingComplete = true`. (User keeps `isSubscribed = false`.)

### `completeOnboarding()` (post-paywall, post-reveal)

Triggered after `AccountCreationScreen` on screen 26. Same logic as `dismissPaywall()`, but the user has now passed through the reveal screen so `isIncluded` toggles meaningfully filter the plan.

## Why both paths

- The paywall is "soft" — the user can dismiss it and still get the app, just without subscription perks.
- Both paths save the same profile + plan so the next launch can restore correctly. The only difference is `isSubscribed` and whether the user saw the reveal.

## Persistence

Both completion paths write to `UserDefaults` keys `estus_user_profile` and `estus_active_plan` via `LocalStorageService`. On next launch, `AppState.restoreSessionIfNeeded()` reads these and auto-flips `isOnboardingComplete = true`.

## Adding a new screen

1. Bump `totalScreens` in `OnboardingFlow.swift`.
2. Insert a new `case N:` in the body switch.
3. Add the corresponding state property to `OnboardingViewModel`.
4. Update `buildUserProfile()` to consume the new state.
5. If the screen should be conditionally skipped, update `skippedScreens`.
6. If the new field affects scoring, add a `profileValue` case in [`PersonalizationScorer`](../engines/personalization-scorer.md), and any related signal (static or DB).
7. `xcodegen generate` after adding the screen file.

## Cross-references

- [State Management](../architecture/state-management.md) — what `AppState` owns at the moment of plan generation.
- [Recommendation Engine](../engines/recommendation-engine.md) — what runs on screen 23.
- [Persistence](../architecture/persistence.md) — what gets saved.
- [Data Models](../architecture/data-models.md) — the `UserProfile` shape that `buildUserProfile()` produces.
