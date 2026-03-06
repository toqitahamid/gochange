# CLAUDE.md

## Project Overview

GoChange is a native iOS/watchOS workout tracking app built with SwiftUI and SwiftData. 4-day Push/Pull/Legs/Fullbody split with intelligent scheduling, HealthKit recovery metrics, Live Activities, and a companion Apple Watch app.

## Build Commands

```bash
# Build
xcodebuild -scheme gochange -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug build

# Test
xcodebuild -scheme gochange -destination 'platform=iOS Simulator,name=iPhone 16' test

# Watch app
xcodebuild -scheme "GoChangeWatch Watch App" -configuration Debug build

# Widget
xcodebuild -scheme GoChangeWidgetExtension -configuration Debug build

# Clean
xcodebuild clean -scheme gochange
```

- Xcode 26.3, iOS 26.3.1 simulator, iPhone 16
- Always pass `-destination 'platform=iOS Simulator,name=iPhone 16'`
- Watch app has a cosmetic AppIcon asset issue (does not block builds)

## Architecture

MVVM with SwiftData persistence. Three targets: iOS app, Widget Extension, watchOS app.

### Data Models

All SwiftData `@Model` classes with cascade-delete relationships:

- **WorkoutDay** → many **Exercise** (template: name, dayNumber, colorHex)
- **WorkoutSession** → many **ExerciseLog** → many **SetLog** (logged workout instance)
- **SetLog**: setNumber, targetReps, actualReps, weight, weightUnit, rir, isCompleted
- **RecoveryMetrics**: HealthKit data (sleep, HR, HRV) + user-reported (fatigue, motivation) → computed recoveryScore
- **RestDay**: date, reason, notes
- **RestTimerAttributes** / **WorkoutActivityAttributes**: ActivityKit Live Activity attributes

Session references WorkoutDay by UUID (not relationship) to preserve history if templates change. ExerciseLog stores exerciseName string copy for historical accuracy.

### Services

All singletons in `gochange/Services/`:

| Service | Purpose |
|---|---|
| **WorkoutManager** | Active workout state (EnvironmentObject). Lifecycle: start/minimize/resume/cancel/complete. Manages exerciseLogs and sets. |
| **SchedulingService** | Suggests next workout based on completion history. Weekly streaks. Rest period validation (48h same muscle, 24h different). |
| **HealthKitService** | Read/write HealthKit: workouts, sleep, HR, HRV, SpO2, VO2max, steps. Requires Info.plist privacy descriptions. |
| **RecoveryService** | Fetches/creates RecoveryMetrics, syncs with HealthKit, calculates recovery scores. |
| **RestTimerActivityManager** | Live Activity for rest timer on Lock Screen/Dynamic Island. |
| **WorkoutActivityManager** | Live Activity for workout progress. Auto-managed by WorkoutManager. |
| **NotificationService** | Rest timer notifications, scheduled workout reminders. |
| **DataService** | JSON export/import for backup/restore. |
| **AnalyticsService** | Workout statistics: active days, volume, top exercises, trends. |
| **WatchConnectivityService** | Sends workout templates to Watch, receives completed sessions. |
| **MediaService** | Photo/video for exercise form reference. |

### ViewModels

| ViewModel | Purpose |
|---|---|
| **DashboardViewModel** | Home dashboard: recovery/sleep/strain scores, HealthKit metrics |
| **FitnessViewModel** | Strength analytics, muscle group volumes, strain vs recovery correlation |
| **AnalyticsViewModel** | Weekly/monthly workout trends |
| **WorkoutViewModel** | Workout operations (NOT used in main flow — WorkoutManager preferred) |

### Navigation

**MainTabView** — 3 tabs:
- Tab 0 "Home": **JournalView** (primary dashboard — recovery/strain/sleep cards, timeline, health metrics)
- Tab 1 "Workout": **WorkoutDaySelectionView** (plan and select workouts)
- Tab 2 "Fitness": **PerformanceAnalyticsView** (analytics and trends)
- Active workout overlay via **ActiveWorkoutView** when `WorkoutManager.isWorkoutActive`
- **WorkoutMiniplayer** shown when workout is minimized
- Settings via navigation (no tab)

### App Initialization (`GoChangeApp.swift`)

SwiftData ModelContainer with all models → injected via `.modelContainer()`. WorkoutManager as @StateObject → `.environmentObject()`. Default data seeded on first launch via `DefaultWorkoutData.createDefaultWorkouts()`.

## Key Patterns

**SwiftData context**: Views use `@Environment(\.modelContext)`. ViewModels receive context via initializer or `WorkoutManager.setModelContext()`.

**Workout session flow**: Create WorkoutSession from template → pre-populate ExerciseLogs and SetLogs → user fills actualReps/weight/RIR → on completion set endTime/duration/isCompleted=true.

**Live Activities**: RestTimerActivityManager and WorkoutActivityManager are singletons. Widget extension (GoChangeWidget) renders both. WorkoutActivityManager is auto-managed by WorkoutManager.

**Watch Connectivity**: iPhone sends templates via WCSession JSON encoding. Watch uses local Codable structs (not SwiftData). Bidirectional via `sendMessage()`.

## Design System

**Card style** (used in JournalView, WorkoutPreviewView, all new cards):
```swift
.background(Color.white)
.clipShape(RoundedRectangle(cornerRadius: 24))
.shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
.overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.gray.opacity(0.1), lineWidth: 1))
```

**Colors**: Background `#F5F5F7`, primary accent `#5B7FFF`, secondary accent `#7B92FF`.

**Layout**: Card spacing 20pt, horizontal padding 20pt, top padding 16pt. Sticky bottom buttons use ZStack with gradient fade + 120pt scroll bottom padding.

## Widget Extension

Target: `GoChangeWidget` (bundle: `com.toqitahamid.gochange.GoChangeWidget`)
- Live Activities for rest timer and workout progress
- Static home screen widget (small/medium): weekly progress, streak, next workout suggestion
- App Groups: `group.com.toqitahamid.gochange`

## Apple Watch App

Target: `GoChangeWatch Watch App` (bundle: `com.toqitahamid.gochange.watchkitapp`, watchOS 10+)
- WatchWorkoutManager, WatchConnectivityManager, WatchHealthKitService
- Views: WorkoutListView, WorkoutDetailView, WatchActiveWorkoutView, SetInputView
- Uses local Codable structs (WatchWorkoutDay, WatchExercise), not SwiftData

## Dependencies

- **FSCalendar** (v2.8.4+): Calendar UI via SPM

## Changelog

See `CHANGELOG.md`. Current version: **1.0.0** (2026-03-01).

## Roadmap

See `ROADMAP.md` (Now / Next / Later format).
- **Now**: Core workout polish (exercise reordering, activity rings, Liquid Glass), Watch stability
- **Next**: Progressive overload, workout customization (supersets, warm-up sets), recovery depth, Watch independence
- **Later**: Intelligent coaching, social/sharing, iPad/Apple TV, third-party integrations
