# Ample Design System

> Internal module: `Tonic` · iOS 17+ · Light-mode only · All tokens live in `DesignTokens.swift`

---

## Philosophy

Ample's visual language is **warm, biological, and precise**. The interface feels like a well-made physical object — warm off-white surfaces, olive-toned text, subtle grain textures, and organic accent colors drawn from biology (chlorophyll greens, membrane golds, deep purples). Typography is clinical and modern (Geist), but the palette and micro-interactions add warmth. Every element uses design tokens — no raw literals.

---

## Color Palette

### Backgrounds (warm off-whites)

| Token | Hex | Usage |
|-------|-----|-------|
| `bgDeepest` | `#FAF8F3` | Page/screen background, the base canvas |
| `bgSurface` | `#F2EFE8` | Card and panel backgrounds |
| `bgElevated` | `#EBE7DF` | Badges, pressed states, slider tracks, toggles-off |

### Text (olive neutrals)

| Token | Hex | Usage |
|-------|-----|-------|
| `textPrimary` | `#1C1E17` | Headings, body copy, primary CTA fill |
| `textSecondary` | `#6B6E63` | Labels, supporting text, section headers |
| `textTertiary` | `#A3A69B` | Hints, timestamps, disabled states, subtle icons |

### Borders

| Token | Hex | Usage |
|-------|-----|-------|
| `borderDefault` | `#D9D5CC` | Standard card borders, dividers |
| `borderSubtle` | `#E5E1D9` | Very light outlines, picker containers |

### Wellness Dimension Accents

Each of the five tracked wellness dimensions has a dedicated color used for sliders, rings, badges, and charts.

| Dimension | Token | Hex | Color Name |
|-----------|-------|-----|------------|
| Sleep | `accentSleep` | `#7B2D8E` | Deep Purple |
| Energy | `accentEnergy` | `#E8C94A` | Pale Gold |
| Clarity | `accentClarity` | `#4A8FC2` | Ocean Blue |
| Mood | `accentMood` | `#D4A017` | Golden Membrane |
| Gut | `accentGut` | `#B8C234` | Acid Chartreuse |

These five colors form the **spectrum** — an ordered gradient used in progress bars, ring charts, and decorative borders: Sleep → Energy → Clarity → Mood → Gut.

> **Warning:** Pale Gold (`#E8C94A`) has low contrast on warm white backgrounds. Use it only for fills and icons, never for small text.

### Health Goal Accents

| Token | Hex | Color Name |
|-------|-----|------------|
| `accentLongevity` | `#2E9E9E` | Deep Teal |
| `accentSkin` | `#C94277` | Magenta |
| `accentMuscle` | `#3B5E3B` | Moss |
| `accentHeart` | `#D94040` | Warm Red |
| `accentImmunity` | `#1A6B6A` | Dark Teal |
| `accentTerracotta` | `#B07156` | Terracotta |
| `warmStone` | `#8C7E6A` | Warm Stone |

### Functional Colors

| Token | Hex | Role | Same As |
|-------|-----|------|---------|
| `positive` | `#2E9E9E` | Success, checkmarks, active toggles, add actions | `accentLongevity` |
| `negative` | `#D94040` | Errors, warnings, destructive actions | `accentHeart` |
| `info` | `#4A8FC2` | Links, dosage data, active page dots | `accentClarity` |

### Usage Rules

- All colors are initialized via `Color(hex:)` using sRGB color space.
- Background hierarchy creates depth through subtle warmth shifts, not opacity or shadows alone.
- Accent colors appear at reduced opacity for fills/backgrounds (typically `0.12`–`0.15`) with full opacity for text/icons on those fills.
- The spectrum gradient is always ordered Sleep → Energy → Clarity → Mood → Gut, leading to trailing.

---

## Typography

### Font Family

**Geist** (by Vercel) — bundled in `Resources/Fonts/`. Four subfamilies:

| Family | Weights Available |
|--------|-------------------|
| Geist | Light, Regular, Medium, SemiBold |
| GeistMono | Regular, Medium |
| GeistPixel-Grid | Single weight (decorative pixel font) |

### Type Scale

#### Display & Headlines

| Token | Font | Size | Usage |
|-------|------|------|-------|
| `displayFont` | Geist-Light | 32pt | Hero display text |
| `headlineFont` | Geist-Light | 28pt | Primary screen headlines, onboarding headers |
| `titleFont` | Geist-SemiBold | 20pt | Section titles, card headers, premium titles |

#### Body & UI

