# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GoChange is a native iOS workout tracking app built with SwiftUI and SwiftData. It helps users log gym sessions following a 4-day Push/Pull/Legs/Fullbody split with intelligent workout scheduling, progress tracking, and Live Activity support for rest timers.

## Building and Running

### Build the main app
```bash
xcodebuild -scheme gochange -configuration Debug build
```

### Build the widget extension
```bash
xcodebuild -scheme GoChangeWidgetExtension -configuration Debug build
```

### Run in simulator (recommended for development)
Open `gochange.xcodeproj` in Xcode and use Cmd+R to build and run. The app requires iOS 17.0+.

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

### ViewModels

- **WorkoutViewModel** (`gochange/ViewModels/WorkoutViewModel.swift`):
  - ViewModel for workout operations (NOT currently used in main app flow)
  - WorkoutManager is preferred for active workout management
  - Contains methods: startSession(), completeSession(), addExercise(), etc.
  - Calculates statistics: completedSessionsThisWeek, totalVolume, averageWorkoutDuration
  - Uses SchedulingService.suggestNextWorkout()

- **CalendarViewModel** (`gochange/ViewModels/CalendarViewModel.swift`):
  - Calendar-specific logic and data transformation

### View Structure

- **MainTabView.swift**: Tab-based navigation (Home, Workout, Calendar, History, More/Settings)
  - Dynamically shows ActiveWorkoutView when WorkoutManager.isWorkoutActive is true
  - Shows MiniPlayerView at bottom when workout is minimized
  - Injects WorkoutManager as EnvironmentObject

- **Views/Workout/**: ActiveWorkoutView (main workout logging UI), WorkoutDaySelectionView, EditWorkoutDayView, WorkoutPreviewView
- **Views/LiveActivity/**: RestTimerWidget (WidgetKit/ActivityKit UI), RestTimerWidgetBundle
- **Views/Components/**: Reusable components like RestTimerView, ProgressChartView, MiniPlayerView
- **Views/Home/**: HomeView
- **Views/Calendar/**: CalendarView
- **Views/History/**: HistoryListView, SessionDetailView
- **Views/Exercise/**: ExerciseLibraryView, ExerciseDetailView
- **Views/Settings/**: SettingsView

### App Initialization

In `gochange/App/GoChangeApp.swift`:
- SwiftData ModelContainer is initialized with schema including all 5 models
- Default workout data is seeded on first launch via `DefaultWorkoutData.createDefaultWorkouts()`
- ModelContainer is injected into environment via `.modelContainer(modelContainer)`
- WorkoutManager singleton is created as @StateObject and injected via `.environmentObject(workoutManager)`

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
│   ├── RestTimerAttributes.swift
│   ├── WorkoutActivityAttributes.swift
│   └── DefaultWorkoutData.swift
├── ViewModels/                   # MVVM ViewModels
│   ├── WorkoutViewModel.swift
│   └── CalendarViewModel.swift
├── Views/                        # SwiftUI views
│   ├── MainTabView.swift
│   ├── Home/
│   ├── Workout/
│   ├── Calendar/
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
│   └── MediaService.swift
└── Utilities/                    # Extensions and constants
    ├── Extensions.swift
    └── Constants.swift

GoChangeWidget/                   # Widget Extension target
├── Info.plist
└── Assets.xcassets/
```
