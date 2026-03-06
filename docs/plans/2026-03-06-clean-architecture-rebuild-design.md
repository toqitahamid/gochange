# GoChange Clean Architecture Rebuild - Design Document

**Date:** 2026-03-06
**Approach:** B - Clean Architecture Rebuild
**Status:** Approved

---

## 1. Design Principles

- **Single source of truth** for all design tokens, constants, and layout values
- **Protocol-based services** with dependency injection (testable, swappable)
- **No mock data in production code** - every displayed value comes from a real source or shows an explicit empty state
- **Fail visible** - errors surface to the user, never swallow silently
- **Models preserved** - SwiftData schema is solid and stays as-is with minor additions

---

## 2. What We Keep (Unchanged)

### SwiftData Models
All 7 models stay as-is:
- `WorkoutDay`, `Exercise`, `WorkoutSession`, `ExerciseLog`, `SetLog`, `RestDay`, `RecoveryMetrics`
- `WorkoutActivityAttributes` (ActivityKit)
- `DefaultWorkoutData` (seeding)

Minor additions:
- Add `@Attribute(.index)` to `RecoveryMetrics.date` and `RestDay.date`
- Add `MetricModels.swift` stays (UI documentation only)

### Core Service Logic (internals preserved, interface refactored)
- HealthKit queries (all 72 read types, workout save)
- ProgressiveOverloadService suggestion algorithm
- AnalyticsService computation methods
- SchedulingService suggestion logic
- NotificationService scheduling
- DataExportService import/export
- MediaService file handling

### Watch App UI
- DesignSystem.swift (excellent quality)
- WorkoutListView, WorkoutDetailView, WatchActiveWorkoutView, SetInputView (all polished)

---

## 3. What We Rebuild

### 3.1 Unified Design System

**Delete:** `Constants.swift` (AppConstants), `Extensions.swift` cardStyle(), `AppTheme` bridge
**Keep:** `Theme.swift` as single source of truth

```
Utilities/
  Theme.swift          -- AppColors, AppFonts, AppLayout (SOLE source)
  Extensions.swift     -- Date, Color hex, TimeInterval (NO style constants)
  ViewModifiers.swift  -- .cardStyle(), .sectionHeader(), .pillStyle() (reference Theme.swift)
```

**Color System (finalized):**
- Primary accent: `#FF5500` (International Orange) - stays
- Background: `#F5F5F7` - stays
- Surface: `#FFFFFF` - stays
- Success: `#00C896` (Mint) - stays
- Warning: `#F59E0B` (Amber) - stays
- Error: `#EF4444` (Crimson) - stays
- Workout colors: Use `WorkoutDay.colorHex` from database (user-customizable)

**Layout Constants (single definition):**
- cornerRadius: 24pt (cards), 20pt (sub-components), 12pt (small elements)
- cardPadding: 20pt
- screenMargin: 20pt
- spacing: 12pt (standard), 20pt (section)
- Shadow: `Color.black.opacity(0.08), radius: 15, x: 0, y: 5` (main cards)
- Border: `Color.gray.opacity(0.15), lineWidth: 1`

### 3.2 Service Architecture

**Current:** Singletons with `shared` pattern, direct coupling
**New:** Protocol-based with injection via Environment

```swift
// Protocol definition
protocol HealthDataProviding {
    func getHeartRateVariability(for date: Date) async -> Double?
    func getRestingHeartRate(for date: Date) async -> Double?
    func getSleepData(for date: Date) async -> SleepData?
    // ... all current methods
}

// Concrete implementation
final class HealthKitService: HealthDataProviding { ... }

// Injection via SwiftUI Environment
struct HealthDataProviderKey: EnvironmentKey {
    static let defaultValue: HealthDataProviding = HealthKitService()
}
```

**Services to refactor:**

| Service | Current | New |
|---------|---------|-----|
| HealthKitService | Singleton | Protocol + Environment |
| RecoveryService | Singleton | Protocol + Environment |
| WorkoutManager | Singleton EnvironmentObject | Keep as EnvironmentObject (owns mutable state) |
| SchedulingService | Static methods | Static methods (fine as-is) |
| AnalyticsService | Static methods | Static methods (fine as-is) |
| ProgressiveOverloadService | Singleton | Static methods (stateless) |
| NotificationService | Singleton | Protocol + Environment |
| WatchConnectivityService | Singleton | Keep singleton (system requirement) |
| WorkoutActivityManager | Singleton | Keep singleton (ActivityKit requirement) |
| DataExportService | Class | Keep as-is (instantiated on demand) |
| MediaService | Class | Keep as-is (instantiated on demand) |
| UserProfileService | Singleton | Delete (unused, replace with UserDefaults direct) |

### 3.3 ViewModel Rebuild

