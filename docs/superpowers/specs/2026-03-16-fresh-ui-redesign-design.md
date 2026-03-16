# GoChange — Fresh UI Redesign (Layered Glass)

## Overview

Complete UI redesign of GoChange iOS app. Inspired by Bevel's design language — score-based dashboard, Liquid Glass effects, data-forward presentation — adapted with a warm cream palette, muted tangerine accent, and layered glassmorphism aesthetic.

**Scope**: View layer only. All data models, services, ViewModels, and business logic remain untouched. Widget extension and Watch app are out of scope.

## Design System

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `background` | `#EDE5D8` | App background — warm parchment |
| `surface` | `rgba(255,255,255,0.5)` | Glass cards (with backdrop blur) |
| `surfaceStrong` | `rgba(255,255,255,0.65)` | Hero/prominent glass cards, tab bar |
| `surfaceSubtle` | `rgba(255,255,255,0.32)` | Secondary glass cards |
| `primary` | `#D97B4A` | Muted Tangerine — buttons, active tab, accents |
| `primaryDark` | `#C46A3A` | Gradient end for primary buttons |
| `textPrimary` | `#2C2418` | Headlines, values, primary text |
| `textSecondary` | `#6B5D4F` | Labels, descriptions, muted text |
| `strain` | `#E8453C` | Strain metric — warm red |
| `recovery` | `#00B482` | Recovery metric — teal green |
| `sleep` | `#6E5AD2` | Sleep metric — indigo purple |
| `border` | `rgba(255,255,255,0.55)` | Glass card borders |
| `borderSubtle` | `rgba(255,255,255,0.4)` | Subtle glass borders |
| `divider` | `rgba(140,126,110,0.12)` | List dividers |
| `completedTint` | `rgba(0,180,130,0.06)` | Subtle green tint for completed sets |

### Ambient Blobs

Three positioned radial gradients behind content create depth and color atmosphere:
- **Blob 1** (primary): `#D97B4A`, top-right, 160px, opacity 0.35
- **Blob 2** (sleep): `#6E5AD2`, mid-left, 130px, opacity 0.20
- **Blob 3** (recovery): `#00B482`, bottom-right, 150px, opacity 0.18

Blobs are fixed behind content. They shift position subtly per-tab to keep the ambient feel fresh. On scroll, a subtle parallax effect moves blobs at 0.3x scroll speed.

**Performance**: Render blobs as pre-composited images using `.drawingGroup()` to avoid real-time blur recalculation on scroll. Use `Canvas` for the blur pass once, not per-frame.

**Accessibility**: Disable parallax when `accessibilityReduceMotion` is enabled — blobs remain static.

### Typography

Font: **Sora** (Google Fonts, OFL license).

**Bundling**: Download individual static Sora font files (Sora-Light.ttf, Sora-Regular.ttf, Sora-Medium.ttf, Sora-SemiBold.ttf, Sora-Bold.ttf, Sora-ExtraBold.ttf) from google/fonts GitHub. Add all files to the `gochange` target. Register each filename in Info.plist under `UIAppFonts`. OFL license — include LICENSE file in bundle.

**Fallback**: `.system(.body, design: .rounded)` with matched weights — only used if font fails to load.

**Dynamic Type**: All sizes below are base sizes at the default Dynamic Type setting. Use `@ScaledMetric` for key values (card padding, icon sizes). Text styles should use `.dynamicTypeSize(...)` ranges capped at `.xxxLarge` to prevent layout breakage.

| Style | Size | Weight | Tracking | Usage |
|---|---|---|---|---|
| `heroValue` | 54pt | 800 | -2pt | Energy Bank score |
| `screenTitle` | 28pt | 800 | -1pt | "Dashboard", "Workout", "Analytics" |
| `cardValue` | 26pt | 800 | -0.5pt | Score trio values, vital values |
| `cardValueSmall` | 22pt | 800 | -0.5pt | Secondary metric values |
| `body` | 15pt | 500 | 0 | Descriptions, insights, workout meta |
| `bodySmall` | 13pt | 500 | 0 | Status text, subtitles |
| `label` | 10pt | 700 | 1.5pt | Uppercase labels (STRAIN, RECOVERY) |
| `caption` | 11pt | 400 | 0 | Meta text, units, sub-values |
| `captionSmall` | 9pt | 400 | 0 | Strain labels, tiny meta |