| Token | Font | Size | Notes |
|-------|------|------|-------|
| `bodyFont` | Geist-Regular | 16pt | Paragraph text, card content |
| `ctaFont` | Geist-SemiBold | 16pt | Button labels; uses `tracking: 0.32` |
| `captionFont` | Geist-Regular | 13pt | Secondary text, disclaimers |

#### Section Labels

| Token | Font | Size | Notes |
|-------|------|------|-------|
| `sectionHeader` | Geist-SemiBold | 13pt | Always ALL-CAPS with `tracking: 1.5` |

#### Monospace (Data & Labels)

| Token | Font | Size | Notes |
|-------|------|------|-------|
| `dataMono` | GeistMono-Medium | 16pt | Dosages, numeric values, scores |
| `labelMono` | GeistMono-Regular | 11pt | Timing badges, category chips; `tracking: 1.2` |
| `smallMono` | GeistMono-Regular | 10pt | Ring center labels, tiny annotations; `tracking: 1.2` |

#### Pixel / Icon Font

| Token | Font | Size | Usage |
|-------|------|------|-------|
| `pixelIconLarge` | GeistPixel-Grid | 22pt | Large decorative icons |
| `pixelIconFont` | GeistPixel-Grid | 18pt | Supplement abbreviation icons (1–2 chars) |
| `pixelIconSmall` | GeistPixel-Grid | 14pt | Supplement icons (3 chars) |

Additional sizes: 11pt for 4+ character abbreviations, 28pt for PillboxLid etchings, 40pt (center) / 32pt (off-center) for ScrollWheelPicker.

### HeadlineText Component

SwiftUI doesn't support precise line heights natively. `HeadlineText` wraps a `UILabel` to enforce exact line spacing — default is 28pt font with 32pt line height (1.14× ratio). Used for all onboarding and paywall headline paragraphs.

### Type Patterns

```
Section header:     "SECTION NAME" — sectionHeader, tracking 1.5, textSecondary, ALL-CAPS
Card title:         "Supplement Name" — bodyFont .semibold, textPrimary
Card subtitle:      "Description" — captionFont, textSecondary
Badge label:        "MORNING" — labelMono, tracking 1.2, ALL-CAPS
Data value:         "500 mg" — dataMono, info color
```

---

## Spacing

A 9-step spacing scale based on multiples of 4, with a 2pt micro unit.

| Token | Value | Common Usage |
|-------|-------|--------------|
| `spacing2` | 2pt | Micro gaps, icon-to-text tightening |
| `spacing4` | 4pt | Inline element gaps, badge internal padding |
| `spacing8` | 8pt | Between small siblings, chip horizontal padding |
| `spacing12` | 12pt | Within-card element spacing |
| `spacing16` | 16pt | Card padding, horizontal page margins |
| `spacing20` | 20pt | Medium vertical gaps |
| `spacing24` | 24pt | Section spacing, vertical padding, onboarding margins |
| `spacing32` | 32pt | Section separators, bottom padding |
| `spacing40` | 40pt | Large vertical gaps |
| `spacing48` | 48pt | Bottom CTA safe area padding |

### Layout Rules

- **Page horizontal margin:** `spacing16` (most screens), `spacing24` (onboarding/paywall)
- **Between cards:** `spacing24`
- **Within cards:** `spacing12`–`spacing16`
- **Between small siblings:** `spacing4`–`spacing8`
- **Page bottom padding:** `spacing32`–`spacing48`

---

## Corner Radii

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 8pt | Chips, icon backgrounds, checkboxes |
| `radiusMedium` | 12pt | Cards, most buttons, input fields |
| `radiusLarge` | 16pt | Pillbox containers, pricing cards, major panels |
| `radiusFull` | 999pt | Pills, capsule badges, toggles, removable chips |

---

## Shadows & Depth

Depth is conveyed through background color hierarchy first, with shadows used sparingly:

| Context | Shadow Definition |
|---------|-------------------|
| Standard card (`cardStyle()`) | `black.opacity(0.06), radius: 6, y: 2` |
| Pillbox container | `black.opacity(0.06), radius: 8, y: 4` |
| Pillbox lid | `black.opacity(0.06), radius: 12, y: 2` |
| Undo toast | `black.opacity(0.3), radius: 12, y: 4` |

All shadows are black at very low opacity (0.06 standard, 0.3 for floating overlays). They cast downward (positive y) to simulate overhead lighting.

### Inner Shadows

`WellbeingScoreRing` uses an inner shadow on the background ring track: `black.opacity(0.08)`, blurred 8pt, created via a mask overlay technique.

### Glow Effects

