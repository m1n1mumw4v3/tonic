# Ample (module: Tonic)

## Overview
iOS app that generates personalized supplement plans based on health goals and lifestyle, then tracks daily wellness across five dimensions (sleep, energy, clarity, mood, gut) to optimize recommendations over time. Subscription-based with RevenueCat. User-facing name is "Ample"; internal Swift module remains "Tonic."

## Tech Stack
- Swift 5.9 / SwiftUI, iOS 17+ deployment target
- XcodeGen (`project.yml` → Xcode project)
- Supabase (auth, Postgres, edge functions)
- RevenueCat (subscriptions), PostHog (analytics)
- Geist font family (custom, bundled in `Resources/Fonts/`)
- Metal shaders (`Design/Shaders/`)

## Project Structure
- `Tonic/App/` — Entry point, `AppState` (global `@Observable`), `ContentView` (onboarding vs main tabs)
- `Tonic/Design/` — `DesignTokens.swift` (colors, typography, spacing, radii), reusable `Components/`, `Modifiers/`, `Shaders/`
- `Tonic/Features/` — Feature modules: `Onboarding/`, `Home/`, `Plan/`, `DailyCheckIn/`, `Insights/`
- `Tonic/Models/` — Data models: `UserProfile`, `SupplementPlan`, `DailyCheckIn`, `WellbeingScore`, `Insight`
- `Tonic/Services/` — `DataStore` protocol, `LocalStorageService` (swappable for Supabase later)
- `Tonic/Utilities/` — `RecommendationEngine`, `SupplementKnowledgeBase`, `MedicationKnowledgeBase`
- `Tonic/Resources/` — Assets, fonts
- `TonicTests/` — Unit tests
- `tonic-v1-spec.md` — Full product spec (single source of truth for features and requirements)

## Commands
- Regenerate Xcode project: `xcodegen generate`
- Build: `xcodebuild -project Tonic.xcodeproj -scheme Tonic -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- Test: `xcodebuild -project Tonic.xcodeproj -scheme TonicTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test`

## Architecture Decisions
- ALWAYS use `DesignTokens` for colors, fonts, spacing, and radii. NEVER use raw Color literals, system fonts, or magic numbers for layout.
- State management uses Swift Observation framework (`@Observable`, `@Environment`). NEVER use `ObservableObject`/`@Published`/`@StateObject`.
- Light-mode only (`.preferredColorScheme(.light)` set at root). All UI assumes warm white backgrounds (Ample brand system).
- Brand palette: warm white backgrounds (`#FAF8F3`, `#F2EFE8`, `#EBE7DF`), olive text (`#1C1E17`, `#6B6E63`, `#A3A69B`), biological accent colors (Deep Purple, Pale Gold, Ocean Blue, Golden Membrane, Acid Chartreuse, Bright Teal, Magenta, Moss, Warm Red, Deep Teal, Terracotta).
- Feature modules follow the pattern: `Screen` (SwiftUI view) + `ViewModel` (`@Observable` class) where state is non-trivial.
- `RecommendationEngine` is deterministic and local — no API calls. It uses `SupplementKnowledgeBase` for supplement data and `goalSupplementMap` for goal-to-supplement mapping.
- `DataStore` protocol abstracts persistence. Currently backed by `LocalStorageService`; will swap to Supabase in a future milestone.
- Onboarding is a linear flow managed by screen index in `OnboardingFlow.swift`. New screens must be added to the `switch` statement and `totalScreens` must be updated.

## Key Warnings
- CRITICAL: After adding/removing/renaming any Swift file, you MUST run `xcodegen generate` to regenerate the Xcode project. The `project.pbxproj` is generated from `project.yml` — never edit it by hand.
- NEVER commit API keys, Supabase URLs, or RevenueCat keys. These are not yet configured and will use environment-based config.
- The product spec at `tonic-v1-spec.md` is the authoritative reference for feature requirements, data models, and UX flows. Consult it before implementing new features.
- Pale Gold (`#E8C94A`) has low contrast on warm white — never use for small text, only fills/icons.
- User-facing name is "Ample" — internal Swift module stays "Tonic."
