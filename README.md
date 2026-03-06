# GoChange

A native iOS and watchOS workout tracking app built with SwiftUI and SwiftData.

GoChange helps you log gym sessions, monitor recovery, and understand your fitness trends through deep HealthKit integration.

## Features

**Home Dashboard**
- Recovery Score calculated from HRV and resting heart rate
- Sleep Score from duration, stages (REM, deep, core), and quality via HealthKit
- Strain Score from workout intensity and active energy
- Health metrics panel: HRV, resting HR, respiratory rate, SpO2, VO2 max, steps
- Scrollable activity timeline with tap-to-view session detail
- Daily insight card with personalized recovery feedback

**Workout Tracking**
- 4-day split (Push / Pull / Legs / Fullbody) with fully customizable templates
- Weekly progress indicator and day-by-day completion tracker
- Log sets with weight, reps, and Reps In Reserve (RIR)
- Inline previous set history for every exercise
- Progressive overload suggestions based on recent logs
- Minimize an active workout and navigate freely, then resume where you left off
- Rest timer with Live Activity on Lock Screen and Dynamic Island
- Workout Live Activity showing set and exercise progress during sessions
- Attach photos or videos to any exercise as form reference

**Fitness Analytics**
- Activity heatmap (GitHub-style contribution grid)
- Strength radar chart: volume, frequency, and muscular load by muscle group
- Cardio analytics: focus gauge and heart rate recovery metrics
- Strain vs Recovery correlation chart, dual-axis time series over 7–30 days
- Session detail view for any completed workout

**Apple Watch**
- Browse and start workouts from your wrist
- 3-page active workout layout: set input, overview stats, and controls
- Digital Crown input for weight and reps
- Real-time heart rate streamed to iPhone during workouts
- Haptic feedback on set completion
- Workout templates synced automatically from iPhone

**Other**
- Home screen widget: weekly progress and next suggested workout (small and medium sizes)
- Completed workouts saved to Apple Health
- Full JSON data export and import for backup and restore
- Rest timer alerts and scheduled workout reminders
- Intelligent scheduling: suggests the workout not yet done this week, falling back to the one done longest ago

## Requirements

- iOS 26.1+
- watchOS 26.1+
- Xcode 26.0+
- Swift 5.0
- Apple Developer Account (required for HealthKit, App Groups, and Live Activities)

**Dependencies** (Swift Package Manager):
- [FSCalendar](https://github.com/WenchaoD/FSCalendar) v2.8.4+

## Setup

**1. Clone the repository**

```bash
git clone https://github.com/your-username/gochange.git
cd gochange
open gochange.xcodeproj
```

**2. Update bundle identifiers**

The project uses `com.toqitahamid.gochange` as the base bundle identifier. Replace it with your own across all three targets in Xcode:

- `gochange` — main app
- `GoChangeWidget` — widget extension
- `GoChangeWatch Watch App` — Watch app

**3. Update the App Group identifier**

Search for `group.com.toqitahamid.gochange` and replace it with your own:

```bash
grep -r "group.com.toqitahamid.gochange" --include="*.swift" .
```

Update the references in `gochange/Services/WorkoutManager.swift` and each target's entitlements. Register the new identifier in the [Apple Developer portal](https://developer.apple.com/account).

**4. Set your development team**

In `gochange.xcodeproj/project.pbxproj`, replace `BR9VB4UHUR` with your own team ID, or select your team under each target's Signing & Capabilities tab in Xcode.

**5. Configure HealthKit**

HealthKit is enabled on all three targets. After updating your bundle identifier, ensure HealthKit capability is added for your App ID in the Apple Developer portal. The required usage descriptions are already in the project's Info.plist.

**6. Build and run**

Select the `gochange` scheme and a simulator or connected device, then press `Cmd+R`. To run the Watch app, select the `GoChangeWatch Watch App` scheme with a paired Watch simulator.

## Architecture

GoChange follows MVVM with SwiftData for persistence.

```
gochange/
├── App/                    # Entry point, model container setup
├── Models/                 # SwiftData models
├── ViewModels/             # DashboardViewModel, FitnessViewModel, WorkoutViewModel
├── Views/
│   ├── Home/               # JournalView (primary dashboard)
│   ├── Workout/            # WorkoutDaySelectionView, ActiveWorkoutView
│   ├── Fitness/            # FitnessDashboardView, PerformanceAnalyticsView
│   ├── History/            # SessionDetailView
│   ├── Components/         # Reusable UI components
│   └── LiveActivity/       # Widget and Live Activity UI
├── Services/               # Business logic
└── Utilities/              # Extensions, constants

GoChangeWidget/             # WidgetKit + ActivityKit extension
GoChangeWatch Watch App/    # Standalone watchOS app
```

Key services:
- `WorkoutManager` — singleton managing active workout state, injected as `EnvironmentObject`
- `HealthKitService` — reads sleep, HRV, heart rate, VO2 max, and steps; writes completed workouts
- `SchedulingService` — suggests next workout based on completion history and recency
- `RestTimerActivityManager` — manages Live Activity for the rest timer
- `WatchConnectivityService` — syncs workout templates to Watch

## Building

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

## Contributing

Open an issue to discuss significant changes before submitting a pull request.

1. Fork the repository
2. Complete the [Setup](#setup) steps with your own bundle identifier and team
3. Create a feature branch: `git checkout -b feat/your-feature`
4. Commit using conventional prefixes: `feat:`, `fix:`, `refactor:`, `docs:`
5. Open a pull request

## License

MIT License — see [LICENSE](LICENSE) for details.
