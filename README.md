# GoChange

A native iOS and watchOS workout tracking app built with SwiftUI and SwiftData. GoChange helps you log gym sessions, monitor recovery, and understand your fitness trends through deep HealthKit integration.

---

## Features

### Home Dashboard
- **Recovery Score** — calculated from HRV and resting heart rate
- **Sleep Score** — sleep duration, stages (REM, deep, core), and quality via HealthKit
- **Strain Score** — workout intensity and active energy tracking
- **Health Metrics Panel** — HRV, resting HR, respiratory rate, SpO2, VO2 max, steps
- **Activity Timeline** — scrollable list of recent workout sessions with tap-to-view details
- **Daily Insight Card** — personalized recovery feedback based on recent data

### Workout Tracking
- **4-Day Split** — Push / Pull / Legs / Fullbody templates, fully customizable
- **Weekly Progress** — circular progress indicator and day-by-day completion tracker
- **Active Workout View** — log sets with weight, reps, and Reps In Reserve (RIR)
- **Exercise Library** — browsable and searchable library with muscle group filters
- **Previous Set History** — see your last performance for every exercise inline
- **Progressive Overload Suggestions** — smart recommendations based on recent logs
- **Minimize & Resume** — minimize an active workout and navigate freely, then pick up where you left off
- **Rest Timer** — countdown timer with Live Activity on Lock Screen and Dynamic Island
- **Workout Live Activity** — set/exercise progress shown on Lock Screen during workouts
- **Exercise Form Reference** — attach photos or videos to any exercise

### Fitness Analytics
- **Activity Heatmap** — GitHub-style contribution grid showing workout intensity over time
- **Strength Radar Chart** — visualize volume, frequency, and muscular load by muscle group
- **Cardio Analytics** — cardio focus gauge and heart rate recovery metrics
- **Strain vs Recovery Correlation** — dual-axis time series chart over 7–30 days
- **Session Detail View** — complete breakdown of any past workout

### Apple Watch App
- **Workout List** — browse and start workouts from your wrist
- **Active Workout View** — 3-page layout: set input, overview stats, and controls
- **Digital Crown Input** — scroll to adjust weight and reps
- **Real-time Heart Rate** — streamed live to the iPhone during workouts
- **Haptic Feedback** — confirms set completion and input changes
- **WatchConnectivity Sync** — workout templates synced automatically from iPhone

### Other
- **Home Screen Widget** — weekly workout progress and next suggested workout (small and medium sizes)
- **HealthKit Write** — completed workouts saved to Apple Health
- **Data Export / Import** — full JSON backup and restore
- **Notification Support** — rest timer alerts and scheduled workout reminders
- **Intelligent Scheduling** — suggests the workout you haven't done yet this week, falling back to the one done longest ago

---

## Requirements

| Requirement | Version |
|---|---|
| iOS | 26.1+ |
| watchOS | 26.1+ |
| Xcode | 26.0+ |
| Swift | 5.0 |
| Apple Developer Account | Required (HealthKit, App Groups, Live Activities) |

**Dependencies** (resolved automatically via Swift Package Manager):
- [FSCalendar](https://github.com/WenchaoD/FSCalendar) v2.8.4+

---

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/your-username/gochange.git
cd gochange
open gochange.xcodeproj
```

### 2. Update bundle identifiers

The project uses `com.toqitahamid.gochange` as the base bundle identifier. You need to replace it with your own throughout the project.

In Xcode, select the `gochange` project in the navigator, then update the bundle identifier for each target:

| Target | Default Bundle ID |
|---|---|
| gochange | `com.toqitahamid.gochange` |
| GoChangeWidget | `com.toqitahamid.gochange.GoChangeWidget` |
| GoChangeWatch Watch App | `com.toqitahamid.gochange.watchkitapp` |

### 3. Update the App Group identifier

The app uses App Groups to share data between the main app, widget extension, and Watch app. Search for `group.com.toqitahamid.gochange` in the project and replace it with your own App Group identifier:

```
grep -r "group.com.toqitahamid.gochange" --include="*.swift" .
```

Update these in:
- `gochange/Services/WorkoutManager.swift`
- Your Xcode project entitlements for each target

Register the new App Group identifier in your [Apple Developer portal](https://developer.apple.com/account).

### 4. Set your Development Team

In `gochange.xcodeproj/project.pbxproj`, replace `BR9VB4UHUR` with your own team ID, or select your team in Xcode under each target's **Signing & Capabilities** tab.

### 5. Configure HealthKit entitlements

HealthKit is enabled on all three targets. After changing your bundle identifier, ensure HealthKit capability is added in the Apple Developer portal for your App ID. The required usage descriptions are already in the project's Info.plist.

### 6. Build and run

Select the `gochange` scheme and a simulator or connected device, then press `Cmd+R`.

To run the Watch app, select the `GoChangeWatch Watch App` scheme and a paired Watch simulator.

---

## Architecture

GoChange follows **MVVM** with **SwiftData** for persistence.

```
gochange/
├── App/                    # Entry point, model container setup
├── Models/                 # SwiftData models (WorkoutDay, Exercise, WorkoutSession, ...)
├── ViewModels/             # DashboardViewModel, FitnessViewModel, WorkoutViewModel, ...
├── Views/
│   ├── Home/               # JournalView (primary dashboard), SummaryRingsView, TimelineView
│   ├── Workout/            # WorkoutDaySelectionView, ActiveWorkoutView, WorkoutPreviewView, ...
│   ├── Fitness/            # FitnessDashboardView, PerformanceAnalyticsView
│   ├── Recovery/           # Recovery detail views
│   ├── Sleep/              # Sleep detail views
│   ├── Analytics/          # Advanced analytics views
│   ├── History/            # SessionDetailView
│   ├── Exercise/           # ExerciseLibraryView, ExerciseDetailView
│   ├── Settings/           # SettingsView
│   ├── Components/         # Reusable UI components
│   └── LiveActivity/       # Widget and Live Activity UI
├── Services/               # Business logic (WorkoutManager, HealthKitService, SchedulingService, ...)
└── Utilities/              # Extensions, constants

GoChangeWidget/             # WidgetKit + ActivityKit extension
GoChangeWatch Watch App/    # Standalone watchOS app
```

**Key services:**
- `WorkoutManager` — singleton managing active workout state, injected as `EnvironmentObject`
- `HealthKitService` — reads sleep, HRV, heart rate, VO2 max, steps; writes completed workouts
- `SchedulingService` — suggests next workout based on completion history and recency
- `RestTimerActivityManager` — manages Live Activity for rest timer
- `WatchConnectivityService` — syncs workout templates to Watch; receives heart rate during workouts

---

## Building Specific Targets

```bash
# Main app
xcodebuild -scheme gochange -configuration Debug build

# Widget extension
xcodebuild -scheme GoChangeWidgetExtension -configuration Debug build

# Apple Watch app
xcodebuild -scheme "GoChangeWatch Watch App" -configuration Debug build

# Clean
xcodebuild clean -scheme gochange
```

---

## Contributing

Contributions are welcome. Please open an issue first to discuss significant changes.

1. Fork the repository
2. Follow the [Setup](#setup) steps with your own bundle identifier and team
3. Create a feature branch: `git checkout -b feat/your-feature`
4. Commit with conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`
5. Open a pull request

---

## License

MIT License — see [LICENSE](LICENSE) for details.
