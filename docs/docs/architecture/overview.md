# Architecture Overview

Estus is a SwiftUI iOS app with a deterministic, on-device recommendation engine. There is no backend AI call — every recommendation, score, and warning is computed locally from the user's profile against a knowledge base that is either fetched from Supabase or fall-back hardcoded.

## High-level data flow

```
┌──────────────────┐
│ Onboarding flow  │  collects 27 screens worth of user input
└────────┬─────────┘
         │ buildUserProfile()
         ▼
┌──────────────────┐    ┌──────────────────────────┐
│   UserProfile    │    │    SupplementCatalog      │ ◄── populated from
│ (goals, meds,    │    │ (supplements, goal map,   │     Supabase OR
│  diet, baselines)│    │  synergies, signals,      │     SupplementKnowledgeBase
└────────┬─────────┘    │  exclusion groups, etc.)  │     (static fallback)
         │              └────────────┬─────────────┘
         │                           │
         │                           ▼
         │              ┌──────────────────────────┐
         │              │   RecommendationEngine    │
         └─────────────►│  generatePlan(profile)    │
                        └────────────┬─────────────┘
                                     │ uses ► PersonalizationScorer
                                     │       ► SafetyRules
                                     │       ► SupplementNameMatcher
                                     │       ► drug interactions
                                     ▼
                        ┌──────────────────────────┐
                        │     SupplementPlan        │
                        │  (tiered PlanSupplements  │
                        │   with enriched copy)     │
                        └────────────┬─────────────┘
                                     │
                  ┌──────────────────┼──────────────────┐
                  ▼                  ▼                  ▼
        ┌─────────────────┐ ┌────────────────┐ ┌──────────────────┐
        │  AppState       │ │ DailyCheckIn   │ │   Insights       │
        │  (@Observable,  │ │ (5 wellness    │ │   (computed by   │
        │  global)        │ │  dims + supp   │ │    InsightsVM    │
        │                 │ │  logs)         │ │    + check-in    │
        │                 │ │                │ │    insight gen)  │
        └────────┬────────┘ └────────┬───────┘ └────────┬─────────┘
                 │                   │                   │
                 └──────────►┌──────────────────┐◄──────┘
                             │ LocalStorage     │
                             │ Service          │
                             │ (UserDefaults)   │
                             └──────────────────┘
```

## Layers

| Layer | What lives here | Notes |
|---|---|---|
| **App** | [`AppState`](state-management.md), `EstusApp`, `ContentView` | Root @Observable, owns catalog/medications/plan/check-ins. |
| **Models** | `UserProfile`, `SupplementPlan`, `DailyCheckIn`, `Insight`, `WellbeingScore` | All `Codable`. See [Data Models](data-models.md). |
| **Services** | `DataStore` (protocol), `LocalStorageService`, `SupplementCatalog`, `SupplementService`, `KnowledgeBaseMapper`, `AuthService`, `HealthKitService`, `NotificationService` | Persistence + I/O abstractions. `DataStore` is the swap-point for Supabase. |
| **Utilities** | `RecommendationEngine`, `PersonalizationScorer`, `SafetyRules`, `SupplementNameMatcher`, `CheckInInsightGenerator`, `SupplementKnowledgeBase`, `MedicationKnowledgeBase` | Pure deterministic logic. No I/O, no UI. |
| **Features** | `Onboarding/`, `Today/` (daily check-in), `Plan/`, `Insights/`, `DeepProfile/`, `Settings/` | One folder per major surface. Each has a `Screen` + `ViewModel`. |
| **Design** | `DesignTokens`, components, modifiers, Metal shaders | Brand system. Not in scope for the wiki. |

## Architectural rules (from `CLAUDE.md`)

- **State management:** Swift Observation (`@Observable`, `@Environment(AppState.self)`). Never `ObservableObject` / `@Published` / `@StateObject`.
- **Light mode only.** All UI assumes warm-white backgrounds.
- **Deterministic recommendations.** `RecommendationEngine` makes no API calls; it operates on the catalog + the user's profile + medication interactions.
- **`DataStore` abstracts persistence.** Currently `LocalStorageService` (UserDefaults). Will swap to Supabase in M3+; the abstraction means flow code shouldn't change.
- **`xcodegen generate` after adding/removing/renaming any Swift file** — the `project.pbxproj` is generated, never hand-edited.

## How a recommendation is born

1. **Onboarding** collects a `UserProfile`.
2. **AppState** has already loaded `SupplementCatalog` (from Supabase or static fallback) and `medications` / `drugInteractions`.
3. `OnboardingFlow.onInterstitialComplete` builds a `RecommendationEngine` over `(catalog, drugInteractions, medications, deepProfileModules)` and calls `engine.generatePlan(for: profile)`.
4. The plan is shown to the user in the Plan Reveal screen, where they can toggle inclusion. On completion, the included subset is saved via `LocalStorageService.savePlan`.
5. Subsequent app launches read profile + plan back from `UserDefaults` in `AppState.restoreSessionIfNeeded()`.

For the full pipeline inside `generatePlan`, see [Recommendation Engine](../engines/recommendation-engine.md).