### Glass Card Styles

**Standard Glass Card** (`.glassCard()`):
```
background: rgba(255, 255, 255, 0.5)
backdrop-filter: blur(20px)
border: 1px solid rgba(255, 255, 255, 0.55)
border-radius: 20pt
padding: 16pt
shadow: 0 4pt 20pt rgba(44, 36, 24, 0.05)
```

**Strong Glass Card** (`.glassCardStrong()`):
```
background: rgba(255, 255, 255, 0.65)
backdrop-filter: blur(24px)
border: 1px solid rgba(255, 255, 255, 0.7)
border-radius: 22pt
padding: 20pt
shadow: 0 8pt 32pt rgba(44, 36, 24, 0.08)
```

**Subtle Glass Card** (`.glassCardSubtle()`):
```
background: rgba(255, 255, 255, 0.32)
backdrop-filter: blur(14px)
border: 1px solid rgba(255, 255, 255, 0.4)
border-radius: 16pt
padding: 14pt
```

### Layout Constants

| Token | Value |
|---|---|
| `horizontalPadding` | 16pt |
| `cardSpacing` | 10pt |
| `sectionSpacing` | 16pt |
| `cornerRadiusLarge` | 22pt |
| `cornerRadiusMedium` | 20pt |
| `cornerRadiusSmall` | 16pt |
| `cornerRadiusTiny` | 12pt |
| `tabBarHeight` | 56pt |
| `tabBarBottomPadding` | 34pt (safe area) |
| `scrollBottomPadding` | 100pt (clears tab bar) |

### Buttons

**Primary Button** (Start Workout, CTA):
```
background: linear-gradient(135deg, primary, primaryDark)
border-radius: 14pt
padding: 14pt
font: Sora 14pt / 700
color: white
shadow: 0 6pt 24pt rgba(217, 123, 74, 0.3)
```

**Secondary/Glass Button:**
```
background: rgba(255, 255, 255, 0.45)
backdrop-filter: blur(12px)
border: 1px solid rgba(255, 255, 255, 0.5)
border-radius: 14pt
```

### Icons
SF Symbols throughout. Icon colors match their metric color (strain=red, recovery=green, sleep=purple) or use `textSecondary` for neutral icons.

### Sparkline Charts
7-bar mini bar charts inside score cards showing last 7 days of data. Bars are 3pt wide, 2pt gap, rounded caps. Color matches the metric with progressive opacity (oldest bar = 15%, newest bar = 100%).

**Data source**: `AnalyticsService` already provides historical workout data. For recovery/sleep 7-day history, use `RecoveryService.fetchMetrics(for:)` across the last 7 days. For strain, derive from `WorkoutSession` completion data.

---

## Energy Bank

The Energy Bank is the hero metric on the home dashboard. It is a **composite readiness score** (0–100%) that combines existing metrics into a single at-a-glance number.

### Formula

```
energyBank = (recoveryWeight × recoveryScore)
           + (sleepWeight × sleepQualityPct)
           + (strainWeight × inverseStrain)

Where:
  recoveryScore   = RecoveryMetrics.recoveryScore (0–100, already a percentage)
  sleepQualityPct = SleepData.qualityPercentage (Int, 0–100, computed from quality * 100)
  inverseStrain   = max(0, 100 - strainScore)
                    // strainScore is HomeViewModel.strainScore (0–100)

Weights: recovery = 0.40, sleep = 0.35, strain = 0.25
```

### Status Labels

| Range | Label | Status Text |
|---|---|---|
| 80–100% | Fully Charged | "Your body is ready to push" |
| 60–79% | Moderate | "Pace your training today" |
| 40–59% | Depleted | "Consider lighter work" |
| 0–39% | Critical | "Rest recommended" |

### Computation
Computed in `HomeViewModel` using existing `HealthDataProviding` and `RecoveryProviding` protocols. No new service needed — it's a derived value from data already fetched for the score cards.

### Insight Badges
Simple rule-based text strings, not AI-generated. Examples:
- Sleep quality > 85%: "Great sleep boosted recovery +X%"
- HRV trending up over 3 days: "HRV trending up — good recovery"
- Strain > 15 yesterday: "High strain yesterday — allow extra recovery"
- No workout in 3+ days: "Ready for a workout — energy is high"

