# Exercise Reordering — Design

**Date:** 2026-03-06
**Status:** Approved

## Problem

`Exercise` (workout template) has no `sortOrder` field. SwiftData does not guarantee `@Relationship` array ordering on refetch, so any reorder done in `EditWorkoutDayView` is lost after the next fetch. The UI for reordering already exists — this design makes it work correctly.

`ExerciseLog` already has `order: Int` (used by `WorkoutManager.moveExercise`). This design brings `Exercise` into parity.

## Data Model

Add to `Exercise`:

```swift
var sortOrder: Int = 0
```

SwiftData will default all existing records to `0`. Order stabilises after the first reorder by the user.

## Persistence

`EditWorkoutDayView.moveExercises` already calls `workoutDay.exercises.move(fromOffsets:toOffset:)`. After the move, write `exercise.sortOrder = index` for each exercise in the array, then call `saveChanges()`.

## Fetch Ordering

Everywhere `WorkoutDay.exercises` is displayed for the template, sort by `sortOrder` ascending before use. Key call sites:

- `WorkoutPreviewView`
- `WorkoutDaySelectionView`
- `WorkoutManager.setupExerciseLogs` — ensure exercises are sorted when pre-populating a session

## Active Workout Fix

`ReorderExercisesSheet` has a bug: `if let count = log.sets.count` — `count` is `Int`, not `Int?`. Remove the `if let` and display count directly.

## Seed Data

Update `DefaultWorkoutData.createDefaultWorkouts()` to assign sequential `sortOrder` values (0, 1, 2, …) when creating exercises.

## Out of Scope

- Drag-to-reorder during an active workout already works via `WorkoutManager.moveExercise` — no changes needed there.
- No UI changes required — the "Reorder" button and `.onMove` handler already exist in `EditWorkoutDayView`.
