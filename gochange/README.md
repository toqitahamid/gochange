# Workout Tracker

A native iOS workout tracking app built with Swift and SwiftUI that helps you log gym sessions following a 4-day Push/Pull/Legs/Fullbody split.

## Features

- **Smart Scheduling**: Intelligent workout suggestions based on your completion history
- **Flexible Tracking**: Log sets, reps, weights, and RIR (Reps In Reserve)
- **Beautiful Calendar**: Visual calendar with color-coded workout history
- **Progress Tracking**: View personal records and exercise-specific progress
- **Exercise Library**: Organized by muscle group with form reference media support
- **Rest Timer**: Built-in rest timer with haptic feedback
- **Data Export/Import**: Backup and restore your workout data

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

1. Clone the repository
2. Open the project in Xcode
3. Build and run on simulator or device

### Adding FSCalendar (Optional)

If you want to use FSCalendar for the calendar view:

1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/WenchaoD/FSCalendar.git`
3. Select version 2.8.4 or later

## Project Structure

```
WorkoutTracker/
├── App/
│   └── WorkoutTrackerApp.swift       # App entry point
├── Models/
│   ├── WorkoutDay.swift              # Workout day model
│   ├── Exercise.swift                # Exercise model
│   ├── WorkoutSession.swift          # Session model
│   ├── ExerciseLog.swift             # Exercise log model
│   ├── SetLog.swift                  # Set log model
│   └── DefaultWorkoutData.swift      # Seed data
├── ViewModels/
│   ├── WorkoutViewModel.swift        # Main workout VM
│   └── CalendarViewModel.swift       # Calendar VM
├── Views/
│   ├── MainTabView.swift             # Tab navigation
│   ├── Home/
│   │   └── HomeView.swift            # Dashboard
│   ├── Workout/
│   │   ├── WorkoutDaySelectionView.swift
│   │   └── ActiveWorkoutView.swift
│   ├── Calendar/
│   │   └── CalendarView.swift
│   ├── History/
│   │   ├── HistoryListView.swift
│   │   └── SessionDetailView.swift
│   ├── Exercise/
│   │   ├── ExerciseLibraryView.swift
│   │   └── ExerciseDetailView.swift
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Components/
│       ├── RestTimerView.swift
│       └── ProgressChartView.swift
├── Services/
│   ├── SchedulingService.swift       # Smart scheduling
│   ├── MediaService.swift            # Photo/video handling
│   └── DataService.swift             # Export/import
└── Utilities/
    ├── Extensions.swift              # Swift extensions
    └── Constants.swift               # App constants
```

## Default Workout Split

### Day 1: Push
- Incline Bench Press (3×8)
- Dumbbell Overhead Press (3×12)
- Machine Chest (3×12)
- Shoulder Side Laterals (3×15)
- Tricep Pushdowns (3×15)

### Day 2: Pull
- Lat Pulldown (3×12)
- Machine Rows (3×12)
- Dumbbell Rows (3×12)
- Rear Delt Flyes (3×15)
- Bicep Curls (3×15)

### Day 3: Legs
- Squat (3×6-8)
- Dumbbell RDL (3×8)
- Leg Press (3×12)
- Leg Extensions (3×12)
- Leg Curl (3×12)

### Day 4: Fullbody
- Squat (2×8)
- Barbell Bench Press (3×8)
- Cable Rows (3×12)
- Underhand Lat Pulldown (3×12)
- Tricep Overhead Extensions (3×12)
- Hammer Curl (3×12)

## Key Technologies

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's persistence framework
- **Swift Charts**: Native charting for progress visualization

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture:

- **Models**: SwiftData entities for persistent storage
- **Views**: SwiftUI views for UI
- **ViewModels**: ObservableObject classes for business logic
- **Services**: Utility classes for specific functionality

## License

MIT License