Logic lives in `HomeViewModel`. Returns an optional string; if nil, the badge is hidden.

---

## Navigation

### Tab Bar
Floating glass tab bar with 3 tabs:
- **Home** (house.fill) — Dashboard with scores, vitals, activity
- **Workout** (dumbbell.fill) — Training plan, workout selection
- **Analytics** (chart.xyaxis.line) — Performance trends and charts

```
Style: surfaceStrong glass
Border: 1px rgba(255,255,255,0.65)
Border-radius: 24pt
Shadow: 0 -4pt 20pt rgba(44,36,24,0.04)
Position: floating above content, 34pt from bottom safe area
```

Active tab: icon + label in `primary` color.
Inactive: icon + label in `textSecondary`.

### Active Workout
Full-screen sheet overlay. Swipe down to minimize → shows glass miniplayer above tab bar.

### Settings
Pushed via NavigationStack from dashboard header gear icon.

---

## Screen Designs

### 1. Home Dashboard (Tab 0)

**Scroll order (top to bottom):**

1. **Header**
   - Greeting: "Good morning" / "Good afternoon" / "Good evening" (textSecondary, bodySmall)
   - Title: "Dashboard" (textPrimary, screenTitle)
   - Settings button: glass circle (36pt), `gearshape` SF Symbol

2. **Energy Bank Hero** (glassCardStrong)
   - Left side:
     - "ENERGY BANK" (label style, primary color)
     - Score: heroValue with "%" in textSecondary
     - Status text (bodySmall, textSecondary)
     - Insight badge (if available): glassCardSubtle pill with sparkle icon + text, colored by relevant metric
   - Right side:
     - Circular progress ring (64pt diameter, 6pt stroke)
     - Track: primary at 12% opacity
     - Progress: primary color, round line cap, drop shadow

3. **Score Trio** (3 × glassCardSubtle, equal width, 8pt gap)
   Each card:
   - Colored dot (8pt) at top
   - Metric label (label style, in metric color)
   - Value (cardValue, textPrimary)
   - Status text (captionSmall, textSecondary)
   - 7-bar sparkline chart (last 7 days)
   - Tap → pushes Recovery Dashboard for that metric

4. **Next Workout Card** (glassCard)
   - "NEXT WORKOUT" (label style, textSecondary)
   - Row: gradient icon (44pt, `cornerRadiusTiny`) + workout name (body, 700 weight) + exercise count & duration (caption, textSecondary)
   - "Start Workout" primary button (full width)

5. **Vitals Grid** (2×2, glassCardSubtle, 8pt gap)
   Each card:
   - SF Symbol icon in metric color + label (label style, textSecondary)
   - Value (cardValue, textPrimary)
   - Unit + trend text (caption, textSecondary)
   - Cards: Resting HR (`heart.fill`), HRV (`waveform.path.ecg`), SpO2 (`checkmark.circle.fill`), VO2 Max (`flame.fill`)

6. **Recent Activity** (glassCard)
   - Header row: "RECENT ACTIVITY" (label) + "See All" (bodySmall, primary)
   - List of recent workout sessions (max 3):
     - Icon (40pt, `cornerRadiusTiny`, primary at 10% opacity bg, dumbbell SF Symbol in primary)
     - Workout name (body, 600 weight) + date/duration (caption, textSecondary)
     - Strain score on right (body, 700 weight, strain color) + "STRAIN" (captionSmall, textSecondary)
   - Dividers between items (divider color)

7. **Bottom spacing**: 100pt (clears tab bar)

**Empty state**: When no HealthKit data is available, score cards show "--" with "Connect Health" prompt. When no workouts exist, Recent Activity shows a glass card with "Complete your first workout to see activity here."

**Loading state**: Use existing `LoadState`. When `.loading`, show a centered `ProgressView` with glass pill background.

**Error state**: When `.error`, show a glassCard with `exclamationmark.triangle.fill` icon (strain color), error message (bodySmall, textSecondary), and a "Retry" primary button. Centers vertically in the scroll area.

---

### 2. Workout Tab (Tab 1)

**Scroll order:**

