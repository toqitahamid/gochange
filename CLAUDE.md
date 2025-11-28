# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GoChange is a native iOS and watchOS workout tracking app built with SwiftUI and SwiftData. It helps users log gym sessions following a 4-day Push/Pull/Legs/Fullbody split with intelligent workout scheduling, progress tracking, HealthKit integration for recovery metrics, and Live Activity support for rest timers and active workouts. The app includes a companion Apple Watch app for viewing and starting workouts on the wrist.

## Building and Running

### Build the main app
```bash
xcodebuild -scheme gochange -configuration Debug build
```

### Build the widget extension
```bash
xcodebuild -scheme GoChangeWidgetExtension -configuration Debug build
```

### Build the Apple Watch app
```bash
xcodebuild -scheme "GoChangeWatch Watch App" -configuration Debug build
```

### Run in simulator (recommended for development)
Open `gochange.xcodeproj` in Xcode and use Cmd+R to build and run. The app requires iOS 17.0+. To run the Watch app, select the Watch scheme and run on a paired Watch simulator.

### Clean build
```bash
xcodebuild clean -scheme gochange
```

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture with SwiftData for persistence:

### Data Models (SwiftData)
All models are SwiftData `@Model` classes with relationships:

- **WorkoutDay**: Represents a workout template (Push/Pull/Legs/Fullbody)
  - Has many `Exercise` objects (cascade delete)
  - Properties: name, dayNumber, colorHex

- **Exercise**: Individual exercise within a workout day
  - Properties: name, defaultSets, defaultReps, muscleGroup, notes
  - Optional media URLs for form reference

- **WorkoutSession**: A logged workout instance
  - Has many `ExerciseLog` objects (cascade delete)
  - Tracks: date, startTime, endTime, duration, isCompleted
  - References WorkoutDay by ID (not a relationship to allow workout template changes)

- **ExerciseLog**: Logged exercise within a session
  - Has many `SetLog` objects (cascade delete)
  - References Exercise by ID, stores exerciseName for history

- **SetLog**: Individual set data
  - Properties: setNumber, targetReps, actualReps, weight, weightUnit, rir (Reps In Reserve), isCompleted

- **RestTimerAttributes**: ActivityKit attributes for Live Activity rest timer

- **WorkoutActivityAttributes**: ActivityKit attributes for Live Activity workout tracking

- **RestDay**: Represents a scheduled rest day
  - Properties: date, reason, notes

- **RecoveryMetrics**: Tracks recovery and readiness data
  - HealthKit data: sleepDuration, sleepQuality, deepSleep, REMsleep, restingHeartRate, HRV
  - User-reported: muscleRecovery (array of MuscleGroupRecovery), overallFatigue, motivationLevel
  - Computed: overallRecoveryScore (0-1), readinessToTrain (TrainingReadiness enum)

### Key Services

- **SchedulingService** (`gochange/Services/SchedulingService.swift`):
  - Intelligent workout suggestions based on completion history
  - Suggests workouts not completed in current week first
  - Falls back to recency-based suggestions (workout done longest ago)
  - Calculates weekly streaks (consecutive weeks with all 4 workouts)
  - Rest period validation (48h same muscle group, 24h different)

- **WorkoutManager** (`gochange/Services/WorkoutManager.swift`):
  - Singleton managing active workout state (injected as EnvironmentObject)
  - Handles workout lifecycle: start(), minimize(), resume(), cancel(), complete()
  - Manages exerciseLogs array and set operations
  - Integrates with WorkoutActivityManager for Live Activity updates
  - Methods: addSet(), removeSet(), toggleSetCompletion()

- **RestTimerActivityManager** (`gochange/Services/RestTimerActivityManager.swift`):
  - Singleton managing Live Activity for rest timer
  - Uses ActivityKit to display timer on Lock Screen/Dynamic Island
  - Methods: start(endTime:), update(endTime:), end()

- **WorkoutActivityManager** (`gochange/Services/WorkoutActivityManager.swift`):
  - Singleton managing Live Activity for active workouts
  - Shows workout progress (completed sets/total sets) on Lock Screen/Dynamic Island
  - Methods: start(), update(completedSets:totalSets:exerciseCount:), end()

- **DataService** (`gochange/Services/DataService.swift`):
  - Export/import functionality for backup/restore
  - JSON serialization with ISO8601 dates
  - Full data export including all workout days and session history

