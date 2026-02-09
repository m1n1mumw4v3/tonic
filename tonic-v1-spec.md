# Tonic — v1.0 Product Specification

> AI-powered personalized supplement plans with longitudinal tracking and optimization.
> This document is the single source of truth for building v1.0 with Claude Code.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Tech Stack](#2-tech-stack)
3. [Design System](#3-design-system)
4. [Data Models](#4-data-models)
5. [Onboarding Flow](#5-onboarding-flow)
6. [Core App Screens](#6-core-app-screens)
7. [AI Architecture](#7-ai-architecture)
8. [Subscription & Paywall](#8-subscription--paywall)
9. [Push Notifications](#9-push-notifications)
10. [Analytics](#10-analytics)
11. [Legal & Compliance](#11-legal--compliance)
12. [v1 Scope & Deferred Features](#12-v1-scope--deferred-features)

---

## 1. Product Overview

### Value Proposition

Most supplement companies sell you a stack and forget you. Tonic closes the loop: recommend → track → measure → adjust. The longer someone uses the app, the smarter their plan gets and the harder it is to leave.

### Core Loop

1. User completes onboarding survey (3-5 min)
2. AI generates personalized supplement plan with explanations
3. User tracks daily supplement intake + 5 wellness dimensions (<30 sec)
4. System calculates aggregated Wellbeing Score (0-100)
5. After 2-4 weeks, AI generates insights from longitudinal data
6. Plan adjusts over time based on tracked outcomes

### Revenue Model

Subscription-first. Hard paywall after onboarding with 7-day free trial. Affiliate revenue from supplement purchase links is ancillary (deferred to v2).

### Target Platform

iOS only (native Swift/SwiftUI). No Android in v1.

---

## 2. Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | Swift / SwiftUI | Native iOS app |
| UI Charts | Swift Charts (Apple) | Trend lines, progress dashboards |
| Haptics | UIKit Haptic Engine (UIImpactFeedbackGenerator, UISelectionFeedbackGenerator) | Slider detents, check animations, button feedback |
| Backend | Supabase (Postgres + Auth + Edge Functions + Realtime) | Database, auth, serverless functions, real-time sync |
| AI Layer | Anthropic Claude API (claude-sonnet-4-5-20250929) | Plan generation explanations, longitudinal insights |
| Health Data | Apple HealthKit | Sleep duration, heart rate, HRV, steps, workouts |
| Payments | RevenueCat | Subscription management, App Store billing, trials |
| Analytics | PostHog (iOS SDK) | Product analytics, feature flags, funnels |
| Push | APNs (Apple Push Notification service) | Daily check-in reminders, supplement timing |

### Project Structure

```
Tonic/
├── App/
│   ├── TonicApp.swift                  # App entry point
│   ├── ContentView.swift               # Root navigation
│   └── AppState.swift                  # Global app state
├── Design/
│   ├── DesignTokens.swift              # Colors, typography, spacing
│   ├── Components/
│   │   ├── WellbeingScoreRing.swift    # Segmented ring component
│   │   ├── WellnessSlider.swift        # Custom haptic slider
│   │   ├── SupplementCard.swift        # Pill tray card
│   │   ├── InsightCard.swift           # AI insight display
│   │   ├── SpectrumBar.swift           # Brand element bar
│   │   └── CTAButton.swift             # Primary/secondary buttons
│   └── Modifiers/
│       └── HapticModifiers.swift       # Haptic feedback helpers
├── Features/
│   ├── Onboarding/
│   │   ├── OnboardingFlow.swift        # Survey coordinator
│   │   ├── Screens/
│   │   │   ├── WelcomeScreen.swift
│   │   │   ├── NameScreen.swift
│   │   │   ├── BasicInfoScreen.swift
│   │   │   ├── GoalsScreen.swift
│   │   │   ├── CurrentSuppsScreen.swift
│   │   │   ├── MedicationsScreen.swift
│   │   │   ├── LifestyleScreen.swift
│   │   │   ├── BaselineScreen.swift
│   │   │   ├── HealthKitScreen.swift
│   │   │   └── AIInterstitialScreen.swift
│   │   └── OnboardingViewModel.swift
│   ├── Paywall/
│   │   ├── PaywallScreen.swift
│   │   └── PaywallViewModel.swift
│   ├── Home/
│   │   ├── HomeScreen.swift            # Main dashboard
│   │   └── HomeViewModel.swift
│   ├── DailyCheckIn/
│   │   ├── CheckInFlow.swift           # Sliders + pill tray
│   │   └── CheckInViewModel.swift
│   ├── Plan/
│   │   ├── PlanScreen.swift            # Supplement plan display
│   │   └── PlanViewModel.swift
│   ├── Insights/
│   │   ├── InsightsScreen.swift        # AI insights list
│   │   └── InsightsViewModel.swift
│   ├── Progress/
│   │   ├── ProgressScreen.swift        # Charts and trends
│   │   └── ProgressViewModel.swift
│   └── Settings/
│       ├── SettingsScreen.swift
│       └── SettingsViewModel.swift
├── Services/
│   ├── SupabaseService.swift           # Supabase client
│   ├── AuthService.swift               # Authentication
│   ├── AIService.swift                 # Claude API calls
│   ├── HealthKitService.swift          # HealthKit integration
│   ├── NotificationService.swift       # Push notifications
│   ├── AnalyticsService.swift          # PostHog wrapper
│   └── SubscriptionService.swift       # RevenueCat wrapper
├── Models/
│   ├── UserProfile.swift
│   ├── SupplementPlan.swift
│   ├── DailyCheckIn.swift
│   ├── WellbeingScore.swift
│   └── Insight.swift
└── Utilities/
    ├── RecommendationEngine.swift      # Deterministic rules engine
    ├── SupplementKnowledgeBase.swift    # Supplement data + interactions
    └── Extensions.swift
```

### XcodeGen Project Generation

This project uses **XcodeGen** (`project.yml`) to generate the Xcode project file. The `project.pbxproj` is a generated artifact — file membership is determined by what exists on disk under the `Tonic/` source directory.

**Critical rule for Claude Code:** After creating any new `.swift` file, you **must** run `xcodegen generate` to regenerate the `.xcodeproj`. Without this step, Xcode will not know about the new file and you will get "Cannot find ___ in scope" build errors. This applies to new files, renamed files, moved files, or deleted files — any change to the file tree requires regeneration.

```bash
# Run from the project root after adding/removing/moving any source files
xcodegen generate
```

---

## 3. Design System

### Philosophy

Challenger Deep / Night Owl terminal aesthetic. Multi-accent spectrum where each wellness dimension has its own color, reinforcing "balanced variety of nutrients." Deep navy backgrounds, not pure black.

### Color Palette

```swift
// MARK: - Backgrounds
static let bgDeepest       = Color(hex: "#0E1025")  // App background
static let bgSurface       = Color(hex: "#141733")  // Cards, sheets
static let bgElevated      = Color(hex: "#1B1F42")  // Modals, elevated surfaces

// MARK: - Text
static let textPrimary     = Color(hex: "#D6DEEB")  // Primary body text
static let textSecondary   = Color(hex: "#7E8CA8")  // Captions, labels
static let textTertiary    = Color(hex: "#4A5274")  // Disabled, hints

// MARK: - Borders
static let borderDefault   = Color(hex: "#1F2347")  // Card borders
static let borderSubtle    = Color(hex: "#181C3A")  // Dividers

// MARK: - Dimension Accents (each wellness metric gets its own color)
static let accentSleep     = Color(hex: "#C792EA")  // Lavender/purple
static let accentEnergy    = Color(hex: "#FFCB6B")  // Warm amber
static let accentClarity   = Color(hex: "#82AAFF")  // Bright blue
static let accentMood      = Color(hex: "#F78C6C")  // Coral/orange
static let accentGut       = Color(hex: "#C3E88D")  // Soft green

// MARK: - Functional
static let positive        = Color(hex: "#7FE0A0")  // Success, improvement
static let negative        = Color(hex: "#FF5572")  // Decline, warnings
static let info            = Color(hex: "#89DDFF")  // Links, cyan accent

// MARK: - Spectrum Bar (brand element using all 5 dimension accents)
// Horizontal bar: Sleep → Energy → Clarity → Mood → Gut
// Use in: loading screens, section dividers, app icon, marketing
```

### Typography

Use the **Geist** font family (by Vercel). Bundle both Geist Sans and Geist Mono with the app.

```swift
// MARK: - Typography Scale

// Display / Large Headers (e.g., "Good morning, Matt")
// Geist Sans Light 300, large sizes
static let displayFont = Font.custom("GeistSans-Light", size: 32)

// Section Headers (e.g., "Today's Supplements", "Daily Check-in")
// Geist Sans SemiBold 600, uppercase with letter-spacing
static let sectionHeader = Font.custom("GeistSans-SemiBold", size: 13)
// Apply: .tracking(1.5), .textCase(.uppercase), color: textSecondary

// Body Copy (e.g., AI explanations, insight text)
// Geist Sans Regular 400
static let body = Font.custom("GeistSans-Regular", size: 15)

// Data / Metrics / Dosages (e.g., "400mg", "72", score numbers)
// Geist Mono Medium 500
static let dataMono = Font.custom("GeistMono-Medium", size: 16)

// Timestamps / Labels (e.g., "Feb 8 · 9:42 AM", "EVENING")
// Geist Mono Regular, uppercase with letter-spacing
static let labelMono = Font.custom("GeistMono-Regular", size: 11)
// Apply: .tracking(1.2), .textCase(.uppercase), color: textTertiary
```

### Spacing Scale

```swift
static let spacing4   = CGFloat(4)
static let spacing8   = CGFloat(8)
static let spacing12  = CGFloat(12)
static let spacing16  = CGFloat(16)
static let spacing20  = CGFloat(20)
static let spacing24  = CGFloat(24)
static let spacing32  = CGFloat(32)
static let spacing40  = CGFloat(40)
static let spacing48  = CGFloat(48)
```

### Corner Radii

```swift
static let radiusSmall   = CGFloat(8)    // Checkboxes, small elements
static let radiusMedium  = CGFloat(12)   // Cards, supplement items
static let radiusLarge   = CGFloat(16)   // Sheets, large containers
static let radiusFull    = CGFloat(999)  // Pills, circular elements
```

### CTA Buttons

**Primary CTA (Inverted Solid):** White background (#D6DEEB), deep navy text (#0E1025). Used for paywall conversion, onboarding "Continue", key actions. Bold, decisive, Vercel/Linear style. Full-width, 52pt height, 12pt corner radius.

**Secondary CTA (Frosted Glass):** Semi-transparent background (rgba(255,255,255,0.08)) with subtle backdrop blur. Border: 1px rgba(255,255,255,0.12). Used for secondary actions, "Skip", "Maybe later". Doesn't compete with primary.

### Spectrum Bar Brand Element

A 5-color horizontal bar using all dimension accent colors in order: Sleep (lavender) → Energy (amber) → Clarity (blue) → Mood (coral) → Gut (green). Height: 3-4pt, full-width. Use as loading indicator, section divider, onboarding progress bar, and in app icon/marketing.

---

## 4. Data Models

### Supabase Schema

```sql
-- Users
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  first_name TEXT NOT NULL,
  email TEXT UNIQUE,
  auth_id UUID REFERENCES auth.users(id)
);

-- Onboarding Profile (survey responses)
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Basic info
  age INTEGER NOT NULL,
  sex TEXT NOT NULL CHECK (sex IN ('male', 'female', 'other', 'prefer_not_to_say')),
  height_inches INTEGER,
  weight_lbs INTEGER,

  -- Goals (stored as array)
  health_goals TEXT[] NOT NULL DEFAULT '{}',
  -- Options: sleep, energy, focus, gut_health, immunity, fitness_recovery,
  --          stress_anxiety, skin_hair_nails, longevity

  -- Current supplements (free text or structured)
  current_supplements JSONB DEFAULT '[]',

  -- Health constraints
  allergies TEXT[] DEFAULT '{}',
  medications TEXT[] DEFAULT '{}',

  -- Lifestyle
  diet_type TEXT CHECK (diet_type IN ('omnivore', 'vegetarian', 'vegan', 'keto', 'paleo', 'pescatarian', 'other')),
  exercise_frequency TEXT CHECK (exercise_frequency IN ('none', '1-2_weekly', '3-4_weekly', '5+_weekly')),
  exercise_type TEXT[] DEFAULT '{}',
  sleep_hours_avg NUMERIC(3,1),
  caffeine_daily TEXT CHECK (caffeine_daily IN ('none', '1_cup', '2-3_cups', '4+_cups')),
  alcohol_weekly TEXT CHECK (alcohol_weekly IN ('none', '1-3_drinks', '4-7_drinks', '8+_drinks')),
  stress_level TEXT CHECK (stress_level IN ('low', 'moderate', 'high', 'very_high')),

  -- Baselines (0-100, captured via sliders during onboarding)
  baseline_energy INTEGER CHECK (baseline_energy BETWEEN 0 AND 100),
  baseline_clarity INTEGER CHECK (baseline_clarity BETWEEN 0 AND 100),
  baseline_sleep INTEGER CHECK (baseline_sleep BETWEEN 0 AND 100),
  baseline_mood INTEGER CHECK (baseline_mood BETWEEN 0 AND 100),
  baseline_gut INTEGER CHECK (baseline_gut BETWEEN 0 AND 100),

  -- Apple Health
  healthkit_enabled BOOLEAN DEFAULT FALSE
);

-- Supplement Plan
CREATE TABLE supplement_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  version INTEGER DEFAULT 1,
  ai_reasoning TEXT  -- LLM-generated explanation of overall plan
);

-- Individual supplements within a plan
CREATE TABLE plan_supplements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID REFERENCES supplement_plans(id) ON DELETE CASCADE,
  supplement_id UUID REFERENCES supplement_knowledge_base(id),
  custom_name TEXT,                    -- If not in knowledge base
  dosage TEXT NOT NULL,                -- e.g., "400mg"
  dosage_mg NUMERIC,                   -- Numeric for calculations
  timing TEXT NOT NULL CHECK (timing IN ('morning', 'afternoon', 'evening', 'bedtime', 'with_food', 'empty_stomach')),
  frequency TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'every_other_day', 'weekly', 'as_needed')),
  reasoning TEXT,                       -- LLM-generated per-supplement explanation
  sort_order INTEGER DEFAULT 0
);

-- Supplement Knowledge Base (curated, research-backed)
CREATE TABLE supplement_knowledge_base (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,                  -- e.g., "Magnesium Glycinate"
  category TEXT NOT NULL,              -- e.g., "mineral", "vitamin", "amino_acid", "adaptogen", "herb"
  common_dosage_range TEXT,            -- e.g., "200-400mg"
  recommended_timing TEXT,
  benefits TEXT[] DEFAULT '{}',        -- Tags: sleep, energy, focus, gut, immunity, etc.
  contraindications TEXT[] DEFAULT '{}',
  drug_interactions TEXT[] DEFAULT '{}',
  notes TEXT,
  research_summary TEXT,
  is_active BOOLEAN DEFAULT TRUE
);

-- Daily Check-ins
CREATE TABLE daily_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  checkin_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Wellness sliders (0-100)
  sleep_score INTEGER CHECK (sleep_score BETWEEN 0 AND 100),
  energy_score INTEGER CHECK (energy_score BETWEEN 0 AND 100),
  clarity_score INTEGER CHECK (clarity_score BETWEEN 0 AND 100),
  mood_score INTEGER CHECK (mood_score BETWEEN 0 AND 100),
  gut_score INTEGER CHECK (gut_score BETWEEN 0 AND 100),

  -- Aggregated wellbeing (computed)
  wellbeing_score INTEGER CHECK (wellbeing_score BETWEEN 0 AND 100),

  -- Optional notes
  notes TEXT,

  UNIQUE(user_id, checkin_date)
);

-- Supplement Intake Log
CREATE TABLE supplement_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_supplement_id UUID REFERENCES plan_supplements(id),
  logged_date DATE NOT NULL,
  taken BOOLEAN DEFAULT FALSE,
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Insights
CREATE TABLE insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  insight_type TEXT CHECK (insight_type IN ('correlation', 'trend', 'recommendation', 'milestone')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data_points_used INTEGER,   -- How many days of data informed this
  dimension TEXT,              -- Which wellness dimension (sleep, energy, etc.) or NULL for general
  is_read BOOLEAN DEFAULT FALSE,
  is_dismissed BOOLEAN DEFAULT FALSE
);

-- Streaks
CREATE TABLE user_streaks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  last_checkin_date DATE
);

-- Apple Health Data Cache
CREATE TABLE healthkit_data (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  sleep_hours NUMERIC(4,2),
  resting_heart_rate INTEGER,
  hrv_ms NUMERIC(5,1),
  steps INTEGER,
  active_minutes INTEGER,
  UNIQUE(user_id, date)
);
```

### Wellbeing Score Calculation

The Wellbeing Score is a weighted average of the 5 daily dimensions. Equal weights by default (each 20%), with the option to weight by user-selected goals later.

```swift
func calculateWellbeingScore(
    sleep: Int, energy: Int, clarity: Int, mood: Int, gut: Int
) -> Int {
    // Equal weights (v1)
    let raw = Double(sleep + energy + clarity + mood + gut) / 5.0
    return Int(round(raw))
}
```

The wellbeing score ring visualization is segmented: each of the 5 dimension values contributes a proportional arc segment in its own accent color, creating a multi-colored ring that shows both the total score and the dimensional breakdown at a glance.

---

## 5. Onboarding Flow

### Screen Sequence

The onboarding is 8-10 screens plus the AI interstitial. Progress bar at top uses the spectrum bar gradient. Each screen has one clear question with a primary CTA to continue.

**Screen 1 — Welcome**
- App logo + spectrum bar
- Tagline: "Your supplements, optimized."
- Brief value prop (2-3 lines max)
- CTA: "Get Started"

**Screen 2 — Name**
- "What should we call you?"
- Single text input for first name
- Used throughout app: "Good morning, Matt", "Matt's Plan"
- CTA: "Continue"

**Screen 3 — Basics**
- Age (number picker or stepper)
- Sex (segmented control: Male / Female / Other / Prefer not to say)
- Height (ft/in picker) and Weight (lbs stepper) — optional
- CTA: "Continue"

**Screen 4 — Health Goals**
- "What are your top health goals?"
- "Select all that apply. We'll tailor your plan around these."
- Multi-select list:
  - Better sleep
  - More energy
  - Mental clarity & focus
  - Stress & anxiety relief
  - Gut health & digestion
  - Immune support
  - Fitness recovery
  - Skin, hair & nails
  - Longevity
- Minimum 1 selection required
- CTA: "Continue"

**Screen 5 — Current Supplements**
- "Are you currently taking any supplements?"
- Toggle: Yes / No
- If yes: free-text input or structured add (name + dosage)
- CTA: "Continue"

**Screen 6 — Medications & Allergies**
- "Any medications we should know about?"
- Free-text input (important for interaction checking)
- "Any known allergies or sensitivities?"
- Common tags (shellfish, soy, gluten, dairy) + free text
- CTA: "Continue"

**Screen 7 — Lifestyle**
- Diet type (single select: Omnivore, Vegetarian, Vegan, Keto, Paleo, Pescatarian, Other)
- Exercise frequency (None, 1-2x/week, 3-4x/week, 5+/week)
- Caffeine intake (None, 1 cup/day, 2-3 cups, 4+)
- Alcohol intake (None, 1-3 drinks/week, 4-7, 8+)
- Stress level (Low, Moderate, High, Very High)
- CTA: "Continue"

**Screen 8 — Baseline Wellness**
- "Rate your typical wellness levels."
- "We'll use these as your starting point to measure improvement."
- 5 sliders using the same component as daily check-in:
  - Sleep Quality (Restless / Broken → Deep & Restorative) — uses accentSleep color
  - Energy Level (Drained / Fatigued → Vibrant & Sustained) — uses accentEnergy color
  - Mental Clarity (Foggy / Scattered → Sharp & Locked In) — uses accentClarity color
  - Mood (Low / Flat → Positive & Balanced) — uses accentMood color
  - Gut Health (Uncomfortable / Off → Smooth & Settled) — uses accentGut color
- Each slider is 0-100 with haptic detents every 10 units
- This screen doubles as training for the daily check-in mechanic
- CTA: "Continue"

**Screen 9 — Apple Health (Optional)**
- "Connect Apple Health for richer insights"
- List of data points we'll access: sleep duration, heart rate, HRV, steps, workouts
- Privacy assurance copy
- Two CTAs: "Connect Apple Health" (primary) / "Skip for now" (secondary frosted glass)
- If connected, trigger HealthKit authorization prompt

**Screen 10 — AI Interstitial (Plan Generation)**
- Full-screen animated sequence, 15-20 seconds
- Animated progress stages:
  1. "Analyzing your profile..." (0-25%)
  2. "Cross-referencing clinical research..." (25-50%)
  3. "Checking for interactions..." (50-75%)
  4. "Building your personalized plan..." (75-100%)
- Spectrum bar as progress indicator
- Subtle particle/dot animation in background
- During this time, the app actually:
  - Sends profile data to the recommendation engine
  - Calls Claude API for plan explanations
  - Saves plan to Supabase
- On completion: transition to paywall

### Onboarding Design Notes

- Each screen: single question, large Geist Sans Light header, brief subtext in textSecondary
- Selection items: rounded rectangles with accent border when selected, checkbox with dimension accent color
- Progress: thin spectrum bar at top showing completion (fills left to right using the 5-color gradient)
- Transitions: smooth horizontal slide between screens
- All screens dark background (#0E1025)

---

## 6. Core App Screens

### Tab Bar

4 tabs along bottom:
1. **Home** — Dashboard with wellbeing score, today's supplements, streak
2. **Plan** — Full supplement plan with details and explanations
3. **Progress** — Charts, trends, historical data
4. **Settings** — Account, notifications, Apple Health, subscription

### Home Screen (Tab 1)

**Layout (top to bottom):**

1. **Header Bar**
   - "Good morning, Matt" (Geist Sans Light, 28pt)
   - Current date in mono label format
   - Streak badge (if active): flame icon + "12 day streak" in accentEnergy

2. **Wellbeing Score Card** (large, prominent)
   - Segmented ring visualization (140x140pt):
     - Each dimension = colored arc segment proportional to its score
     - Sleep segment in #C792EA, Energy in #FFCB6B, etc.
     - Ring fills clockwise, gaps between segments
   - Score number centered (Geist Mono Medium, 36pt)
   - "WELLBEING" label below (Geist Mono, uppercase, 10pt, textSecondary)
   - Below ring: 5 mini dimension scores in a row
     - Each shows number + label in its accent color
   - 7-day trend sparkline below
   - Tap to expand → Progress tab

3. **Daily Check-in CTA** (if not yet completed today)
   - Card with spectrum bar accent top border
   - "How are you feeling today?"
   - Primary CTA: "Check In" (inverted solid)
   - After completion: card shows "✓ Checked in" with today's scores

4. **Today's Supplements Card**
   - Section header: "TODAY'S SUPPLEMENTS"
   - "Take All" link (top right, in info/cyan color)
   - Pill tray: list of supplement cards
     - Each shows: supplement name, dosage (mono font), timing badge
     - Tap to toggle taken/not taken
     - When toggled: checkmark animation + haptic impact feedback + subtle sound
     - Card background subtly tints with the primary accent on completion
   - Completion indicator: "3 of 5 taken" with mini progress bar

5. **Latest Insight** (if available, after 2+ weeks of data)
   - InsightCard component
   - Subtle accent border (dimension-specific color)
   - Truncated preview, tap to expand

### Daily Check-In Flow

Triggered from Home screen CTA. Modal sheet presentation.

**Step 1: Wellness Sliders**
- 5 continuous sliders, one per dimension
- Each slider uses its dimension accent color for the fill and thumb
- Anchor labels at each end (e.g., "Restless / Broken" ↔ "Deep & Restorative")
- Haptic detents every 10 units on the 0-100 scale (UISelectionFeedbackGenerator)
- As slider moves, the dimension label at left subtly pulses
- When released, micro-animation confirms the value
- "Continue" CTA at bottom

**Step 2: Supplement Logging (Pill Tray)**
- Grid/list of today's supplements
- Each as a tappable card with:
  - Supplement name + dosage
  - Timing badge (MORNING / EVENING)
  - Checkbox (rounded square, fills with accent color)
- "Took Everything" button at top for one-tap complete
- Each tap: satisfying haptic (UIImpactFeedbackGenerator.medium) + checkmark animation
- Visual: think popping bubble wrap — each tap should feel rewarding
- "Done" CTA at bottom

**Step 3: Completion**
- Brief celebration: wellbeing score animates to today's value
- "Come back tomorrow" or streak congratulation
- Auto-dismiss after 2 seconds or tap to close

**Total interaction time target: <30 seconds**

### Plan Screen (Tab 2)

**Layout:**

1. **Plan Header**
   - "Matt's Supplement Plan"
   - Plan version + date generated
   - Spectrum bar divider

2. **Supplement List** (grouped by timing)
   - **Morning** section
     - Each supplement card:
       - Name (Geist Sans SemiBold)
       - Dosage (Geist Mono Medium, accent color)
       - Category badge (vitamin, mineral, adaptogen, etc.)
       - Tap to expand → detail view
   - **Evening** section
   - Same card format

3. **Supplement Detail View** (sheet presentation on tap)
   - Full supplement name + dosage
   - "Why this is in your plan" — AI-generated explanation (2-3 sentences)
   - Benefits tags (mapped to dimension colors)
   - Timing recommendation
   - Research summary (brief, from knowledge base)
   - Interaction warnings (if any, in negative color)

4. **Overall Plan Reasoning**
   - Expandable card at bottom
   - AI-generated overview of the full plan strategy
   - How supplements work together, what gaps they fill

### Progress Screen (Tab 3)

**Layout:**

1. **Time Range Selector**
   - Segmented control: 7D / 30D / 90D / All
   - Affects all charts below

2. **Wellbeing Score Trend**
   - Line chart (Swift Charts)
   - X-axis: dates, Y-axis: 0-100
   - Line color: positive if trending up, negative if down
   - Baseline reference line (from onboarding)

3. **Dimension Breakdown**
   - 5 mini sparkline charts, one per dimension
   - Each in its accent color
   - Tap any to expand to full chart view
   - Shows: current value, trend direction (↑ ↓ →), change vs. baseline

4. **Supplement Adherence**
   - Calendar heat map or simple adherence percentage
   - "You took 92% of supplements this week"
   - Streak counter

5. **Insights History**
   - Chronological list of all AI insights
   - Grouped by week/month
   - Each tagged with relevant dimension color

### Settings Screen (Tab 4)

- Account info (name, email)
- Notification preferences (daily reminder time, toggle on/off)
- Apple Health (connect/disconnect, what data is shared)
- Subscription management (current plan, billing, upgrade/downgrade — links to RevenueCat managed page)
- Retake onboarding survey (regenerates plan)
- About / Privacy Policy / Terms
- "Send Feedback" (mailto link or in-app form)
- Sign out / Delete account

---

## 7. AI Architecture

### Hybrid Approach

The system uses a deterministic rules engine for safety-critical decisions and an LLM for personalization and natural language.

### Layer 1: Recommendation Engine (Deterministic)

```
User Profile → Goal Mapping → Supplement Candidates → Interaction Filter → Dosage Adjustment → Ranked Plan
```

**Goal Mapping:** Each health goal maps to a set of candidate supplements from the knowledge base.

```swift
// Example mappings (codified in SupplementKnowledgeBase.swift)
let goalSupplementMap: [String: [String]] = [
    "sleep": ["Magnesium Glycinate", "L-Theanine", "Melatonin", "Glycine", "Tart Cherry Extract"],
    "energy": ["Vitamin B Complex", "CoQ10", "Iron", "Vitamin D3", "Rhodiola Rosea"],
    "focus": ["L-Theanine", "Omega-3 DHA", "Lion's Mane", "Bacopa Monnieri", "Phosphatidylserine"],
    "gut_health": ["Probiotics", "L-Glutamine", "Digestive Enzymes", "Fiber", "Zinc Carnosine"],
    "immunity": ["Vitamin C", "Vitamin D3", "Zinc", "Elderberry", "Quercetin"],
    "stress_anxiety": ["Ashwagandha KSM-66", "L-Theanine", "Magnesium Glycinate", "Rhodiola Rosea", "GABA"],
    "fitness_recovery": ["Creatine Monohydrate", "Omega-3", "Tart Cherry Extract", "Vitamin D3", "Magnesium"],
    "skin_hair_nails": ["Biotin", "Collagen Peptides", "Vitamin C", "Zinc", "Vitamin E"],
    "longevity": ["Omega-3", "Vitamin D3", "CoQ10", "NAD+/NMN", "Resveratrol"]
]
```

**Interaction Filter:** Check each candidate against:
1. User's current medications (flag known interactions)
2. Other supplements in the plan (avoid redundancy, check interactions)
3. User allergies/sensitivities
4. Contraindications from knowledge base

**Dosage Adjustment:** Modify standard dosages based on:
- Age (reduce for older adults on some supplements)
- Weight (adjust fat-soluble vitamins)
- Sex (different needs for iron, etc.)
- Diet type (vegans need B12, D3 supplementation)

**Output:** A ranked list of 5-8 supplements with dosages and timing. This is the deterministic foundation — it never hallucinates.

### Layer 2: Claude API (Natural Language)

Claude is called for two purposes:

**Purpose 1: Plan Explanation Generation (during onboarding)**

```
System: You are a knowledgeable supplement advisor for the Tonic app. You explain
supplement plans in clear, friendly language. You NEVER make medical claims or
diagnoses. Frame everything as informational and educational. Use the user's name.

User: Generate explanations for this supplement plan.

User Profile:
{serialized profile data}

Recommended Plan (from rules engine):
{serialized plan with supplements, dosages, timing}

Generate:
1. A 2-3 sentence overall plan summary explaining the strategy
2. For each supplement: a 2-3 sentence explanation of why it's included,
   specific to THIS user's profile and goals
3. Keep language warm but evidence-informed. Reference the user's stated
   goals and conditions where relevant.

Respond in JSON format:
{
  "plan_summary": "...",
  "supplement_explanations": {
    "Magnesium Glycinate": "...",
    "Vitamin D3": "...",
    ...
  }
}
```

**Purpose 2: Longitudinal Insights (after 2+ weeks of data)**

```
System: You are an analytical wellness advisor for the Tonic app. You identify
patterns in user tracking data and generate actionable insights. You NEVER make
medical claims. Frame correlations carefully — "your data suggests" not
"this proves." Use the user's name.

User: Analyze this tracking data and generate insights.

User Profile:
{serialized profile}

Current Plan:
{serialized active plan}

Tracking Data (last 14-30 days):
{serialized daily check-ins with all 5 dimensions + supplement adherence}

Apple Health Data (if available):
{serialized HealthKit data}

Generate 1-3 insights. For each:
- Type: correlation | trend | recommendation | milestone
- Which dimension(s) it relates to
- Clear, specific observation with data references
- Suggested action (if applicable)

Respond in JSON format:
{
  "insights": [
    {
      "type": "correlation",
      "dimension": "sleep",
      "title": "Magnesium is helping your sleep",
      "body": "...",
      "data_points_used": 21
    }
  ]
}
```

### Insight Generation Schedule

- First insight: after 14 days of check-in data (minimum viable pattern)
- Ongoing: generate new insights weekly via Supabase Edge Function cron job
- Maximum 3 insights per generation cycle to avoid overwhelm
- Each insight requires minimum 7 data points in the relevant dimension

### AI Safety Guardrails

1. **No medical claims.** All LLM output is post-processed to strip language like "cures", "treats", "diagnoses". Use: "may support", "research suggests", "your data indicates".
2. **No dosage hallucination.** The LLM NEVER sets dosages. It only explains dosages that the rules engine determined.
3. **Interaction warnings come from the knowledge base, not the LLM.** The LLM can reference them in explanations but doesn't generate them.
4. **All LLM responses are JSON-parsed.** If parsing fails, fall back to generic templates.

---

## 8. Subscription & Paywall

### Paywall Placement

After onboarding survey → AI interstitial → Plan generated → **Paywall screen appears**.

The user has invested 3-5 minutes answering questions. They've seen the AI "build" their plan. Maximum curiosity, maximum perceived value. This is where conversion happens.

### Paywall Screen Design

**Layout:**

1. **Plan Teaser**
   - Show 1-2 supplements from the generated plan (blurred or partial)
   - "Your personalized plan is ready" headline
   - Spectrum bar accent

2. **Value Props** (3-4 bullet points max)
   - "AI-powered personalized supplement plan"
   - "Daily tracking with Wellbeing Score"
   - "Smart insights that improve over time"
   - "Apple Health integration"

3. **Pricing Tiers** (3 options, annual pre-selected)
   - **Annual: $79.99/year** — "Best Value" badge, "$1.54/week" anchor
   - **Quarterly: $29.99/quarter** — "$2.31/week"
   - **Monthly: $12.99/month** — "$3.00/week"
   - Annual plan visually emphasized (slightly larger, accent border)

4. **Primary CTA**
   - "Start Free Trial" (inverted solid button, full-width)
   - Subtext: "7-day free trial, cancel anytime"

5. **Secondary**
   - "Restore Purchase" link (small, textSecondary)
   - Terms of service / Privacy policy links (footer)

### RevenueCat Configuration

```swift
// Products (configured in App Store Connect + RevenueCat dashboard)
let monthlyProductId  = "tonic_premium_monthly"     // $12.99/mo
let quarterlyProductId = "tonic_premium_quarterly"   // $29.99/qtr
let annualProductId   = "tonic_premium_annual"       // $79.99/yr

// All include 7-day free trial
// RevenueCat handles:
//   - Trial management
//   - Billing
//   - Subscription status checks
//   - Grace periods
//   - Restore purchases
```

### Subscription State Machine

```
NOT_SUBSCRIBED → TRIAL_ACTIVE → SUBSCRIBED → (EXPIRED | CANCELLED)
                                     ↓
                               GRACE_PERIOD → EXPIRED
```

- App checks subscription status on every launch via RevenueCat
- If expired/cancelled: redirect to paywall, core features locked
- During trial: full access, subtle "X days left in trial" indicator in settings

---

## 9. Push Notifications

### Notification Types

1. **Morning Supplement Reminder**
   - Default: 8:00 AM (user-configurable)
   - "Good morning, Matt. Time for your morning supplements."
   - Tapping opens the daily check-in flow

2. **Evening Supplement Reminder**
   - Default: 8:00 PM (user-configurable)
   - "Don't forget your evening supplements."

3. **Daily Check-in Nudge**
   - Fires if no check-in by 7:00 PM
   - "How are you feeling today? Quick check-in takes 20 seconds."

4. **Streak at Risk**
   - Fires at 9:00 PM if no activity that day
   - "Your X-day streak is on the line! Check in now."

5. **New Insight Available**
   - When AI generates a new insight
   - "New insight: Your sleep improved 18% this month."

### Implementation

- Use APNs directly (no third-party push service needed for v1)
- Register for notifications during onboarding (after Apple Health screen)
- Local notifications for time-based reminders (no server needed)
- Remote notifications only for new insights (via Supabase Edge Function → APNs)

---

## 10. Analytics

### PostHog Events

Track these key events for funnel analysis and product optimization:

**Onboarding Funnel:**
- `onboarding_started`
- `onboarding_screen_viewed` (with `screen_name` property)
- `onboarding_screen_completed` (with `screen_name`)
- `onboarding_goals_selected` (with `goals` array)
- `onboarding_healthkit_connected` (boolean)
- `onboarding_completed`
- `ai_plan_generated`

**Paywall:**
- `paywall_viewed`
- `paywall_plan_selected` (with `plan_type`: monthly/quarterly/annual)
- `trial_started` (with `plan_type`)
- `subscription_activated` (with `plan_type`)
- `paywall_dismissed`

**Core Engagement:**
- `daily_checkin_started`
- `daily_checkin_completed` (with `wellbeing_score`, `time_to_complete_seconds`)
- `supplement_logged` (with `supplement_name`, `taken` boolean)
- `take_all_tapped`
- `insight_viewed` (with `insight_type`, `dimension`)
- `plan_detail_viewed` (with `supplement_name`)
- `progress_chart_viewed` (with `time_range`)

**Retention:**
- `app_opened` (daily active tracking)
- `streak_milestone` (with `streak_count`: 7, 14, 30, etc.)

### Key Metrics to Monitor

- **Onboarding completion rate** (started → completed)
- **Paywall conversion rate** (viewed → trial started)
- **Trial → Paid conversion rate**
- **D1, D7, D30 retention**
- **Daily check-in completion rate** (DAU / total subscribers)
- **Average time to complete check-in**
- **Supplement adherence rate** (taken / total daily supplements)
- **Insight engagement rate** (viewed / generated)

---

## 11. Legal & Compliance

### Medical Disclaimer

Must be visible during onboarding and accessible in Settings:

> "Tonic provides informational content about dietary supplements. It is not intended to diagnose, treat, cure, or prevent any disease. The information provided is not a substitute for professional medical advice. Always consult your healthcare provider before starting any new supplement regimen, especially if you are pregnant, nursing, taking medications, or have a medical condition."

### Where Disclaimers Appear

1. **Onboarding** — brief version on medications screen: "We check for known interactions, but always consult your doctor."
2. **Plan Screen** — footer: "This plan is informational, not medical advice."
3. **Insight Cards** — footer on each: "Based on your self-reported data. Not medical advice."
4. **Settings** — full disclaimer accessible

### Data Privacy

- All user data stored in Supabase (hosted, SOC 2 compliant)
- Apple HealthKit data: only accessed with explicit permission, never shared with third parties, only used for insight generation
- No data sold to advertisers or third parties
- User can delete all data at any time (Settings → Delete Account)
- Privacy Policy must cover: data collected, how it's used, HealthKit specific terms, data retention, deletion rights

### App Store Compliance

- Health & Fitness category
- HealthKit usage description strings required in Info.plist
- Subscription terms must be clear before purchase
- Auto-renewable subscription guidelines compliance
- Privacy nutrition label in App Store Connect

---

## 12. v1 Scope & Deferred Features

### Included in v1

- Full onboarding survey (8-10 screens)
- AI plan generation with Claude API
- Daily check-in (wellness sliders + supplement logging)
- Wellbeing Score (0-100, segmented ring)
- Supplement plan display with AI explanations
- Apple Health sync (sleep, heart rate, HRV, steps)
- AI insights (after 2+ weeks of data)
- Progress dashboards with Swift Charts (trend lines, sparklines)
- Push notifications (local for reminders, remote for insights)
- Hard paywall with 7-day free trial (RevenueCat)
- Streak tracking
- PostHog analytics
- Settings (notifications, HealthKit, subscription, account)

### Deferred to v2

- **Affiliate purchase links** — Link out to Amazon/iHerb for each supplement. Not in v1 to keep the experience clean and avoid App Store review friction.
- **Social features** — Share wellbeing score, invite friends
- **Branded supplement line** — Not planned
- **Android** — Evaluate demand after iOS validates
- **Wearable integrations** — Apple Watch app, complications
- **Advanced ML** — Per-user model training with enough longitudinal data
- **Supplement scanner** — Scan existing supplement bottles to add to plan
- **Custom plan editing** — Let users modify AI-recommended plan
- **Multi-language support**
- **Widget** — iOS home screen widget showing wellbeing score + streak

---

## Appendix A: Supplement Knowledge Base (Seed Data)

The knowledge base should be seeded with the most common, well-researched supplements. This is a starting set — expand over time.

| Supplement | Category | Common Dosage | Key Benefits | Timing |
|-----------|----------|---------------|-------------|--------|
| Magnesium Glycinate | Mineral | 200-400mg | sleep, stress_anxiety, muscle | Evening |
| Vitamin D3 + K2 | Vitamin | 2000-5000 IU | immunity, energy, longevity | Morning with food |
| Omega-3 (EPA/DHA) | Fatty Acid | 1000-2000mg | focus, longevity, inflammation | Morning with food |
| Ashwagandha KSM-66 | Adaptogen | 300-600mg | stress_anxiety, energy, sleep | Evening |
| L-Theanine | Amino Acid | 100-200mg | focus, sleep, stress_anxiety | Morning or Evening |
| Vitamin B Complex | Vitamin | 1x daily | energy, focus, mood | Morning |
| Probiotics | Probiotic | 10-50B CFU | gut_health, immunity | Morning empty stomach |
| Zinc | Mineral | 15-30mg | immunity, skin_hair_nails, gut | Evening with food |
| Vitamin C | Vitamin | 500-1000mg | immunity, skin_hair_nails | Morning |
| CoQ10 | Coenzyme | 100-200mg | energy, longevity | Morning with food |
| Creatine Monohydrate | Amino Acid | 3-5g | fitness_recovery, focus | Any time |
| Collagen Peptides | Protein | 10-15g | skin_hair_nails, gut_health | Any time |
| Lion's Mane | Mushroom | 500-1000mg | focus, longevity | Morning |
| Rhodiola Rosea | Adaptogen | 200-400mg | energy, stress_anxiety | Morning |
| Melatonin | Hormone | 0.5-3mg | sleep | 30 min before bed |
| Biotin | Vitamin | 2500-5000mcg | skin_hair_nails | Morning |
| Iron | Mineral | 18-27mg | energy (esp. women) | Empty stomach with Vitamin C |
| NAC | Amino Acid | 600-1200mg | immunity, longevity | Morning |
| Berberine | Plant Extract | 500mg | gut_health, longevity | With meals |
| Tart Cherry Extract | Fruit Extract | 500-1000mg | sleep, fitness_recovery | Evening |

### Known Drug Interactions (Critical Subset)

These must be flagged during plan generation:

- **Blood thinners (Warfarin, etc.):** Omega-3, Vitamin E, Ginkgo, high-dose Vitamin K
- **SSRIs/SNRIs:** St. John's Wort (absolute contraindication), 5-HTP, high-dose Omega-3
- **Blood pressure medication:** CoQ10 (may potentiate), Magnesium (may potentiate)
- **Thyroid medication (Levothyroxine):** Iron, Calcium, Magnesium (take 4+ hours apart)
- **Immunosuppressants:** Echinacea, Elderberry, high-dose Vitamin C
- **Diabetes medication:** Berberine (may potentiate), Chromium
- **Statins:** CoQ10 (recommended alongside), Red Yeast Rice (contraindicated)

---

## Appendix B: Haptic Feedback Specification

| Interaction | Haptic Type | Intensity |
|------------|------------|-----------|
| Slider drag detent (every 10 units) | UISelectionFeedbackGenerator | Default |
| Slider release (value confirmed) | UIImpactFeedbackGenerator | Light |
| Supplement toggle (taken) | UIImpactFeedbackGenerator | Medium |
| "Take All" button | UINotificationFeedbackGenerator | Success |
| Check-in complete | UINotificationFeedbackGenerator | Success |
| Streak milestone | UINotificationFeedbackGenerator | Success |
| CTA button press | UIImpactFeedbackGenerator | Light |
| Error state | UINotificationFeedbackGenerator | Error |

---

## Appendix C: Animation Specification

| Element | Animation | Duration | Easing |
|---------|-----------|----------|--------|
| Wellbeing score ring fill | Stroke dashoffset | 800ms | easeOut |
| Supplement checkmark | Scale from 0 → 1 + opacity | 300ms | spring(damping: 0.6) |
| Slider thumb glow | Opacity pulse on drag | 200ms | linear |
| Daily check-in completion | Score counter (0 → final) | 1000ms | easeInOut |
| Onboarding screen transitions | Horizontal slide | 350ms | easeInOut |
| AI interstitial progress | Linear fill + stage text fade | 15-20s total | linear |
| Insight card entrance | Slide up + fade in | 400ms | spring(damping: 0.8) |
| Streak badge pulse | Scale 1 → 1.1 → 1 | 500ms | easeInOut |

---

*This specification is version 1.0. App name "Tonic" is a placeholder pending final trademark clearance.*