**Delete:** `WorkoutViewModel.swift` (dead code, duplicates WorkoutManager)

**Rebuild with proper error/loading states:**

```swift
@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadState {
        case idle, loading, loaded, error(String)
    }

    @Published var loadState: LoadState = .idle
    @Published var recoveryScore: Int = 0
    // ... all metrics with real data sources

    // NO mock baselines - use rolling 14-day average for HRV baseline
    // NO Int.random() - use actual day-over-day comparison
    // NO hardcoded calorie estimation - use HealthKit active energy
}
```

**HomeViewModel fixes:**
- HRV baseline: Use rolling 14-day average instead of hardcoded 50ms
- Calorie estimation: Use `HealthKitService.getActiveEnergyBurned()` instead of `duration * 5`
- Daily insight: Use actual day-over-day recovery comparison, not `Int.random()`
- Activity rings: Wire to real HealthKit data (active energy, exercise time, stand hours)

**FitnessViewModel fixes:**
- `cardioFocusPercentage`: Calculate from actual cardio vs strength session ratio
- `cardioFocusStatus`: Derive from calculated percentage
- Strain calculation: Use real HealthKit active energy, not mocked 4.0
- Remove unused `calculateAdvancedMetrics()` or complete implementation

**AnalyticsViewModel fixes:**
- `selectedExerciseForTrend`: Default to first exercise from user's data, not "Bench Press"
- Add error states for all AnalyticsService calls

### 3.4 View Rebuilds

**Every view gets:**
1. Real data connections (no hardcoded values)
2. Proper loading states (skeleton/shimmer)
3. Empty states (when no data exists)
4. Error states (when data fetch fails)
5. Consistent card styling from ViewModifiers.swift

**JournalView (Home) fixes:**
- ActivityRingsCard: Wire to HealthKit (activeEnergy, exerciseTime, standHours)
- Daily insight: Real day-over-day comparison text
- All metrics from HomeViewModel (already mostly correct)

**FitnessDashboardView fixes:**
- Remove hardcoded "load > 500" threshold
- Remove "Mock lines" code
- Wire cardio analytics to real data

**SleepView fixes:**
- Complete sleep stages implementation with real HealthKit sleep analysis data
- Remove "Mock for now" comment and code

**SessionHealthSummaryCard fixes:**
- Wire cardio impact "Before/After" to real pre/post workout HR data

**RecoveryDetailSheet fixes:**
- Wire trend indicators to actual historical comparison

### 3.5 Watch App Fixes

**Critical: Fix Watch-to-iPhone sync**

```swift
// In GoChangeApp.swift or MainTabView.swift onAppear:
WatchConnectivityService.shared.onWorkoutReceived = { [weak self] workoutData in
    // Parse WatchWorkoutTransfer
    // Create WorkoutSession + ExerciseLogs + SetLogs
    // Insert into SwiftData ModelContext
    // Save
}
```

**Consolidate HealthKit on Watch:**
- Remove duplicate HKWorkoutSession from WatchWorkoutManager
- Use WatchHealthKitService exclusively
- Ensure heart rate, calories, and max HR are captured and transmitted

**Add HealthKit authorization:**
- Call `WatchHealthKitService.requestAuthorization()` on Watch app launch

**Add workout state persistence:**
- Save active workout to UserDefaults on Watch (like iPhone does)
- Restore on app relaunch

### 3.6 Missing Feature Completion

From the ROADMAP "Now" items:
1. Exercise reordering - DONE (ReorderExercisesSheet exists)
2. Activity rings with real data - needs wiring
3. Rest timer accuracy - needs review
4. Watch sync reliability - critical fix needed

From ROADMAP "Next" items (in scope for this rebuild):
1. Per-exercise history chart - ExerciseMiniChart exists but needs verification
2. Personal records detection during workouts - PR check exists in WorkoutManager
3. Per-exercise rest timer presets - add `defaultRestDuration` to Exercise model
4. Watch sessions sync back to iPhone - critical fix

Deferred (NOT in scope):
- Superset/circuit UI (model supports it via ExerciseLog.groupId, UI not built)
- Muscle soreness logging per session
- Watch complications
- Deload week detection
- Social/sharing features

---

## 4. File Structure (After Rebuild)