- **MediaService** (`gochange/Services/MediaService.swift`):
  - Photo/video handling for exercise form reference

- **NotificationService** (`gochange/Services/NotificationService.swift`):
  - Singleton managing local notifications and authorization
  - Rest timer completion notifications
  - Scheduled workout reminders (recurring based on weekday)
  - Methods: requestAuthorization(), scheduleRestTimerNotification(endTime:), scheduleWorkoutReminder(weekday:hour:minute:workoutName:)
  - Uses UNUserNotificationCenter for local notifications

- **HealthKitService** (`gochange/Services/HealthKitService.swift`):
  - Singleton managing HealthKit integration
  - Writes workout sessions to Apple Health with activity type and calories
  - Reads extensive health metrics: sleep data, heart rate, HRV, respiratory rate, oxygen saturation, VO2 max, steps, etc.
  - Methods: requestAuthorization(), saveWorkout(), getSleepData(), getRestingHeartRate(), getHRV()
  - Requires proper Info.plist privacy usage descriptions

- **RecoveryService** (`gochange/Services/RecoveryService.swift`):
  - Singleton managing recovery metrics
  - Fetches/creates RecoveryMetrics for given dates
  - Syncs with HealthKit for sleep and vitals
  - Calculates recovery scores from multiple data sources

- **AnalyticsService** (`gochange/Services/AnalyticsService.swift`):
  - Workout analytics and statistics
  - Calculates: active days, total exercises, total reps, top exercises, volume trends

- **WatchConnectivityService** (`gochange/Services/WatchConnectivityService.swift`):
  - Singleton managing iPhone side of Watch Connectivity
  - Sends workout day templates to Apple Watch
  - Receives completed workout sessions from Watch
  - Uses WCSession for bidirectional communication

### ViewModels

- **WorkoutViewModel** (`gochange/ViewModels/WorkoutViewModel.swift`):
  - ViewModel for workout operations (NOT currently used in main app flow)
  - WorkoutManager is preferred for active workout management
  - Contains methods: startSession(), completeSession(), addExercise(), etc.
  - Calculates statistics: completedSessionsThisWeek, totalVolume, averageWorkoutDuration
  - Uses SchedulingService.suggestNextWorkout()

- **DashboardViewModel** (`gochange/ViewModels/DashboardViewModel.swift`):
  - Main dashboard data aggregation
  - Calculates recovery, sleep, and strain scores (0-100)
  - Fetches data from HealthKitService and RecoveryService
  - Displays: HRV, resting HR, sleep data, active calories, VO2 max, respiratory rate, oxygen saturation

- **FitnessViewModel** (`gochange/ViewModels/FitnessViewModel.swift`):
  - Fitness and strength analytics
  - Calculates muscle group volumes, frequency, and load
  - Displays strength metrics and workout distribution

- **AnalyticsViewModel** (`gochange/ViewModels/AnalyticsViewModel.swift`):
  - Advanced analytics and trends
  - Weekly/monthly workout statistics

### View Structure

- **MainTabView.swift**: Tab-based navigation (Home, Workout, Fitness, More/Settings)
  - Dynamically shows ActiveWorkoutView when WorkoutManager.isWorkoutActive is true
  - Shows MiniPlayerView at bottom when workout is minimized
  - Injects WorkoutManager as EnvironmentObject

