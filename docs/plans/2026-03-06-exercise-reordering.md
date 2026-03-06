# Exercise Reordering Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Persist exercise order in the `Exercise` model so that drag-to-reorder in `EditWorkoutDayView` survives SwiftData refetches.

**Architecture:** Add `sortOrder: Int = 0` to `Exercise`. Update all call sites that iterate `WorkoutDay.exercises` to sort by `sortOrder` first. Update `moveExercises` to write new sort order values after a drag. Fix a type bug in `ReorderExercisesSheet`.

**Tech Stack:** Swift, SwiftData, SwiftUI `.onMove`

---

### Task 1: Add `sortOrder` to `Exercise` model

**Files:**
- Modify: `gochange/Models/Exercise.swift:9-16`

**Step 1: Add the field**

In `Exercise.swift`, add after `var defaultRestDuration`:

```swift
var sortOrder: Int = 0
```

Final property block should look like:

```swift
var defaultSets: Int
var defaultWeight: Double?
var defaultReps: String
var muscleGroup: String
var notes: String?
var mediaURL: String?
var mediaType: MediaType?
var defaultRestDuration: TimeInterval = AppConstants.Defaults.restTimerDuration
var sortOrder: Int = 0
```

**Step 2: Build to verify no errors**

```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator26.2 -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v Watch | grep -v Asset
```

Expected: no output (zero errors)

**Step 3: Commit**

```bash
git add gochange/Models/Exercise.swift
git commit -m "feat: add sortOrder field to Exercise model"
```

---

### Task 2: Assign sort orders in `DefaultWorkoutData`

**Files:**
- Modify: `gochange/Models/DefaultWorkoutData.swift:4-65`

**Step 1: Update `createDefaultWorkouts` to assign sort orders**

`Exercise` has no `sortOrder` init parameter — set it after creation. Replace the inline array literals with a helper closure that assigns sort order. The pattern is the same for all 4 workout days.

At the top of `createDefaultWorkouts`, add a helper:

```swift
func ordered(_ exercises: [Exercise]) -> [Exercise] {
    exercises.enumerated().forEach { i, e in e.sortOrder = i }
    return exercises
}
```

Then wrap each `exercises:` array:

```swift
exercises: ordered([
    Exercise(name: "Incline Bench Press", ...),
    ...
])
```

Apply this to all 4 `WorkoutDay` definitions (Push, Pull, Legs, Fullbody).

**Step 2: Build**

```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator26.2 -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v Watch | grep -v Asset
```

Expected: no output

**Step 3: Commit**

```bash
git add gochange/Models/DefaultWorkoutData.swift
git commit -m "feat: assign sortOrder to default exercises"
```

---

### Task 3: Sort exercises at fetch call sites

The following call sites iterate `WorkoutDay.exercises` without sorting — they must sort by `sortOrder` ascending so the order is stable after any refetch.

**Files:**
- Modify: `gochange/Services/WorkoutManager.swift:595`
- Modify: `gochange/Views/Workout/WorkoutPreviewView.swift:195`
- Modify: `gochange/Views/Workout/EditWorkoutDayView.swift:230`

**Step 1: `WorkoutManager.setupExerciseLogs` (line 595)**

Change:
```swift
exerciseLogs = workoutDay.exercises.enumerated().map { index, exercise in
```
To:
```swift
exerciseLogs = workoutDay.exercises
    .sorted { $0.sortOrder < $1.sortOrder }
    .enumerated().map { index, exercise in
```

**Step 2: `WorkoutPreviewView` (line 195)**

Change:
```swift
ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
```
To:
```swift
ForEach(Array(workoutDay.exercises.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { index, exercise in
```

**Step 3: `EditWorkoutDayView` (line 230)**

Change:
```swift
ForEach(Array(workoutDay.exercises.enumerated()), id: \.element.id) { index, exercise in
```
To:
```swift
ForEach(Array(workoutDay.exercises.sorted { $0.sortOrder < $1.sortOrder }.enumerated()), id: \.element.id) { index, exercise in
```

**Step 4: Build**

```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator26.2 -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v Watch | grep -v Asset
```

Expected: no output

**Step 5: Commit**

```bash
git add gochange/Services/WorkoutManager.swift gochange/Views/Workout/WorkoutPreviewView.swift gochange/Views/Workout/EditWorkoutDayView.swift
git commit -m "feat: sort exercises by sortOrder at all fetch call sites"
```

---

### Task 4: Persist sort order after drag-to-reorder

**Files:**
- Modify: `gochange/Views/Workout/EditWorkoutDayView.swift:332-335`

**Step 1: Update `moveExercises`**

Current:
```swift
private func moveExercises(from source: IndexSet, to destination: Int) {
    workoutDay.exercises.move(fromOffsets: source, toOffset: destination)
    saveChanges()
}
```

Replace with:
```swift
private func moveExercises(from source: IndexSet, to destination: Int) {
    workoutDay.exercises.move(fromOffsets: source, toOffset: destination)
    for (index, exercise) in workoutDay.exercises.enumerated() {
        exercise.sortOrder = index
    }
    saveChanges()
}
```

**Step 2: Build**

```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator26.2 -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v Watch | grep -v Asset
```

Expected: no output

**Step 3: Commit**

```bash
git add gochange/Views/Workout/EditWorkoutDayView.swift
git commit -m "feat: persist sortOrder after exercise drag-to-reorder"
```

---

### Task 5: Fix `ReorderExercisesSheet` type bug

**Files:**
- Modify: `gochange/Views/Workout/ReorderExercisesSheet.swift:14-20`

**Step 1: Fix the `if let` on a non-optional**

`log.sets` is `[SetLog]` — `count` is `Int`, not `Int?`. The `if let` never binds.

Current:
```swift
if let count = log.sets.count {
    Text("\(count) sets")
        .font(.caption)
        .foregroundColor(.secondary)
}
```

Replace with:
```swift
Text("\(log.sets.count) sets")
    .font(.caption)
    .foregroundColor(.secondary)
```

**Step 2: Build**

```bash
xcodebuild -project gochange.xcodeproj -target gochange -sdk iphonesimulator26.2 -configuration Debug build CODE_SIGNING_ALLOWED=NO 2>&1 | grep "error:" | grep -v Watch | grep -v Asset
```

Expected: no output

**Step 3: Commit**

```bash
git add gochange/Views/Workout/ReorderExercisesSheet.swift
git commit -m "fix: show set count in ReorderExercisesSheet"
```