Rather than traditional shadows, components use **glow** for emphasis:
- Slider fill: dimension color at `opacity(0.3)`, blurred 6pt behind the fill bar
- Slider thumb (active): dimension color at `opacity(0.5)`, shadow radius visible while dragging
- Pillbox compartment (taken): radial gradient of accent color, opacity pulsed on interaction
- Score ring segments: dimension color at `opacity(0.35)`, `lineWidth+4`, blurred 8pt behind each arc
- Core supplement card: radial gradient from `accent.opacity(0.04)` at the leading edge

---

## Texture

### Film Grain

A subtle grain overlay (`GrainOverlay`) is applied to backgrounds to add organic warmth:
- Implemented via a Metal shader (`GrainShader.metal`) using hash-based noise
- Intensity: 0.06, blend mode: `.multiply`, opacity: 0.04
- Static (no animation), adds/subtracts luminance equally around midpoint
- Visually imperceptible at a glance but prevents surfaces from feeling digitally flat

---

## Buttons

### CTAButton (Primary Action)

Full-width, 52pt height, `radiusMedium` corners, `ctaFont` (Geist-SemiBold 16pt, tracking 0.32).

| Style | Background | Text | Border |
|-------|-----------|------|--------|
| `.primary` | `textPrimary` | `bgDeepest` | None |
| `.secondary` | Clear | `textPrimary` | 1.5pt `textPrimary` |
| `.ghost` | Clear | `textSecondary` | None |

**Spectrum border variant:** Adding `spectrumBorder: true` replaces the border with a 1.5pt gradient stroke cycling through the five spectrum colors. Used for key conversion CTAs ("Start My Free Trial", "Start Your First Check-in").

**Press style:** `CTAPressStyle` — scales to 0.97 on press with `easeInOut(duration: 0.15)`. Always triggers `HapticManager.impact(.light)`.

### CardPressStyle

For tappable cards: scales to 0.98 on press with `easeInOut(duration: 0.15)`.

### Icon Buttons

SF Symbols at 14–24pt in `textTertiary` or `textSecondary`, 28×28pt minimum hit area. No background. Example: kebab menu (`ellipsis` rotated 90°).

---

## Cards

### Standard Card (`cardStyle()` modifier)

The universal card appearance applied as a view modifier:

```
padding: spacing16
background: bgSurface
cornerRadius: radiusMedium
shadow: black 6%, radius 6, y 2
```

### Supplement Cards

Two variants, both `radiusMedium`:

**SupplementCardView** (current, expandable):
- `bgSurface` background, 1pt `borderDefault` stroke
- Left accent bar: 5pt wide for core tier (gradient if multiple goals), 3pt for targeted
- Core-tier glow: subtle radial gradient from accent color at leading edge
- Expands inline with `.opacity.combined(with: .move(edge: .top))` transition
- Kebab menu for contextual actions

**SupplementCard** (compact, checkbox-based):
- 24×24pt checkbox with `radiusSmall`
- Taken state: `positive.opacity(0.05)` bg, `positive.opacity(0.2)` border, strikethrough on name
- Checkmark enters with `.spring(duration: 0.3, bounce: 0.6)`

### Insight Cards

`bgSurface` background, `radiusMedium`, 1pt border in `dimensionColor.opacity(0.3)`. Type badge uses `labelMono` in dimension color on tinted pill. Unread dot: 8pt `info` circle.

### Discovery Cards

260pt wide, min 160pt tall. Category badge in accent color pill. Used in horizontal carousel with `.viewAligned` snap scrolling and page dots.

---

## Icons

### SF Symbols (Primary)

All UI icons use SF Symbols. Size conventions:

| Context | Size | Weight |
|---------|------|--------|
| Section decorative | 12–14pt | `.medium` |
| Action icons | 14–15pt | `.regular` |
| State indicators | 18–24pt | `.regular` |
| Paywall benefits | 16pt | `.medium` |
| Lock overlay | 24pt | `.regular` |
| Empty states | 48pt | `.regular` |

Common symbols: `checkmark`, `checkmark.circle.fill`, `plus.circle`, `xmark.circle.fill`, `ellipsis`, `chevron.right`, `chevron.down`, `lock.fill`, `leaf.fill`, `brain.head.profile`, `moon.stars.fill`, `fish.fill`, `sun.max.fill`, `moon.fill`, `flame.fill`, `bolt.fill`, `exclamationmark.triangle`.

### Pixel Text Icons (Supplement Abbreviations)