- **Views/Workout/**: ActiveWorkoutView (main workout logging UI), WorkoutDaySelectionView, EditWorkoutDayView, WorkoutPreviewView
- **Views/LiveActivity/**: RestTimerWidget (WidgetKit/ActivityKit UI), RestTimerWidgetBundle, GoChangeStaticWidget (home screen widget)
- **Views/Components/**: Reusable components like RestTimerView, ProgressChartView, MiniPlayerView, CircularProgressView
- **Views/Home/**: HomeView with new dashboard showing Recovery/Strain/Sleep metrics
- **Views/Recovery/**: Recovery metrics detail view
- **Views/Sleep/**: Sleep data detail view
- **Views/Fitness/**: Fitness/strength analytics view
- **Views/Analytics/**: Advanced analytics view
- **Views/History/**: SessionDetailView (individual workout session details, used in homepage timeline)
- **Views/Exercise/**: ExerciseLibraryView, ExerciseDetailView
- **Views/Settings/**: SettingsView

### App Initialization

In `gochange/App/GoChangeApp.swift`:
- SwiftData ModelContainer is initialized with schema including all models: WorkoutDay, Exercise, WorkoutSession, ExerciseLog, SetLog, RestDay, RecoveryMetrics
- Default workout data is seeded on first launch via `DefaultWorkoutData.createDefaultWorkouts()`
- ModelContainer is injected into environment via `.modelContainer(modelContainer)`
- WorkoutManager singleton is created as @StateObject and injected via `.environmentObject(workoutManager)`
- WatchConnectivityService is initialized with model context for iPhone-Watch communication

## Important Patterns

### SwiftData Context Access
Views access the model context via `@Environment(\.modelContext)`. ViewModels receive it via initializer or WorkoutManager.setModelContext().

### Session Management
When starting a workout via WorkoutManager:
1. Create WorkoutSession from WorkoutDay template
2. Pre-populate ExerciseLogs for each exercise
3. Pre-populate SetLogs for each set with targetReps from exercise defaults
4. User fills in actualReps, weight, RIR during workout
5. On completion, set endTime, duration, isCompleted = true and persist to database

### Data Relationships
- Use cascade delete for parent-child relationships (WorkoutDay→Exercise, WorkoutSession→ExerciseLog, etc.)
- Session references WorkoutDay by UUID (not relationship) to preserve history if templates change
- ExerciseLog stores exerciseName string copy for historical accuracy

### Live Activity Integration
- RestTimerActivityManager is a singleton that manages the rest timer Live Activity. Call `RestTimerActivityManager.shared.start(endTime: Date)` to show the timer on Lock Screen/Dynamic Island.
- WorkoutActivityManager is a singleton that manages the workout progress Live Activity. It's automatically started/updated/ended by WorkoutManager.
- The widget extension (GoChangeWidget) renders the UI for both activities.

### HealthKit Integration
- Request authorization on first use via `HealthKitService.shared.requestAuthorization()`
- Save completed workouts to Apple Health: `HealthKitService.shared.saveWorkout(session:)`
- Fetch sleep, heart rate, HRV data for recovery metrics
- Info.plist must include privacy usage descriptions for all HealthKit data types

### Watch Connectivity
- iPhone app initializes `WatchConnectivityService.shared` and provides model context
- Watch app uses `WatchConnectivityManager.shared` to communicate
- Workout templates are synced from iPhone to Watch via JSON encoding
- Watch can request workout data: `requestWorkoutDays()`
- Completed Watch workouts can be synced back to iPhone (planned feature)

## Design System

### Card Styling Standards
All cards throughout the app should use consistent styling for visual cohesion. These standards are applied in HomeView, WorkoutPreviewView, and should be used for any new card components.

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
- Corner radius: `24`
- Shadow: `color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4`
- Border: `Color.gray.opacity(0.1), lineWidth: 1`
- Background: `Color.white`

### Color Scheme
**Background:**
- Main background: `Color(hex: "#F5F5F7")` - Light gray background used across HomeView, WorkoutPreviewView, and other main screens

**Accent Colors:**
- Primary accent: `Color(hex: "#5B7FFF")` - Blue used for primary actions and highlights
- Secondary accent: `Color(hex: "#7B92FF")` - Lighter blue for gradients
- Note: Individual workout days may have custom colors stored in `colorHex` property, but primary UI elements should use the unified blue scheme

### Layout Patterns
**Sticky Bottom Buttons:**
- Important action buttons (e.g., "Start Workout") should be fixed at the bottom of the screen using a ZStack layout
- Include a gradient fade effect behind the button for smooth visual transition
- Add extra bottom padding (120pt) to ScrollView content to prevent overlap

**Spacing:**
- Card spacing: `20pt` between cards
- Horizontal padding: `20pt` from screen edges
- Top padding: `16pt` for main content areas

## Widget Extension

The `GoChangeWidget` target is a Widget Extension containing:
- Info.plist with NSSupportsLiveActivities = YES
- Widget UI in Views/LiveActivity/RestTimerWidget.swift
- Bundle identifier: com.toqitahamid.gochange.GoChangeWidget

### Static Home Screen Widget
- **GoChangeStaticWidget** (`gochange/Views/LiveActivity/GoChangeStaticWidget.swift`):
  - WidgetKit-based home screen widget showing weekly progress
  - Supports small and medium widget sizes
  - Shows: workouts completed this week, weekly streak, next suggested workout
  - Uses App Groups for data sharing: `group.com.toqitahamid.gochange`
  - WidgetDataManager syncs data between main app and widget extension
  - Updates every hour via Timeline

## Apple Watch App

The `GoChangeWatch Watch App` target is a standalone watchOS app:
- Bundle identifier: com.toqitahamid.gochange.watchkitapp
- Minimum watchOS version: watchOS 10.0+
- Uses WatchConnectivity to sync workout templates from iPhone

### Watch App Structure
- **GoChangeWatchApp.swift**: Entry point, initializes WatchConnectivityManager
- **WatchWorkoutManager**: Manages active workout state on Watch (similar to iOS WorkoutManager)
- **WatchConnectivityManager**: Handles communication with iPhone, receives workout templates
- **WatchHealthKitService**: Saves completed workouts to HealthKit on Watch
- **Views**: WorkoutListView, WorkoutDetailView, WatchActiveWorkoutView, SetInputView
- **DesignSystem.swift**: Watch-specific design tokens and styling

### Watch-iPhone Communication
- Watch requests workout templates on launch via `requestWorkoutDays()`
- iPhone responds with JSON-encoded workout data via WCSession
- Watch uses local `WatchWorkoutDay` and `WatchExercise` models (Codable structs, not SwiftData)
- Communication is bidirectional: sendMessage() with optional reply handlers

## Dependencies

- **FSCalendar** (v2.8.4+): Calendar UI component via Swift Package Manager
  - URL: https://github.com/WenchaoD/FSCalendar.git

## Common Data Operations

### Fetching workout days
```swift
let descriptor = FetchDescriptor<WorkoutDay>(sortBy: [SortDescriptor(\.dayNumber)])
let workoutDays = try modelContext.fetch(descriptor)
```

### Fetching sessions
```swift
let descriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
let sessions = try modelContext.fetch(descriptor)
```

### Filtering sessions for current week
```swift
let startOfWeek = Date().startOfWeek  // Extension in Utilities/Extensions.swift
let weekSessions = sessions.filter { $0.isCompleted && $0.date >= startOfWeek }
```

## Project Structure

```
gochange/
├── App/                          # App entry point
│   └── GoChangeApp.swift
├── Models/                       # SwiftData models
│   ├── WorkoutDay.swift
│   ├── Exercise.swift
│   ├── WorkoutSession.swift
│   ├── ExerciseLog.swift
│   ├── SetLog.swift
│   ├── RestDay.swift
│   ├── RecoveryMetrics.swift
│   ├── RestTimerAttributes.swift
│   ├── WorkoutActivityAttributes.swift
│   └── DefaultWorkoutData.swift
├── ViewModels/                   # MVVM ViewModels
│   ├── WorkoutViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── FitnessViewModel.swift
│   └── AnalyticsViewModel.swift
├── Views/                        # SwiftUI views
│   ├── MainTabView.swift
│   ├── Home/
│   ├── Workout/
│   ├── Recovery/
│   ├── Sleep/
│   ├── Fitness/
│   ├── Analytics/
│   ├── History/
│   ├── Exercise/
│   ├── Settings/
│   ├── LiveActivity/             # Widget UI
│   └── Components/
├── Services/                     # Business logic services
│   ├── SchedulingService.swift
│   ├── WorkoutManager.swift
│   ├── RestTimerActivityManager.swift
│   ├── WorkoutActivityManager.swift
│   ├── NotificationService.swift
│   ├── DataService.swift
│   ├── MediaService.swift
│   ├── HealthKitService.swift
│   ├── RecoveryService.swift
│   ├── AnalyticsService.swift
│   └── WatchConnectivityService.swift
└── Utilities/                    # Extensions and constants
    ├── Extensions.swift
    └── Constants.swift

GoChangeWidget/                   # Widget Extension target
├── Info.plist
└── Assets.xcassets/

GoChangeWatch Watch App/          # watchOS app target
├── GoChangeWatchApp.swift
├── DesignSystem.swift
├── Services/
│   ├── WatchWorkoutManager.swift
│   ├── WatchConnectivityManager.swift
│   └── WatchHealthKitService.swift
└── Views/
    ├── WorkoutListView.swift
    ├── WorkoutDetailView.swift
    ├── WatchActiveWorkoutView.swift
    └── SetInputView.swift
```
