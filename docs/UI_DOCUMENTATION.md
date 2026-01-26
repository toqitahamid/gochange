# GoChange UI Documentation

**Date:** January 26, 2026  
**Version:** 1.0  
**Platform:** iOS 17.0+ (iPhone), watchOS 10.0+ (Apple Watch)

---

## Table of Contents

1. [Design System](#design-system)
2. [Main Screens](#main-screens)
3. [Component Library](#component-library)
4. [Visual Specifications](#visual-specifications)
5. [User Flows](#user-flows)

---

## Design System

### Color Palette

#### Primary Colors
- **Background**: `#F5F5F7` (Light gray - main app background)
- **Card Background**: `#FFFFFF` (White - all cards)
- **Primary Accent**: `#5B7FFF` / `#7B92FF` (Blue - primary actions)
- **Slate Accent**: `#2D3748` (Dark slate - unified workout accent)

#### Semantic Colors
- **Success**: `#00C896` (Mint green - completion, PRs)
- **Warning**: `#F59E0B` (Amber - high RPE, fatigue)
- **Error**: `#EF4444` (Crimson - failure, errors)
- **Recovery**: `#00D4AA` (Teal - recovery metrics)
- **Sleep**: `#7B68EE` (Purple - sleep metrics)

#### Workout Day Colors
- **Push**: `#7CB9A8` (Teal)
- **Pull**: `#9B59B6` (Purple)
- **Legs**: `#5DADE2` (Light Blue)
- **Fullbody**: `#85C1E9` (Sky Blue)

#### Text Colors
- **Primary Text**: `#111827` (Rich Black)
- **Secondary Text**: `#6B7280` (Metallic Gray)
- **Tertiary Text**: `#9CA3AF` (Light Gray)

### Typography

#### Font Hierarchy
- **Large Title**: 34pt Bold Rounded (screen headers)
- **Title**: 28pt Bold Rounded (card titles)
- **Headline**: 24pt Semibold Rounded (metric values)
- **Body**: 16-18pt Semibold/Medium (content)
- **Caption**: 12-13pt Medium (labels, metadata)
- **Small Caption**: 10-11pt Regular (tracking labels)

#### Font Weights
- **Black**: Large numbers, key metrics
- **Bold**: Headers, important values
- **Semibold**: Body text, card titles
- **Medium**: Labels, secondary info
- **Regular**: Captions, metadata

### Spacing System

- **Screen Padding**: 20pt (horizontal edges)
- **Card Padding**: 16-24pt (internal card spacing)
- **Card Spacing**: 12-20pt (between cards)
- **Section Spacing**: 20pt (major sections)
- **Component Spacing**: 8-12pt (within components)

### Card Styling

**Standard Card Style:**
```swift
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 24))
.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
.overlay(
    RoundedRectangle(cornerRadius: 24)
        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
)
```

**Key Properties:**
- Corner radius: `24pt`
- Shadow: `color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4`
- Border: `Color.gray.opacity(0.1), lineWidth: 1`
- Background: `Color.white`

### Effects

#### Glassmorphism
- Material: `.ultraThinMaterial` (Watch app)
- White cards with subtle transparency (iOS)
- Blur effects for depth

#### Shadows
- **Cards**: `radius: 10-15, x: 0, y: 4-8, opacity: 0.05-0.08`
- **Buttons**: `radius: 20, x: 0, y: 8, opacity: 0.35` (accent color)

---

## Main Screens

### 1. Home Tab (JournalView)

**Purpose:** Primary dashboard showing recovery, sleep, strain, and activity timeline

#### Layout Structure
```
┌─────────────────────────────────┐
│ Header (Date + Greeting)         │
│ Settings Button (User Initials)  │
├─────────────────────────────────┤
│ Next Workout Pill                │
├─────────────────────────────────┤
│ Score Cards Grid (2x2)           │
│ ┌──────────┐ ┌──────────┐       │
│ │ Recovery │ │  Energy  │       │
│ │   Ring   │ │   Bank   │       │
│ └──────────┘ └──────────┘       │
│ ┌──────────────────────────┐    │
│ │      Strain Progress     │    │
│ └──────────────────────────┘    │
│ ┌──────────────────────────┐    │
│ │      Sleep Score         │    │
│ └──────────────────────────┘    │
├─────────────────────────────────┤
│ Vitals Grid                      │
│ HRV | RHR | RR | SpO2 | VO2 Max │
├─────────────────────────────────┤
│ Daily Insight Card               │
│ (Sparkles icon + message)        │
├─────────────────────────────────┤
│ Activity Timeline                │
│ (Recent workouts list)           │
└─────────────────────────────────┘
```

#### Key Components

**Recovery Ring Card:**
- Circular progress ring (0-100%)
- Score display in center
- Status label below (Prime/Ready/Steady/Recovering/Low)
- Color: Green (≥80), Amber (≥50), Red (<50)
- Size: 80x80pt ring

**Energy Bank Card:**
- Battery icon visualization
- Fill level (0-100%)
- Status text (Full/Good/Steady/Low/Depleted)
- Gradient fill based on level

**Strain Progress Card:**
- Current value / 21 scale
- Progress bar with target zone (10-14)
- Status (Optimal/Overreaching/Restoring)
- Flame icon

**Sleep Score Card:**
- Sleep duration (hours + minutes)
- Score percentage
- Stage breakdown bar (Light/Deep/REM)
- Moon icon

**Vitals Grid:**
- 5 metrics in horizontal grid
- HRV, Resting HR, Respiratory Rate, SpO2, VO2 Max
- Each shows value + label
- Tap to view details

**Daily Insight Card:**
- Sparkles icon (50x50pt circle)
- "Daily Insight" label
- Personalized message based on recovery
- White card with standard styling

**Activity Timeline:**
- List of recent workout sessions
- Workout icon, name, date
- Set count badges
- Tap to view session details

---

### 2. Workout Tab (WorkoutDaySelectionView)

**Purpose:** Weekly workout planning and selection

#### Layout Structure
```
┌─────────────────────────────────┐
│ Header                          │
│ "Workout" + Analytics Button    │
├─────────────────────────────────┤
│ Weekly Progress Header          │
│ ┌──────────────────────────┐   │
│ │ WEEKLY GOAL              │   │
│ │ 3 / 4                    │   │
│ │ [Progress Message]        │   │
│ │                          │   │
│ │    [Circular Progress]   │   │
│ └──────────────────────────┘   │
│ Day Indicators                  │
│ D1─●─D2─●─D3─○─D4              │
│ (Connected timeline)           │
├─────────────────────────────────┤
│ Workout Cards                   │
│ ┌──────────────────────────┐   │
│ │ [Icon] DAY 1 [DONE]      │   │
│ │ Push                     │   │
│ │ 🏋️ 5 Exercises          │   │
│ └──────────────────────────┘   │
│ ... (one per workout day)       │
├─────────────────────────────────┤
│ Add Workout Card                │
│ (Glass style with + icon)       │
├─────────────────────────────────┤
│ Exercise Library Card           │
└─────────────────────────────────┘
```

#### Key Components

**Weekly Progress Header:**
- Large circular progress indicator (88x88pt)
- Workout count vs weekly goal (e.g., "3 / 4")
- Percentage display in center
- Progress message (Goal Complete!/Almost there!/Keep pushing!/Let's get started!)
- Color changes: Green (100%), Blue (≥70%), Orange (≥40%), Gray (<40%)
- Day indicators below with connected timeline
- Checkmarks for completed days

**Workout Day Card:**
- Left: Icon (64x64pt rounded square)
  - Green gradient if completed this week
  - Slate gradient if not completed
  - Checkmark icon if done, workout icon if not
- Center: 
  - "DAY X" label (bold, uppercase, tracking)
  - "DONE" badge if completed (green capsule)
  - Workout name (18pt semibold rounded)
  - Exercise count label
- Right: Chevron indicator
- Standard white card styling

**Add Workout Card:**
- Glassmorphic style (.ultraThinMaterial)
- Plus icon in circle (64x64pt)
- "Add Workout" title
- "Create a new workout day" subtitle
- Subtle border and shadow

**Exercise Library Card:**
- Books icon (64x64pt)
- "Exercise Library" title
- "Browse and manage exercises" subtitle
- Standard card styling

---

### 3. Workout Preview View

**Purpose:** Display workout details before starting

#### Layout Structure
```
┌─────────────────────────────────┐
│ Navigation Bar                  │
│ [Back] Workout Name [Edit]      │
├─────────────────────────────────┤
│ Workout Header Card             │
│ ┌──────────────────────────┐   │
│ │ [Icon] DAY X             │   │
│ │ Workout Name             │   │
│ ├──────────────────────────┤   │
│ │ Exercises | Sets | Est.  │   │
│ └──────────────────────────┘   │
├─────────────────────────────────┤
│ EXERCISES Section               │
│ ┌──────────────────────────┐   │
│ │ [1] Exercise Name        │   │
│ │     Muscle • 3 × 12      │   │
│ ├──────────────────────────┤   │
│ │ [2] Exercise Name        │   │
│ │     Muscle • 3 × 10      │   │
│ │ ...                      │   │
│ └──────────────────────────┘   │
├─────────────────────────────────┤
│ [Sticky Bottom Button]          │
│ Start Workout (Gradient)        │
└─────────────────────────────────┘
```

#### Key Components

**Workout Header Card:**
- Icon (64x64pt) with gradient background
- "DAY X" label (uppercase, tracking)
- Workout name (24pt bold rounded)
- Stats row: Exercises count | Sets count | Estimated minutes
- Divider between header and stats
- White card with standard styling

**Exercise Preview Row:**
- Number badge (44x44pt rounded square)
  - Gradient background (slate colors)
  - Number in center
- Exercise info:
  - Exercise name (16pt semibold)
  - Muscle group + Sets × Reps (13pt)
- Chevron indicator
- Dividers between rows

**Sticky Start Button:**
- Fixed at bottom with gradient fade
- Gradient background (slate colors)
- Play icon + "Start Workout" text
- White text, rounded corners (16pt)
- Shadow with accent color
- White border overlay

---

### 4. Active Workout View

**Purpose:** Log sets and track workout progress

#### Layout Structure
```
┌─────────────────────────────────┐
│ Workout Header Bar              │
│ [Timer] WORKOUT NAME [X]        │
│ [Pause] [Finish Workout]        │
├─────────────────────────────────┤
│ TabView (Swipeable Exercises)   │
│ ┌──────────────────────────┐   │
│ │ Exercise 1 of 5          │   │
│ │                          │   │
│ │ Exercise Name            │   │
│ │ Muscle • 3 × 12         │   │
│ │                          │   │
│ │ SET | TARGET | WEIGHT   │   │
│ │     | REPS | RIR | ✓    │   │
│ │ ─────────────────────── │   │
│ │  1  |  12  | 135 | 10 | │   │
│ │  2  |  12  | 135 | 10 | │   │
│ │  3  |  12  | 140 | 10 | │   │
│ │                          │   │
│ │ [+ Add Set] [Notes]     │   │
│ └──────────────────────────┘   │
│ (Swipe left/right for next)    │
└─────────────────────────────────┘
```

#### Key Components

**Workout Header Bar:**
- Top row:
  - Elapsed timer (left, gray pill)
  - Workout name (center, uppercase, tracking)
  - Close button (right, X icon)
- Controls row:
  - Pause/Resume button (left, gray pill)
  - Finish Workout button (right, green capsule)
- Divider below

**Exercise Card:**
- Header:
  - Exercise name (17pt semibold)
  - Notes icon if notes exist
  - Muscle group + Sets × Reps
  - Completion indicator (X/Y sets)
  - Chevron (expandable)
- Expanded content:
  - Set headers row (SET | TARGET | WEIGHT | REPS | RIR)
  - Set rows with inputs:
    - Set number
    - Target reps (with previous data hint)
    - Weight input (text field)
    - Actual reps input (text field)
    - RIR picker (menu)
    - Complete checkbox (circle)
  - Bottom row:
    - Add Set button (plus icon)
    - Notes button

**Set Input Row:**
- Set number (bold, rounded)
- Target reps (with previous set hint in green)
- Weight input (text field, gray background)
- Reps input (text field, gray background)
- RIR menu (shows "-" if not set)
- Complete button (circle, green when checked)

**Workout Miniplayer:**
- Shown when workout is minimized
- Compact view at bottom
- Workout name, exercise name
- Timer, heart rate
- Expand button
- Pause/Resume controls

---

### 5. Fitness Tab (PerformanceAnalyticsView)

**Purpose:** Advanced fitness analytics and performance metrics

#### Layout Structure
```
┌─────────────────────────────────┐
│ Header                          │
│ "Fitness"                       │
│ [Time Range Picker]             │
├─────────────────────────────────┤
│ Daily Readiness Card            │
│ (Large score + progress bar)    │
├─────────────────────────────────┤
│ Sleep Debt | ACWR Cards         │
│ (Side by side)                  │
├─────────────────────────────────┤
│ Activity Heatmap                │
│ (GitHub-style grid)             │
├─────────────────────────────────┤
│ Activity Summary                │
│ Steps | Distance | Kcal | Time │
├─────────────────────────────────┤
│ Cardio Section                  │
│ Cardio Load Card                │
│ Cardio Focus | HRR Cards        │
├─────────────────────────────────┤
│ Strength Section                │
│ Strength Radar Chart            │
│ (3 metric views)                │
│ Strength Progression Card       │
├─────────────────────────────────┤
│ Strain Performance              │
│ Strain vs Recovery Chart        │
└─────────────────────────────────┘
```

#### Key Components

**Daily Readiness Card:**
- Large score (48pt bold rounded)
- Percentage symbol
- Governor message (right aligned)
- Progress bar (8pt height)
- Color: Green (≥80), Amber (≥40), Red (<40)
- Info button (top right)

**Sleep Debt Card:**
- Hours value (28pt bold)
- "hours" label
- Status message (right)
- Color: Green (<2h), Amber (<5h), Red (≥5h)

**ACWR Card:**
- Ratio value (28pt bold)
- Status message
- Range indicator with sweet spot zone (0.8-1.3)
- Current value dot
- Color: Green (sweet spot), Amber (undertraining), Red (high risk)

**Activity Heatmap:**
- Two month grids side by side
- Day labels (S M T W T F S)
- Color intensity: Gray (0), Light green (1), Green (2), Blue (3+)
- Legend below

**Activity Summary Card:**
- Four metrics in 2x2 grid:
  - Steps (large number)
  - Distance (km)
  - Active Energy (kcal)
  - Exercise Time (min)
- Divider between rows

**Cardio Load Card:**
- Average load value (32pt bold)
- Status text
- Mini chart (120x60pt)
- Area + line chart

**Cardio Focus Card:**
- Status text
- Percentage
- Progress bar with indicator dot

**HRR Card:**
- Resting heart rate (bpm)
- Status text
- Short slider track with knob

**Strength Radar Chart:**
- 6-axis radar (Chest, Back, Legs, Shoulders, Core, Arms)
- 3 metric views (Total Volume, Workout Frequency, Muscular Load)
- Menu to switch views
- Labels around perimeter
- Value display at each axis

**Strain vs Recovery Chart:**
- Dual-axis time series
- Recovery line (green, area fill)
- Strain line (orange)
- X-axis: Dates (dynamic spacing)
- Y-axis: 0-100 scale (stride by 25)
- Legend below
- Insight text
- Loading state support

---

## Component Library

### Score Cards

**RecoveryRingCard:**
- Circular progress ring
- Score in center (28pt bold rounded)
- Status label below
- Color-coded by score

**EnergyBankCard:**
- Battery icon visualization
- Fill level percentage
- Status text

**StrainProgressCard:**
- Current value / 21
- Progress bar with target zone
- Status indicator

**SleepScoreCard:**
- Duration display
- Score percentage
- Stage breakdown bar

### Buttons

**Primary Button:**
- Gradient background (accent colors)
- White text
- Rounded corners (16pt)
- Shadow with accent color
- White border overlay

**Secondary Button:**
- Gray background
- Primary text color
- Rounded corners (20pt)
- Subtle shadow

**Icon Button:**
- Circular (44x44pt)
- Background with opacity
- SF Symbol icon
- Tap target: 44pt minimum

### Inputs

**TextField:**
- Gray background (opacity 0.1)
- Rounded corners (8pt)
- Center alignment for numbers
- Decimal pad for weight
- Number pad for reps

**RIR Picker:**
- Menu style
- Shows "-" if not set
- Color-coded by value
- Options: 0-5

**Set Completion Checkbox:**
- Circle (28x28pt)
- Green when checked
- Checkmark icon
- Stroke when unchecked

### Progress Indicators

**Circular Progress:**
- Background ring (gray, opacity 0.1)
- Progress ring (gradient)
- Percentage in center
- Rotation: -90 degrees

**Linear Progress Bar:**
- Background capsule (gray, opacity 0.1)
- Fill capsule (gradient or solid)
- Height: 6-8pt
- Rounded ends

### Cards

**Standard Card:**
- White background
- Corner radius: 24pt
- Shadow: radius 10, y: 4, opacity 0.05
- Border: gray, opacity 0.1, width 1

**Glass Card:**
- Ultra thin material background
- Subtle border gradient
- Shadow: radius 12, y: 4, opacity 0.06

**Workout Day Card:**
- Icon on left (64x64pt)
- Info in center
- Chevron on right
- Standard card styling
- Green accent if completed

### Charts

**Radar Chart:**
- 6 axes (60 degrees apart)
- 4 concentric circles
- Data shape (filled + stroke)
- Labels at perimeter
- Values at axes

**Time Series Chart:**
- Dual Y-axis support
- Line marks with interpolation
- Area marks for fill
- Grid lines
- Dynamic X-axis spacing
- Y-axis stride by 25

**Heatmap Grid:**
- 7 columns (days of week)
- 5 rows (weeks)
- Color intensity by value
- Day labels above
- Month label

### Navigation

**Tab Bar:**
- 3 tabs: Home, Workout, Fitness
- Icons: house.fill, dumbbell.fill, chart.xyaxis.line
- Accent color tint
- Standard iOS styling

**Navigation Bar:**
- Inline title display
- Back button (standard)
- Trailing actions (icons/buttons)
- Transparent background

**Sheet:**
- Medium or large detents
- Drag indicator visible
- Standard iOS presentation

---

## Visual Specifications

### Screen Dimensions

**iPhone:**
- Standard sizes: iPhone 14 Pro (393×852pt)
- Safe area padding: Top 47pt, Bottom 34pt (with notch)
- Tab bar height: 49pt

**Apple Watch:**
- Series 10 46mm: Optimized layouts
- Circular display considerations
- Compact UI patterns

### Spacing Guidelines

- **Screen edges**: 20pt padding
- **Card spacing**: 20pt vertical
- **Card padding**: 16-24pt internal
- **Component spacing**: 8-12pt
- **Section spacing**: 20pt

### Typography Scale

- **Display**: 48pt (large numbers)
- **Title**: 34pt (screen headers)
- **Headline**: 24-28pt (card titles)
- **Body**: 16-18pt (content)
- **Caption**: 12-13pt (labels)
- **Small**: 10-11pt (metadata)

### Color Usage

**Backgrounds:**
- Main: `#F5F5F7`
- Cards: `#FFFFFF`
- Overlays: White with opacity

**Text:**
- Primary: `#111827`
- Secondary: `#6B7280`
- Tertiary: `#9CA3AF`

**Actions:**
- Primary: `#5B7FFF` (Blue)
- Success: `#00C896` (Mint)
- Warning: `#F59E0B` (Amber)
- Error: `#EF4444` (Red)

### Shadows & Depth

**Cards:**
- Shadow: `Color.black.opacity(0.05), radius: 10, x: 0, y: 4`
- Border: `Color.gray.opacity(0.1), lineWidth: 1`

**Buttons:**
- Shadow: Accent color opacity 0.35, radius 20, y: 8
- Border: White opacity 0.25

**Elevated Elements:**
- Increased shadow radius
- Multiple shadow layers for depth

---

## User Flows

### Starting a Workout

1. **Home Tab** → Tap "Next Workout" pill
2. **Workout Tab** → Tap workout day card
3. **Workout Preview** → Review exercises → Tap "Start Workout"
4. **Active Workout** → Log sets → Complete workout

### Logging a Set

1. **Active Workout** → Swipe to exercise → Tap exercise to expand
2. **Set Row** → Enter weight → Enter reps → Select RIR → Tap checkbox
3. **Auto-rest timer** starts (if enabled)
4. **Next set** → Repeat

### Viewing Analytics

1. **Fitness Tab** → Scroll through cards
2. **Tap card** → View details (if tappable)
3. **Time range picker** → Change period (Week/Month/Year)
4. **Metric info** → Tap info icon → View explanation

### Managing Workouts

1. **Workout Tab** → Long press workout card
2. **Context menu** → Edit or Delete
3. **Edit** → Modify exercises → Save
4. **Add Workout** → Tap "Add Workout" card → Fill form → Create

---

## Apple Watch UI

### Design Principles

- **Liquid Glass** aesthetic
- **Compact layouts** for small screen
- **Large tap targets** (minimum 44pt)
- **Digital Crown** support for inputs
- **Haptic feedback** for interactions

### Key Screens

**Workout List:**
- Glassmorphic cards
- Workout icons
- Swipe to start

**Active Workout:**
- 3-page paginated view
- Large numbers
- Digital Crown for inputs
- Heart rate display

**Set Input:**
- Large weight/reps display
- Digital Crown scrolling
- Haptic feedback
- Focus management

---

## Accessibility

### Text Sizes
- Dynamic Type support
- Minimum readable sizes
- Scalable layouts

### Contrast
- WCAG AA compliance
- High contrast mode support
- Color-blind friendly palettes

### Interactions
- Minimum tap targets: 44x44pt
- VoiceOver support
- Haptic feedback
- Clear focus states

---

## Notes

- All measurements in points (pt)
- Colors specified in hex format
- Fonts use SF Pro Rounded for modern appearance
- Consistent card styling throughout app
- Glassmorphism effects on Watch app
- Standard iOS navigation patterns
- Pull-to-refresh on main screens

---

**Last Updated:** January 26, 2026  
**Maintained By:** Development Team