Supplement icons use GeistPixel-Grid to render chemical abbreviations (Mg, D3, L-T, B, Zn, C, Q10, etc.) as decorative pixel-art labels. Displayed inside tinted circles or rounded squares with `accentColor.opacity(0.12)` backgrounds.

Font size scales by character count: 18pt (1–2 chars), 14pt (3 chars), 11pt (4+ chars).

The `SupplementIconRegistry` maps each supplement to either a `pixelText` or `sfSymbol` variant.

---

## Interactions & Haptics

### Haptic Feedback

All haptics are centralized through `HapticManager`:

| Feedback | Trigger |
|----------|---------|
| `.impact(.light)` | CTA taps, slider release, supplement untake |
| `.impact(.medium)` | Supplement take, primary actions |
| `.selection()` | Slider detents (each integer step), picker item changes |
| `.notification(.success)` | All supplements taken for a timing group |
| `.notification(.warning)` | Validation errors |

### Press Effects

| Component | Scale | Duration |
|-----------|-------|----------|
| CTAButton | 0.97 | 0.15s easeInOut |
| Card (CardPressStyle) | 0.98 | 0.15s easeInOut |
| PillboxCompartment | 0.92 | 0.3s spring, bounce 0.5 |

### Toggles

`SupplementToggle`: 44×26pt capsule, `accentGut` when on / `bgElevated` when off, 22pt white thumb, `easeInOut(duration: 0.2)`.

### Sliders

`WellnessSlider`: 0–10 integer range, dimension-colored fill with glow, 24pt thumb that scales to 1.35× while dragging, 32pt bloom halo, haptic detents at each integer, 7-day average indicator above track.

### Pickers

`ScrollWheelPicker`: drum-roll style, center item at 40pt scaling down to 0.65× at edges with fading opacity, 5 visible items × 56pt, haptic on each value change.

---

## Animations

### Core Timing

| Pattern | Duration | Usage |
|---------|----------|-------|
| Standard appear | `easeOut, 0.4–0.6s` | Fade-in on screen load |
| Toggle / nav | `easeInOut, 0.2–0.35s` | State changes, tab transitions |
| Spring (bouncy) | `spring, 0.3s, bounce 0.4–0.6` | Checkmarks, compartment interactions |
| Spring (smooth) | `spring, response 0.5, damping 0.8` | CTA slide-up, hero entrances |
| Counter | `snappy, 0.15s` | Numeric value transitions (`.numericText()`) |
| Ring entrance | `easeOut, 0.8s` | WellbeingScoreRing draw |
| Compact ring | `easeOut, 0.6s, delay 0.2s` | CompactProgressRing draw |

### Screen Transitions

Onboarding and check-in flows use directional asymmetric transitions:

```
Forward:  insertion .move(.trailing) + .opacity  /  removal .move(.leading) + .opacity
Backward: insertion .move(.leading) + .opacity   /  removal .move(.trailing) + .opacity
Duration: 0.35s easeInOut
```

### Entrance Sequences

Complex screens (paywall, value props) use **staggered entrances** — elements appear sequentially via `DispatchQueue.asyncAfter` delays, typically spanning 2–3 seconds total.

### Ambient Motion

`GradientFlowBackground`: 6 large blurred circles (300–500pt) in spectrum colors, each drifting independently on different timers (5–8s, `easeInOut.repeatForever`). Creates a slow, organic breathing effect.

### Content Transitions

| Transition | Usage |
|------------|-------|
| `.opacity + .move(.top)` | Expanded card content |
| `.opacity + .move(.trailing)` | Insight card dismissal |
| `.scale + .opacity` | Supplement card insertion, checkmark badges |
| `.move(.bottom) + .opacity` | Toast entrance |
| `.symbolEffect(.replace)` | Icon state changes (plus → checkmark) |

### Accessibility

All ambient animations respect `accessibilityReduceMotion`:
- Gradient blobs freeze in place
- Entrance sequences collapse to near-instant (0.15s)
- Essential transitions (screen navigation) still play but are simplified

---

## Layout

### Screen Scaffold

Every screen follows this structure:

```swift
ZStack {
    DesignTokens.bgDeepest.ignoresSafeArea()  // warm canvas
    ScrollView {
        VStack(spacing: spacing24) {
            // content sections
        }
        .padding(.horizontal, spacing16)
        .padding(.bottom, spacing32)
    }
}
```

### Fixed Bottom CTA

Screens with a primary action pin it to the bottom with a gradient fade:

```
┌──────────────────────────────┐
│  Content (scrollable)        │
│                              │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← 32pt gradient fade (bgDeepest 0% → 100%)
│  [ Primary CTA Button ]     │  ← spacing16 horizontal, spacing32 bottom
└──────────────────────────────┘
```