```
gochange/
  App/
    GoChangeApp.swift              -- Entry point, DI setup
  Models/                          -- UNCHANGED (minor index additions)
    WorkoutDay.swift
    Exercise.swift
    WorkoutSession.swift
    ExerciseLog.swift
    SetLog.swift
    RestDay.swift
    RecoveryMetrics.swift
    WorkoutActivityAttributes.swift
    MetricModels.swift
    DefaultWorkoutData.swift
  Services/
    Protocols/
      HealthDataProviding.swift    -- NEW: HealthKit protocol
      RecoveryProviding.swift      -- NEW: Recovery protocol
      NotificationProviding.swift  -- NEW: Notification protocol
    HealthKitService.swift         -- Refactored to conform to protocol
    RecoveryService.swift          -- Refactored to conform to protocol
    WorkoutManager.swift           -- Keep as EnvironmentObject
    WorkoutActivityManager.swift   -- Keep singleton
    SchedulingService.swift        -- Keep static
    AnalyticsService.swift         -- Keep static
    ProgressiveOverloadService.swift -- Convert to static
    NotificationService.swift      -- Refactored to conform to protocol
    DataExportService.swift        -- Keep as-is
    MediaService.swift             -- Keep as-is
    WatchConnectivityService.swift -- Fix onWorkoutReceived handler
  ViewModels/
    HomeViewModel.swift            -- Rebuild (real data, error states)
    FitnessViewModel.swift         -- Rebuild (real data, complete cardio)
    AnalyticsViewModel.swift       -- Fix defaults, add error states
    [WorkoutViewModel.swift]       -- DELETE
  Views/
    MainTabView.swift              -- Minor cleanup
    Home/
      JournalView.swift            -- Wire real data, fix insights
      ActivityRingsCard.swift       -- NEW: extracted, HealthKit-connected
      DailyInsightCard.swift       -- NEW: extracted, data-driven
    Fitness/
      FitnessDashboardView.swift   -- Remove mocks, wire real data
      Components/                  -- Keep, fix data connections
    Workout/                       -- Keep all, minor fixes
    Analytics/
      PerformanceAnalyticsView.swift -- Fix defaults
    Recovery/                      -- Fix trend indicators
    Sleep/
      SleepView.swift              -- Complete with real data
    History/
      SessionDetailView.swift      -- Fix cardio impact
      SessionHealthSummaryCard.swift -- Wire real data
    Exercise/                      -- Keep as-is
    Settings/                      -- Keep as-is
    Components/                    -- Keep, ensure Theme.swift usage
    LiveActivity/                  -- Keep as-is (excellent)
  Utilities/
    Theme.swift                    -- SOLE design system source
    Extensions.swift               -- Remove style constants
    ViewModifiers.swift            -- NEW: .cardStyle() etc referencing Theme

GoChangeWatch Watch App/          -- Fix sync, consolidate HealthKit
GoChangeWidget/                   -- Keep as-is (excellent)
```

---

## 5. Implementation Phases

### Phase 1: Foundation (Design System + Architecture)
- Consolidate Theme.swift as single source
- Create ViewModifiers.swift
- Clean up Constants.swift and Extensions.swift
- Create service protocols
- Delete WorkoutViewModel.swift
- Delete UserProfileService.swift
- Add missing HealthKit privacy descriptions to Info.plist
- Add date indexes to models

### Phase 2: Data Layer (Wire Real Data)
- Rebuild HomeViewModel with real data connections
- Fix FitnessViewModel (cardio, strain calculations)
- Fix AnalyticsViewModel defaults
- Wire ActivityRingsCard to HealthKit
- Fix daily insight text generation
- Complete SleepView with real sleep stages
- Fix SessionHealthSummaryCard cardio impact
- Fix RecoveryDetailSheet trend indicators
- Remove all hardcoded mock data

### Phase 3: Error Handling + States
- Add LoadState enum to all ViewModels
- Add loading skeletons/shimmer to all data views
- Add empty states for zero-data scenarios
- Add error states with retry actions
- Add proper error propagation in services

### Phase 4: Watch App
- Implement onWorkoutReceived handler on iPhone
- Consolidate Watch HealthKit into WatchHealthKitService only
- Add HealthKit authorization on Watch launch
- Add workout state persistence on Watch
- Verify heart rate transmission end-to-end

### Phase 5: Polish + Remaining Features
- Per-exercise rest timer presets (add defaultRestDuration to Exercise)
- Verify ExerciseMiniChart works with real data
- Verify PR detection during active workouts
- Audit all views for consistent card styling
- Remove any remaining dead code
- Final build verification

---

## 6. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| HealthKit returns nil on simulator | Add graceful fallbacks, test with empty states |
| SwiftData migration needed | No schema changes to existing models, only additive |
| Watch sync data format mismatch | Version the transfer format, validate on receive |
| Design system migration breaks views | Phase 1 is foundation-only, views updated in Phase 2 |
| Lost workout data during rebuild | Never modify existing persistence; additive changes only |

---

## 7. Out of Scope

- Superset/circuit UI (model ready, UI deferred)
- Muscle soreness logging per session
- Watch complications
- Deload week detection
- Social/sharing features
- iPad optimization
- Cloud sync
- New workout types beyond current schema
