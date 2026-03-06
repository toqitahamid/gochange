# GoChange Codebase Audit - 2026-03-06

## Summary

Full audit of the GoChange iOS/watchOS app conducted across 5 parallel agents covering:
models, services, views, Watch app, and ViewModels/utilities.

## Critical Issues

### 1. Design System Fragmentation
Three conflicting design constant sources:
- `Theme.swift`: AppColors (orange #FF5500), AppLayout (cornerRadius: 24, cardPadding: 20)
- `Constants.swift`: AppConstants.WorkoutColors (teal #7CB9A8), Layout (cornerRadius: 16, cardPadding: 16)
- `Extensions.swift`: cardStyle() hardcodes radius: 16, shadow opacity: 0.1
- **Resolution:** Consolidate to Theme.swift as single source of truth

### 2. Hardcoded Mock Data in Production Views
| Location | Issue |
|----------|-------|
| JournalView:52-59 | ActivityRingsCard with hardcoded values (550/600, 45/60, 10/12) |
| JournalView:176 | Daily insight uses `Int.random(in: 5...12)%` |
| HomeViewModel:96 | HRV baseline hardcoded at 50ms |
| HomeViewModel:155 | Calories estimated as duration * 5 cal/min |
| FitnessViewModel:33 | cardioFocusPercentage hardcoded at 0.94 |
| FitnessViewModel:178-180 | Cardio strain hardcoded at 4.0 |
| FitnessDashboardView:452 | Load threshold "if load > 500" hardcoded |
| SleepView:38 | Sleep stages marked "Mock for now" |
| SessionHealthSummaryCard:174-176 | Cardio impact Before/After hardcoded as "--" |
| AnalyticsViewModel:23 | Default exercise "Bench Press" hardcoded |

### 3. Watch-to-iPhone Sync Broken
- `WatchConnectivityService.onWorkoutReceived` callback defined but never assigned
- Watch sends completed workouts that are silently lost
- No acknowledgment mechanism

### 4. Missing HealthKit Privacy Descriptions
Main app Info.plist missing:
- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription
(Present in Watch app Info.plist but not main app)

### 5. Dead Code
- `WorkoutViewModel.swift` - 147 lines, completely unused
- `UserProfileService.swift` - No references in views

### 6. Duplicate HealthKit on Watch
- `WatchWorkoutManager` manages HKWorkoutSession directly
- `WatchHealthKitService` also manages HKWorkoutSession
- Two parallel sessions create conflict risk

## Model Layer Assessment: SOLID

All 7 SwiftData models are well-designed:
- Proper cascade delete rules
- UUID-based references for history preservation
- Rich enums (SetType, GroupType, WeightUnit, MediaType)
- Good computed properties on RecoveryMetrics
- Missing: date indexes on RecoveryMetrics and RestDay

## Service Layer Assessment: GOOD LOGIC, POOR ARCHITECTURE

- HealthKitService: Comprehensive (72 read types), proper async/await
- ProgressiveOverloadService: Sound algorithm
- AnalyticsService: Rich computations (ACWR, 1RM, volume trends)
- WorkoutManager: Sophisticated state management (1151 lines)
- All services: No dependency injection, singleton coupling, silent error failures

## View Layer Assessment: POLISHED UI, BAD DATA

- UI quality: 8.5/10 - professional, consistent spacing
- Card styling: Inconsistent across views (3 different systems)
- Data connections: Multiple views show mock/hardcoded values
- Error/loading states: Almost entirely absent
- Watch UI: Excellent (DesignSystem.swift is production-ready)

## Widget Extension: EXCELLENT
- Professional Live Activity implementation
- Unified workout + rest timer in single activity
- Clean Dynamic Island views

## Files by Status

### Keep As-Is (no changes needed)
- All SwiftData models (7 files)
- DefaultWorkoutData.swift
- MetricModels.swift
- WorkoutActivityAttributes.swift (both copies)
- Watch DesignSystem.swift
- Watch Views (4 files)
- Widget extension (3 files)
- DataExportService.swift
- MediaService.swift

### Refactor (keep logic, change interface)
- HealthKitService.swift (add protocol)
- RecoveryService.swift (add protocol)
- NotificationService.swift (add protocol)
- WorkoutManager.swift (minor fixes)
- WatchConnectivityService.swift (fix receive handler)
- HomeViewModel.swift (wire real data)
- FitnessViewModel.swift (complete cardio)
- AnalyticsViewModel.swift (fix defaults)

### Rebuild (significant changes)
- Theme.swift (consolidate all constants)
- Extensions.swift (remove style constants)
- Constants.swift (remove, merge into Theme)
- JournalView.swift (wire real data)
- SleepView.swift (complete implementation)
- SessionHealthSummaryCard.swift (wire real data)

### Delete
- WorkoutViewModel.swift (unused)
- UserProfileService.swift (unused)

### Create New
- Utilities/ViewModifiers.swift
- Services/Protocols/HealthDataProviding.swift
- Services/Protocols/RecoveryProviding.swift
- Services/Protocols/NotificationProviding.swift