### Section Headers

All-caps, tracked, in secondary color:

```
Text("SECTION NAME")
    .font(sectionHeader)        // Geist-SemiBold 13pt
    .tracking(1.5)
    .foregroundStyle(textSecondary)
```

### Grids

- **Pillbox:** 2-column `LazyVGrid`, `spacing8`, divided into AM/PM sections with a 1pt hinge divider
- **Goals:** Multi-column grid layouts using `LazyVGrid` with adaptive columns

### Carousels

Horizontal `ScrollView` with `.scrollTargetBehavior(.viewAligned)` snap scrolling. Page dots below: 6×6pt circles, `info` color when active, `textTertiary` when inactive.

---

## Badges & Chips

### Category Badge (mono label)

```
Text: labelMono (11pt), tracking 1.2, ALL-CAPS
Foreground: accentColor
Background: accentColor.opacity(0.15)
Shape: radiusFull capsule
Padding: spacing8 horizontal, spacing4 vertical
```

### Goal Chip (supplement card)

```
Text: smallMono (10pt), tracking 0.5
Foreground: goal.accentColor
Background: goal.accentColor.opacity(0.12)
Shape: radiusFull capsule
```

### Streak/Count Badge (pill with icon)

```
HStack: SF Symbol icon + count text
Background: accentColor.opacity(0.15)
Shape: radiusFull capsule
Padding: spacing8 horizontal, spacing4 vertical
```

### Removable Chip

```
Text: bodyFont, textPrimary
Close icon: xmark.circle.fill 18pt, textTertiary
Background: bgElevated
Border: 1pt borderDefault
Shape: radiusFull capsule
```

### Evidence Quality Chip

| Level | Color |
|-------|-------|
| Strong | `positive` |
| Moderate | `info` |
| Emerging | `accentEnergy` |

---

## Progress Indicators

### SpectrumBar

Horizontal bar showing progress 0–1:
- Track: `bgElevated` rounded rectangle
- Fill: `LinearGradient` of the 5 spectrum colors, leading → trailing
- Default height: 3pt
- Used as: onboarding progress, decorative dividers, loading indicators

### WellbeingScoreRing

Large circular ring (140pt default, 10pt stroke):
- 5 proportional arc segments, one per dimension
- Glow layers behind each segment
- Center: overall score + "OVERALL" label
- Below: 5 mini labels with individual scores

### CompactProgressRing

Small ring (48pt default, 4pt stroke):
- `AngularGradient` of spectrum colors
- Optional center label
- Used inline in cards and list rows

---

## Premium Gating

`LockedOverlay` modifier (`.lockedOverlay()`):
- Content blurred at 6pt when not subscribed
- Overlay: lock icon, title, subtitle, secondary CTA button
- Applied per-section, not full-screen

---

## Toast Notifications

`UndoToast`: bottom-anchored, auto-dismisses after 5 seconds.
- `bgElevated` background, `radiusMedium`, `borderDefault` border
- Strong shadow for floating emphasis
- "Undo" action in `info` color
- Entrance: `.move(.bottom) + .opacity`, 0.2s easeInOut

---

## Summary of Key Principles

1. **Tokens everywhere.** Never use raw `Color`, font names, spacing values, or corner radii. Everything flows from `DesignTokens`.
2. **Warm, not cool.** Backgrounds are cream, not gray. Text is olive, not pure black. The palette references biology, not tech.
3. **Light-mode only.** The entire system assumes warm white backgrounds. `.preferredColorScheme(.light)` is set at root.
4. **Depth through color, not shadow.** The three background tiers (`bgDeepest` → `bgSurface` → `bgElevated`) create hierarchy. Shadows are minimal and low-opacity.
5. **Glow over shadow for emphasis.** Active states use radial gradients and blurred accent colors rather than drop shadows.
6. **Monospace for data.** All numeric values, dosages, and data labels use GeistMono to feel clinical and precise.
7. **Spectrum as identity.** The five-color wellness gradient (purple → gold → blue → amber → chartreuse) is the app's visual signature, appearing in progress bars, rings, borders, and backgrounds.
8. **Haptics are part of the design.** Every interaction has a corresponding haptic: light for taps, medium for actions, selection for detents, notification for milestones.
9. **Respect reduce motion.** Ambient animations freeze, entrance sequences compress, but essential navigation transitions remain.
10. **Pixel font as brand element.** GeistPixel-Grid for supplement abbreviations gives the app a distinctive scientific-yet-playful identity.
