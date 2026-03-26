# Estus

## Overview
iOS app that generates personalized supplement plans based on health goals and lifestyle, then tracks daily wellness across five dimensions (sleep, energy, clarity, mood, gut) to optimize recommendations over time. Subscription-based with RevenueCat.

## Tech Stack
- Swift 5.9 / SwiftUI, iOS 17+ deployment target
- XcodeGen (`project.yml` → Xcode project)
- Supabase (auth, Postgres, edge functions)
- RevenueCat (subscriptions), PostHog (analytics)
- Geist font family (custom, bundled in `Resources/Fonts/`)
- Metal shaders (`Design/Shaders/`)

## Project Structure
- `Estus/App/` — Entry point, `AppState` (global `@Observable`), `ContentView` (onboarding vs main tabs)
- `Estus/Design/` — `DesignTokens.swift` (colors, typography, spacing, radii), reusable `Components/`, `Modifiers/`, `Shaders/`
- `Estus/Features/` — Feature modules: `Onboarding/`, `Home/`, `Plan/`, `DailyCheckIn/`, `Insights/`
- `Estus/Models/` — Data models: `UserProfile`, `SupplementPlan`, `DailyCheckIn`, `WellbeingScore`, `Insight`
- `Estus/Services/` — `DataStore` protocol, `LocalStorageService` (swappable for Supabase later)
- `Estus/Utilities/` — `RecommendationEngine`, `SupplementKnowledgeBase`, `MedicationKnowledgeBase`
- `Estus/Resources/` — Assets, fonts
- `EstusTests/` — Unit tests

## Commands
- Regenerate Xcode project: `xcodegen generate`
- Build: `xcodebuild -project Estus.xcodeproj -scheme Estus -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build`
- Test: `xcodebuild -project Estus.xcodeproj -scheme EstusTests -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test`

## Architecture Decisions
- ALWAYS use `DesignTokens` for colors, fonts, spacing, and radii. NEVER use raw Color literals, system fonts, or magic numbers for layout.
- State management uses Swift Observation framework (`@Observable`, `@Environment`). NEVER use `ObservableObject`/`@Published`/`@StateObject`.
- Light-mode only (`.preferredColorScheme(.light)` set at root). All UI assumes warm white backgrounds (Estus brand system).
- Brand palette: light backgrounds (`#E3E3E3`, `#FFFFFF`, `#F0F0F0`), borders (`#EBEBEB`, `#F2F2F2`), dark text (`#0C0D0D`, `#6B6E63`, `#A3A69B`), dimension accent colors (Dusty Rose, Rose Pink, Periwinkle, Olive Gold, Warm Gold, Deep Indigo, Soft Violet), goal accents (Warm Amber, Soft Coral, Dark Teal, Terracotta).
- Feature modules follow the pattern: `Screen` (SwiftUI view) + `ViewModel` (`@Observable` class) where state is non-trivial.
- `RecommendationEngine` is deterministic and local — no API calls. It uses `SupplementKnowledgeBase` for supplement data and `goalSupplementMap` for goal-to-supplement mapping.
- `DataStore` protocol abstracts persistence. Currently backed by `LocalStorageService`; will swap to Supabase in a future milestone.
- Onboarding is a linear flow managed by screen index in `OnboardingFlow.swift`. New screens must be added to the `switch` statement and `totalScreens` must be updated.

## Key Warnings
- CRITICAL: After adding/removing/renaming any Swift file, you MUST run `xcodegen generate` to regenerate the Xcode project. The `project.pbxproj` is generated from `project.yml` — never edit it by hand.
- NEVER commit API keys, Supabase URLs, or RevenueCat keys. These are not yet configured and will use environment-based config.
- Pale Gold (`#E8C94A`) has low contrast on warm white — never use for small text, only fills/icons.