1. **Header**
   - Title: "Workout" (screenTitle)
   - Subtitle: "Your Training Plan" (bodySmall, textSecondary)
   - Exercise library button: glass circle (36pt), `books.vertical.fill`

2. **Weekly Progress Card** (glassCardStrong)
   - Left: "WEEKLY GOAL" (label, textSecondary) + "3/4" (cardValue, textPrimary) + motivational text (caption, textSecondary)
   - Right: Progress ring (80pt diameter) with primary gradient stroke
   - Below: 4 dot indicators (matches 4-day split). Completed = filled primary circle with checkmark. Incomplete = outlined circle in textSecondary.

3. **Workout Day List** — vertical stack
   Each **WorkoutDayCard** (glassCard):
   - Left: gradient icon badge (48pt, `cornerRadiusTiny`, using workout's `colorHex` for gradient)
   - Workout name (body, 700 weight, textPrimary)
   - "DONE" badge if completed today: capsule shape, recovery color bg at 15% opacity, "DONE" text in recovery color, captionSmall, 600 weight
   - "Day X" + exercise count (caption, textSecondary)
   - Chevron right (textSecondary)
   - Context menu: Edit, Delete
   - Tap → pushes Workout Preview

4. **Add Workout Card** (glassCardSubtle, dashed border overlay)
   - `plus.circle.fill` (textSecondary) + "Add Workout" (body, textSecondary)

5. **Exercise Library Row** (glassCard)
   - `books.vertical.fill` icon (primary) + "Exercise Library" (body, textPrimary) + chevron

---

### 3. Workout Preview (pushed from Workout tab)

1. **Header Card** (glassCardStrong)
   - Gradient icon (64pt) + "DAY X" (label, textSecondary) + workout name (screenTitle, textPrimary)
   - Glass divider
   - Stats row: exercise count | total sets | est. duration (each: cardValueSmall above, caption below)
   - Vertical dividers (1pt, borderSubtle) between stats

2. **Exercise List** (glassCard)
   - "EXERCISES" (label, textSecondary) + count badge (captionSmall, primary, glass pill)
   - Each exercise row:
     - Numbered badge (36pt circle, gradient bg matching workout colorHex)
     - Exercise name (body, 600 weight) + muscle group glass tag (captionSmall, textSecondary) + "sets × reps" (caption, textSecondary)
     - Chevron (textSecondary)
   - Glass dividers between rows

3. **Sticky Start Button** (bottom)
   - Primary gradient button (full width)
   - Gradient fade above: background color → transparent, 60pt height
   - 120pt scroll bottom padding

---

### 4. Active Workout (full-screen sheet)

1. **Sheet Header** (glassCardStrong, top safe area)
   - Left: elapsed time in glass pill (monospaced digits, bodySmall)
   - Center: workout name uppercase (bodySmall, 700 weight, 1.5pt tracking)
   - Right: X close button (glass circle, 32pt, `xmark` SF Symbol)
   - Control row below:
     - Pause/Resume: glass button with `pause.fill` / `play.fill`
     - "Finish": glass button with recovery green tint, "Finish" text
   - Glass divider at bottom

2. **Exercise Pages** (swipeable TabView, `.tabViewStyle(.page)`)
   Each **ExerciseWorkoutCard**:
   - Progress dots (current exercise indicator)
   - Exercise name (screenTitle, textPrimary)
   - Glass badges row: muscle group tag + "3/5 sets" progress + notes indicator
   - Mini area chart (glassCardSubtle): last 5 sessions of this exercise volume. Area fill at 15% metric color, line stroke at full color. Uses SwiftUI Charts `AreaMark` + `LineMark`.
   - Progressive overload banner (if last session's weight exceeded): glass pill with `arrow.up.right` icon + "New PR potential" text in primary

3. **Set List Section**
   - Column headers: SET | WEIGHT | REPS | RIR (label style, textSecondary)
   - Each **SetInputCard** (glassCardSubtle):
     - Set number badge (20pt circle, textSecondary bg at 10%)
     - Weight input: glass text field, center-aligned, `bodySmall` monospaced
     - Reps input: glass text field, center-aligned
     - RIR menu: color-coded per existing `RIRLabels` mapping
     - Completion toggle: 24pt circle. Incomplete = stroke in textSecondary. Complete = filled primary with white checkmark
   - Completed sets: glassCardSubtle with `completedTint` added to background
   - "Add Set" glass button (secondary style, `plus` icon)

4. **Rest Timer** (appears between sets, overlays set list)
   - glassCardStrong, full width
   - Large countdown: 36pt monospaced digits, textPrimary
   - Circular progress ring (100pt diameter, 6pt stroke, primary)
   - Controls row: "Skip" glass button + "+30s" glass button
   - Triggers existing `RestTimerActivityManager` for Live Activity

---

### 5. Workout Miniplayer (when minimized)

Compact glass bar above the tab bar:
```
Style: glassCardStrong
Border-radius: 20pt top corners, 0 bottom
Height: ~64pt
```

Contents (single row):
- Workout day badge: capsule, primary bg, white text (captionSmall, 700)
- Current exercise name (bodySmall, 600 weight, textPrimary)
- Heart rate pill (if available): glass capsule with red tint, `heart.fill` + BPM value
- Elapsed time (bodySmall, monospaced, textSecondary)
- Pause/Resume button: primary glass circle (40pt)
- Tap anywhere → expands to full active workout sheet

---

### 6. Analytics Tab (Tab 2)

1. **Header**
   - Title: "Analytics" (screenTitle)
   - Period selector: glass segmented control (Week / Month / 3 Months)

2. **Hero Stats Row** (3 × glassCardSubtle pills, equal width, 8pt gap)
   Each: icon in metric color + value (cardValueSmall, 700 weight) + label (captionSmall, textSecondary)
   - Total workouts (primary icon)
   - Avg strain (strain icon)
   - Avg recovery (recovery icon)

3. **Section Segmented Control** (glassCard, 3 segments)
   - Strength | Cardio | Recovery
   - Active segment: primary bg, white text
   - Inactive: transparent, textSecondary

4. **Chart Cards** (glassCard containers)
   All charts use SwiftUI Charts framework:
   - Glass card wrapping
   - Area fills at 15% metric color opacity
   - Line strokes in full metric color, 2pt
   - Grid lines at 8% opacity textSecondary
   - Axis labels: captionSmall, textSecondary

   **Strength section:**
   - Volume Trends (AreaMark + LineMark, primary color, 7/30/90 day data)
   - 1RM Progress (LineMark per exercise, multi-colored)
   - Muscle Group Balance (horizontal BarMark, primary gradient)
   - Personal Records (glassCard with `trophy.fill` in gold, list of PRs)

   **Cardio section:**
   - Heart Rate Zones (stacked BarMark, zone colors)
   - Training Density (calendar heatmap using `RuleMark` grid)

   **Recovery section:**
   - Recovery Trend (AreaMark, recovery green)
   - Sleep Quality (AreaMark, sleep purple)
   - Strain vs Recovery (PointMark scatter, dual colors)

---

### 7. Metric Detail View (pushed from score cards)

Tapping any score card (Strain / Recovery / Sleep) on the home dashboard pushes this view. Replaces the current `RecoveryDashboardView`, `StrainDetailView`, and `SleepView`.

1. **Large Ring** (glassCardStrong)
   - 160pt circular progress ring (8pt stroke)
   - Score percentage centered (heroValue)
   - Status label below (bodySmall, textSecondary)
   - Ring + text color matches the metric

2. **Key Metrics Grid** (2×2 glassCardSubtle)
   - **Recovery detail**: Sleep score, HRV, RHR, Yesterday's Strain
   - **Sleep detail**: Total Duration, Deep Sleep, REM Sleep, Sleep Efficiency
   - **Strain detail**: Active Calories, Workout Count, Peak HR, Total Duration

3. **7-Day Trend** (glassCard)
   - AreaMark + LineMark chart in metric color
   - X-axis: day labels. Y-axis: metric values.

4. **Insights List** (glassCard)
   - Rule-based insight strings (same logic as Energy Bank badges, extended per metric)
   - Each insight: glassCardSubtle pill with icon + text

---

### 8. Settings (pushed from header)

1. **Section Groups** — each section is a glassCard containing navigation rows:
   - SF Symbol icon (colored circle bg at 15% opacity) + label (body, textPrimary) + chevron
   - Glass dividers between rows

   Sections:
   - **GENERAL**: Account (`person.fill`), Customization (`paintbrush.fill`), Notifications (`bell.fill`)
   - **DATA**: Data Sources (`heart.text.square.fill`), Data Management (`externaldrive.fill`)
   - **ABOUT**: Version (`info.circle.fill`), Source Code (`chevron.left.forwardslash.chevron.right`)

2. **Background**: `#EDE5D8` with ambient blobs

3. **Sub-settings screens** (Account, Customization, Notifications, Data Sources, Data Management, Reminders): Use same glass card styling. Each form field uses glassCardSubtle for input containers. Toggle switches use primary color when on.

---

### 9. Session Detail (pushed from activity timeline)

1. **Header Card** (glassCardStrong)
   - Workout name (screenTitle, textPrimary) + date (bodySmall, textSecondary)
   - Duration + Total Volume + Total Sets as glass pill badges

2. **Health Summary** (glassCard)
   - 2×2 grid: Avg HR, Max HR, Calories, Strain score (each: label + cardValueSmall)
   - HR during session chart (if HR samples available from `HealthKitService.getWorkoutHeartRateSamples()`): LineMark in strain color, glassCardSubtle container

3. **Exercise Log List** — one glassCard per exercise logged
   - Exercise name (body, 700 weight) + muscle group glass tag
   - Set table rows (glassCardSubtle): set# | weight | reps | RIR
   - Volume summary per exercise (caption, textSecondary)

---

### 10. Additional Screens (generic glass styling)

These screens exist in the codebase and get the same glass treatment without individual spec:

| Screen | Glass Pattern |
|---|---|
| `EditWorkoutDayView` | glassCard form fields, primary button to save |
| `ExerciseSelectionSheet` | Search bar in glassCardSubtle, exercise list in glassCard rows |
| `ReorderExercisesSheet` | Drag-handle rows in glassCardSubtle |
| `ExerciseDetailView` | glassCardStrong header, glassCard info sections |
| `ExerciseLibraryView` | Search bar + sectioned list, glassCard rows |
| `RestDayLoggingView` | glassCard form with date picker, text fields |
| `RestDayListView` | glassCard list rows with date + type + notes |
| `WeightInputSheet` | Centered number pad, glassCardStrong container |
| `RepsDurationInputSheet` | Same pattern as WeightInputSheet |
| `RPEInputSheet` | Slider or segmented control in glassCard |
| `PreviousWorkoutHistorySheet` | glassCard list of past sessions with set data |
| `MetricExplanationSheet` | glassCard with icon + title + body text |
| `WorkoutSummaryView` | glassCardStrong hero stats + glassCard exercise summary |
| `WatchSyncDebugView` | Unstyled debug — no redesign needed |

**Pattern**: All sheet presentations use `.presentationDetents([.medium, .large])` with glass background. All form inputs use glassCardSubtle with centered text.

---

## Motion & Animation

### Scroll Effects
- Ambient blobs: parallax at 0.3x scroll speed (disabled when `accessibilityReduceMotion` is true)
- Cards: subtle fade-in as they enter viewport (opacity 0→1, translateY 8→0, spring animation with response 0.5, dampingFraction 0.8)
- Score trio sparklines: bars animate height on appear (staggered, 50ms delay each bar)

### Transitions
- Tab switching: cross-dissolve, 0.25s spring
- Push navigation: default iOS slide
- Active workout sheet: spring-driven present/dismiss
- Miniplayer: slide up/down with spring

### Micro-interactions
- Score card tap: scale to 0.97 + light haptic (`UIImpactFeedbackGenerator(.light)`)
- Button press: scale 0.96, 0.1s ease-out
- Completion toggle: checkmark draws in with spring animation
- Progress rings: animate stroke on appear (1s, ease-out)
- Rest timer: pulse animation on ring when time < 10s

### Accessibility
- All animations respect `@Environment(\.accessibilityReduceMotion)`
- When reduce motion is on: no parallax, no card fade-in, instant transitions
- Progress rings still animate but with reduced duration (0.3s)

---

## Implementation Notes

### SwiftUI Glass Modifier Example

```swift
struct GlassCardModifier: ViewModifier {
    enum Style { case standard, strong, subtle }
    let style: Style

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: shadowColor, radius: shadowRadius, y: shadowY)
    }

    // Properties switch on style for specific values
}

extension View {
    func glassCard() -> some View { modifier(GlassCardModifier(style: .standard)) }
    func glassCardStrong() -> some View { modifier(GlassCardModifier(style: .strong)) }
    func glassCardSubtle() -> some View { modifier(GlassCardModifier(style: .subtle)) }
}
```

### Ambient Background Modifier

```swift
struct AmbientBackground: ViewModifier {
    let scrollOffset: CGFloat
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        ZStack {
            Color(hex: "#EDE5D8").ignoresSafeArea()

            // Pre-composited blobs
            Group {
                Circle().fill(Color(hex: "#D97B4A")).frame(width: 160).blur(radius: 50).opacity(0.35)
                    .offset(x: 80, y: reduceMotion ? -40 : -40 + scrollOffset * 0.3)
                Circle().fill(Color(hex: "#6E5AD2")).frame(width: 130).blur(radius: 50).opacity(0.20)
                    .offset(x: -60, y: reduceMotion ? 300 : 300 + scrollOffset * 0.3)
                Circle().fill(Color(hex: "#00B482")).frame(width: 150).blur(radius: 50).opacity(0.18)
                    .offset(x: 70, y: reduceMotion ? 500 : 500 + scrollOffset * 0.3)
            }
            .drawingGroup() // Rasterize for performance

            content
        }
    }
}
```

### Sora Font Registration

```swift
// In AppFonts (Theme.swift)
static func sora(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    let name: String
    switch weight {
    case .light: name = "Sora-Light"
    case .regular: name = "Sora-Regular"
    case .medium: name = "Sora-Medium"
    case .semibold: name = "Sora-SemiBold"
    case .bold: name = "Sora-Bold"
    case .heavy, .black: name = "Sora-ExtraBold"
    default: name = "Sora-Regular"
    }
    return .custom(name, size: size)
}
```

### What Changes from Current Codebase

**Theme.swift** — Complete rewrite:
- New `AppColors` with all glass tokens
- New `AppFonts` with Sora helpers + named styles
- Updated `AppLayout` with new constants
- New `GlassStyle` enum (strong/standard/subtle)

**ViewModifiers.swift** — Replace:
- `.cardStyle()` → `.glassCard()`
- `.subCardStyle()` → `.glassCardSubtle()`
- New `.glassCardStrong()`
- New `.ambientBackground()` modifier

**MainTabView** — Redesign:
- Custom floating glass tab bar (replace `.ultraThinMaterial` capsule)
- Ambient background at the root level

**JournalView** → Home Dashboard:
- Reorder sections: Energy Bank → Score Trio → Next Workout → Vitals → Activity
- Add Energy Bank computation
- Add sparklines to score cards
- Add insight badges

**WorkoutDaySelectionView** — Restyle:
- Glass cards for workout days
- Glass weekly progress card
- 4-dot progress indicator (not 5)

**PerformanceAnalyticsView** → Analytics Tab:
- Rename tab label to "Analytics"
- Glass chart containers
- Glass segmented controls
- Updated chart colors

**ActiveWorkoutView** — Restyle:
- Glass set input cards
- Glass header and controls
- Glass rest timer overlay

**WorkoutMiniplayer** — Restyle:
- Glass bar design
- Updated layout and colors

**RecoveryDashboardView / StrainDetailView / SleepView** → Unified Metric Detail View:
- Consolidate into one parameterized view
- Glass card styling throughout

**All remaining views** — Apply glass styling per the generic pattern table above.

### What Stays the Same
- All data models (SwiftData) — untouched
- All services — untouched
- All ViewModels — untouched (except HomeViewModel gets energyBank computation + insight logic)
- Widget extension — out of scope
- Watch app — out of scope
- FSCalendar dependency — retained, restyled with glass colors if used in analytics heatmap

### Contrast & Accessibility Notes
- `textPrimary` (#2C2418) on glass surfaces over #EDE5D8: effective background ~#F3EEE6, contrast ratio ~10:1 (passes AAA)
- `textSecondary` (#6B5D4F) on same: contrast ratio ~4.8:1 (passes WCAG AA for all text sizes)
- All interactive elements have minimum 44pt tap targets
- VoiceOver: sparkline charts get `accessibilityLabel` summarizing the trend (e.g., "Recovery trending up over 7 days, current 87%")
