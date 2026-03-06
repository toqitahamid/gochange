# GoChange Clean Architecture Rebuild - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild GoChange with clean architecture, real data connections, TDD, and proper error handling while preserving the solid SwiftData models and core service logic.

**Architecture:** Protocol-based services injected via SwiftUI Environment, MVVM with proper LoadState enums, unified design system from single Theme.swift source. Red/green TDD for all service and ViewModel logic.

**Tech Stack:** Swift, SwiftUI, SwiftData, HealthKit, XCTest, ActivityKit, WatchConnectivity

**TDD Approach:** Since HealthKit and SwiftData require specific entitlements, we use protocol-based mocks. Every service gets a protocol, every ViewModel gets tested against mocks. Red (write failing test) -> Green (minimal implementation) -> Refactor.

---

## Phase 1: Foundation (Design System + Architecture + Test Infrastructure)

### Task 1: Create Test Target

**Files:**
- Create: `gochangeTests/GoChangeTests.swift`
- Modify: `gochange.xcodeproj/project.pbxproj` (via Xcode CLI)

**Step 1: Create test target directory and initial test file**

```bash
mkdir -p gochangeTests
```

```swift
// gochangeTests/GoChangeTests.swift
import XCTest
@testable import gochange

final class GoChangeTests: XCTestCase {
    func testProjectCompiles() {
        XCTAssertTrue(true)
    }
}
```

**Step 2: Add test target to Xcode project**

Use `xcodebuild` or add manually. The test target needs `@testable import gochange` access, which requires the main target's module to be importable.

Since no simulator runtimes are installed, tests will be verified by compilation checks and run when simulators are available. Structure tests to be runnable.

**Step 3: Commit**

```
test: add XCTest target with initial test file
```

---

### Task 2: Consolidate Design System

**Files:**
- Modify: `gochange/Utilities/Theme.swift`
- Modify: `gochange/Utilities/Extensions.swift`
- Create: `gochange/Utilities/ViewModifiers.swift`
- Modify: `gochange/Utilities/Constants.swift`

**Step 1: Write failing test for Theme constants**

```swift
// gochangeTests/ThemeTests.swift
import XCTest
@testable import gochange

final class ThemeTests: XCTestCase {
    func testAppColorsExist() {
        // Verify all colors resolve without crash
        let _ = AppColors.primary
        let _ = AppColors.secondary
        let _ = AppColors.background
        let _ = AppColors.surface
        let _ = AppColors.textPrimary
        let _ = AppColors.textSecondary
        let _ = AppColors.textTertiary
        let _ = AppColors.success
        let _ = AppColors.warning
        let _ = AppColors.error
    }

    func testAppLayoutConstants() {
        XCTAssertEqual(AppLayout.cornerRadius, 24.0)
        XCTAssertEqual(AppLayout.miniRadius, 20.0)
        XCTAssertEqual(AppLayout.cardPadding, 20.0)
        XCTAssertEqual(AppLayout.margin, 20.0)
        XCTAssertEqual(AppLayout.spacing, 12.0)
    }

    func testAppShadowConstants() {
        XCTAssertEqual(AppShadow.cardRadius, 15.0)
        XCTAssertEqual(AppShadow.cardOpacity, 0.08)
        XCTAssertEqual(AppShadow.cardY, 5.0)
    }

    func testWorkoutColorForName() {
        // Should return a color for known workout names
        let pushColor = AppColors.workoutColor(for: "Push")
        XCTAssertNotNil(pushColor)
    }
}
```

**Step 2: Update Theme.swift to be the single source of truth**

```swift
// gochange/Utilities/Theme.swift
import SwiftUI

// MARK: - Color System

struct AppColors {
    // Brand
    static let primary = Color(hex: "FF5500")
    static let secondary = Color(hex: "1C1C1E")

    // Backgrounds
    static let background = Color(hex: "F5F5F7")
    static let surface = Color(hex: "FFFFFF")

    // Text
    static let textPrimary = Color(hex: "111827")
    static let textSecondary = Color(hex: "6B7280")
    static let textTertiary = Color(hex: "9CA3AF")

    // Semantic
    static let success = Color(hex: "00C896")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // Workout day colors (fallback when colorHex not set)
    static func workoutColor(for name: String) -> Color {
        switch name.lowercased() {
        case "push": return Color(hex: "FF5500")
        case "pull": return Color(hex: "5C7CFA")
        case "legs": return Color(hex: "343A40")
        case "fullbody", "full body": return Color(hex: "00C896")
        case "running": return Color(hex: "FF6B6B")
        case "cycling": return Color(hex: "4ECDC4")
        case "walking": return Color(hex: "FFD93D")
        default: return Color(hex: "5C7CFA")
        }
    }
}

// MARK: - Typography

struct AppFonts {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func rounded(_ size: CGFloat = 20, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static func mono(_ size: CGFloat = 17, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Layout

struct AppLayout {
    static let margin: CGFloat = 20.0
    static let cardPadding: CGFloat = 20.0
    static let spacing: CGFloat = 12.0
    static let sectionSpacing: CGFloat = 20.0
    static let cornerRadius: CGFloat = 24.0
    static let miniRadius: CGFloat = 20.0
    static let smallRadius: CGFloat = 12.0
}

// MARK: - Shadows

struct AppShadow {
    static let cardRadius: CGFloat = 15.0
    static let cardOpacity: Double = 0.08
    static let cardX: CGFloat = 0
    static let cardY: CGFloat = 5.0

    static let subCardRadius: CGFloat = 10.0
    static let subCardOpacity: Double = 0.05
    static let subCardY: CGFloat = 4.0
}

// MARK: - Border

struct AppBorder {
    static let color = Color.gray.opacity(0.15)
    static let width: CGFloat = 1.0
}

// MARK: - RIR Labels

struct RIRLabels {
    static func label(for rir: Int) -> String {
        switch rir {
        case 0: return "Failure"
        case 1: return "1 left"
        case 2: return "2 left"
        case 3: return "3 left"
        case 4: return "4 left"
        case 5: return "5+ left"
        default: return "\(rir) left"
        }
    }

    static func color(for rir: Int) -> Color {
        switch rir {
        case 0: return AppColors.error
        case 1: return Color(hex: "FF9500")
        case 2: return AppColors.warning
        case 3: return Color(hex: "FFD60A")
        case 4: return AppColors.success
        case 5: return Color(hex: "30D158")
        default: return AppColors.textSecondary
        }
    }
}

// MARK: - Muscle Groups

struct MuscleGroups {
    static let all = ["Chest", "Back", "Shoulders", "Biceps", "Triceps",
                      "Quads", "Hamstrings", "Glutes", "Calves", "Core", "Cardio"]

    static let radarGroups = ["Chest", "Back", "Legs", "Shoulders", "Core", "Arms"]

    static func normalize(_ group: String) -> String {
        switch group.lowercased() {
        case "quads", "hamstrings", "glutes", "calves": return "Legs"
        case "biceps", "triceps": return "Arms"
        case "abs", "obliques": return "Core"
        case "rear delts", "front delts", "side delts": return "Shoulders"
        case "lats", "traps", "rhomboids": return "Back"
        case "pecs": return "Chest"
        default: return group
        }
    }
}
```

**Step 3: Create ViewModifiers.swift**

```swift
// gochange/Utilities/ViewModifiers.swift
import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.cornerRadius))
            .shadow(color: Color.black.opacity(AppShadow.cardOpacity),
                    radius: AppShadow.cardRadius,
                    x: AppShadow.cardX,
                    y: AppShadow.cardY)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.cornerRadius)
                    .stroke(AppBorder.color, lineWidth: AppBorder.width)
            )
    }
}

struct SubCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppLayout.miniRadius))
            .shadow(color: Color.black.opacity(AppShadow.subCardOpacity),
                    radius: AppShadow.subCardRadius,
                    x: 0,
                    y: AppShadow.subCardY)
            .overlay(
                RoundedRectangle(cornerRadius: AppLayout.miniRadius)
                    .stroke(AppBorder.color, lineWidth: AppBorder.width)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func subCardStyle() -> some View {
        modifier(SubCardStyle())
    }
}
```

**Step 4: Clean up Constants.swift - remove duplicates, keep only non-theme constants**

Remove `AppConstants.Layout`, `AppConstants.WorkoutColors`, `AppTheme` bridge.
Keep only `AppConstants.RIR` (redirect to RIRLabels), `AppConstants.Defaults`, `AppConstants.muscleGroups` (redirect to MuscleGroups).

**Step 5: Clean up Extensions.swift - remove cardStyle()**

Remove the `cardStyle()` View extension (now in ViewModifiers.swift). Keep Color hex init, Date extensions, TimeInterval formatting.

**Step 6: Commit**

```
refactor: consolidate design system into single Theme.swift source of truth
```

---

### Task 3: Create Service Protocols

**Files:**
- Create: `gochange/Services/Protocols/HealthDataProviding.swift`
- Create: `gochange/Services/Protocols/RecoveryProviding.swift`
- Create: `gochange/Services/Protocols/NotificationProviding.swift`
- Create: `gochangeTests/Mocks/MockHealthDataProvider.swift`
- Create: `gochangeTests/Mocks/MockRecoveryProvider.swift`

**Step 1: Write the HealthDataProviding protocol**

```swift
// gochange/Services/Protocols/HealthDataProviding.swift
import Foundation

struct SleepData {
    let totalDuration: TimeInterval
    let deepDuration: TimeInterval
    let remDuration: TimeInterval
    let coreDuration: TimeInterval
    let quality: Double // 0.0 - 1.0
    let startDate: Date?
    let endDate: Date?

    var deepPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return deepDuration / totalDuration
    }

    var remPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return remDuration / totalDuration
    }
}

protocol HealthDataProviding: Sendable {
    // Vitals
    func getHeartRateVariability(for date: Date) async -> Double?
    func getRestingHeartRate(for date: Date) async -> Double?
    func getRespiratoryRate(for date: Date) async -> Double?
    func getOxygenSaturation(for date: Date) async -> Double?
    func getBodyTemperature(for date: Date) async -> Double?
    func getVO2Max() async -> Double?

    // Activity
    func getStepCount(for date: Date) async -> Int
    func getActiveEnergyBurned(for date: Date) async -> Double?
    func getExerciseTime(for date: Date) async -> Double?
    func getStandHours(for date: Date) async -> Int?
    func getWalkingRunningDistance(for date: Date) async -> Double?

    // Sleep
    func getSleepData(for date: Date) async -> SleepData?

    // Historical
    func getHistoricalHRV(days: Int) async -> [(date: Date, value: Double)]
    func getHistoricalRHR(days: Int) async -> [(date: Date, value: Double)]
    func getHistoricalSleep(days: Int) async -> [(date: Date, duration: TimeInterval)]
    func getHistoricalActiveEnergy(days: Int) async -> [(date: Date, value: Double)]
    func getDailyActivityStats(days: Int) async -> [(date: Date, count: Int)]

    // Workouts
    func saveWorkout(workoutName: String, startTime: Date, endTime: Date,
                     duration: TimeInterval, totalVolume: Double) async throws

    // Authorization
    func requestAuthorization() async throws
}
```

**Step 2: Write MockHealthDataProvider for tests**

```swift
// gochangeTests/Mocks/MockHealthDataProvider.swift
import Foundation
@testable import gochange

final class MockHealthDataProvider: HealthDataProviding, @unchecked Sendable {
    var hrvValue: Double? = 45.0
    var rhrValue: Double? = 62.0
    var respiratoryRate: Double? = 16.0
    var oxygenSaturation: Double? = 98.0
    var bodyTemperature: Double? = 36.6
    var vo2Max: Double? = 42.0
    var stepCount: Int = 8500
    var activeEnergy: Double? = 450.0
    var exerciseTime: Double? = 45.0
    var standHours: Int? = 10
    var walkingDistance: Double? = 5.2
    var sleepData: SleepData? = SleepData(
        totalDuration: 7.5 * 3600,
        deepDuration: 1.5 * 3600,
        remDuration: 1.8 * 3600,
        coreDuration: 4.2 * 3600,
        quality: 0.82,
        startDate: nil, endDate: nil
    )
    var savedWorkouts: [(String, Date, Date)] = []

    func getHeartRateVariability(for date: Date) async -> Double? { hrvValue }
    func getRestingHeartRate(for date: Date) async -> Double? { rhrValue }
    func getRespiratoryRate(for date: Date) async -> Double? { respiratoryRate }
    func getOxygenSaturation(for date: Date) async -> Double? { oxygenSaturation }
    func getBodyTemperature(for date: Date) async -> Double? { bodyTemperature }
    func getVO2Max() async -> Double? { vo2Max }
    func getStepCount(for date: Date) async -> Int { stepCount }
    func getActiveEnergyBurned(for date: Date) async -> Double? { activeEnergy }
    func getExerciseTime(for date: Date) async -> Double? { exerciseTime }
    func getStandHours(for date: Date) async -> Int? { standHours }
    func getWalkingRunningDistance(for date: Date) async -> Double? { walkingDistance }
    func getSleepData(for date: Date) async -> SleepData? { sleepData }
    func getHistoricalHRV(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getHistoricalRHR(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getHistoricalSleep(days: Int) async -> [(date: Date, duration: TimeInterval)] { [] }
    func getHistoricalActiveEnergy(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getDailyActivityStats(days: Int) async -> [(date: Date, count: Int)] { [] }
    func saveWorkout(workoutName: String, startTime: Date, endTime: Date,
                     duration: TimeInterval, totalVolume: Double) async throws {
        savedWorkouts.append((workoutName, startTime, endTime))
    }
    func requestAuthorization() async throws {}
}
```

**Step 3: Write RecoveryProviding protocol**

```swift
// gochange/Services/Protocols/RecoveryProviding.swift
import Foundation
import SwiftData

protocol RecoveryProviding {
    func syncRecoveryData(context: ModelContext) async
    func getTodaysMetrics(context: ModelContext) async -> RecoveryMetrics?
}
```

**Step 4: Write NotificationProviding protocol**

```swift
// gochange/Services/Protocols/NotificationProviding.swift
import Foundation

protocol NotificationProviding {
    func requestAuthorization() async
    func scheduleRestTimerNotification(endTime: Date)
    func cancelRestTimerNotification()
    func scheduleWorkoutReminder(weekday: Int, hour: Int, minute: Int, workoutName: String)
    func cancelWorkoutReminder(weekday: Int)
}
```

**Step 5: Commit**

```
feat: add service protocols and mock implementations for TDD
```

---

### Task 4: Make HealthKitService Conform to Protocol

**Files:**
- Modify: `gochange/Services/HealthKitService.swift`

**Step 1: Add protocol conformance**

Add `: HealthDataProviding` to the class declaration. Add any missing methods. Ensure existing method signatures match the protocol. Add `getStandHours()` and `getExerciseTime()` if missing.

**Step 2: Verify existing methods match protocol signatures**

Review each protocol method and ensure HealthKitService has a matching implementation. Add stubs for any missing methods that query HealthKit.

**Step 3: Commit**

```
refactor: conform HealthKitService to HealthDataProviding protocol
```

---

### Task 5: Delete Dead Code + Add Model Indexes

**Files:**
- Delete: `gochange/ViewModels/WorkoutViewModel.swift`
- Delete: `gochange/Services/UserProfileService.swift`
- Modify: `gochange/Models/RecoveryMetrics.swift` (add index)
- Modify: `gochange/Models/RestDay.swift` (add index)
- Modify: `gochange/Views/Fitness/JournalView.swift` (remove UserProfileService reference)
- Modify: `gochange/Views/Settings/AccountSettingsView.swift` (remove UserProfileService reference)

**Step 1: Delete WorkoutViewModel.swift**

Remove file. Grep for any remaining references and remove them.

**Step 2: Delete UserProfileService.swift**

Remove file. Replace references in JournalView and AccountSettingsView with direct UserDefaults access or remove entirely.

**Step 3: Add date indexes**

```swift
// In RecoveryMetrics.swift, add to date property:
@Attribute(.index) var date: Date

// In RestDay.swift, add to date property:
@Attribute(.index) var date: Date
```

Note: `.index` attribute was added in later SwiftData versions. If the project targets iOS 17.0, use a FetchDescriptor with sort instead. Verify compatibility.

**Step 4: Commit**

```
chore: delete unused WorkoutViewModel and UserProfileService, add date indexes
```

---

### Task 6: Add HealthKit Privacy Descriptions to Info.plist

**Files:**
- Modify: `gochange/Info.plist`

**Step 1: Add missing privacy keys**

```xml
<key>NSHealthShareUsageDescription</key>
<string>GoChange reads your health data to show recovery metrics, sleep analysis, heart rate variability, and workout history.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>GoChange saves your completed workouts to Apple Health so they appear in your health records.</string>
```

**Step 2: Commit**

```
fix: add missing HealthKit privacy descriptions to main app Info.plist
```

---

## Phase 2: Data Layer (Wire Real Data with TDD)

### Task 7: Rebuild HomeViewModel with Real Data (TDD)

**Files:**
- Create: `gochangeTests/ViewModels/HomeViewModelTests.swift`
- Modify: `gochange/ViewModels/HomeViewModel.swift`

**Step 1: Write failing tests for recovery score calculation**

```swift
// gochangeTests/ViewModels/HomeViewModelTests.swift
import XCTest
@testable import gochange

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockHealth: MockHealthDataProvider!

    override func setUp() {
        mockHealth = MockHealthDataProvider()
        sut = HomeViewModel(healthProvider: mockHealth)
    }

    // MARK: - Recovery Score

    func testRecoveryScore_withGoodHRVAndLowRHR_returnsHighScore() async {
        mockHealth.hrvValue = 65.0  // Good HRV
        mockHealth.rhrValue = 55.0  // Low RHR

        await sut.loadData(context: nil)

        XCTAssertGreaterThanOrEqual(sut.recoveryScore, 70)
    }

    func testRecoveryScore_withLowHRVAndHighRHR_returnsLowScore() async {
        mockHealth.hrvValue = 20.0  // Low HRV
        mockHealth.rhrValue = 85.0  // High RHR

        await sut.loadData(context: nil)

        XCTAssertLessThanOrEqual(sut.recoveryScore, 40)
    }

    func testRecoveryScore_withNoData_returnsZero() async {
        mockHealth.hrvValue = nil
        mockHealth.rhrValue = nil

        await sut.loadData(context: nil)

        XCTAssertEqual(sut.recoveryScore, 0)
    }

    // MARK: - Sleep Score

    func testSleepScore_withGoodSleep_returnsHighScore() async {
        mockHealth.sleepData = SleepData(
            totalDuration: 8 * 3600,
            deepDuration: 1.8 * 3600,
            remDuration: 2.0 * 3600,
            coreDuration: 4.2 * 3600,
            quality: 0.9,
            startDate: nil, endDate: nil
        )

        await sut.loadData(context: nil)

        XCTAssertGreaterThanOrEqual(sut.sleepScore, 70)
    }

    func testSleepScore_withNoData_returnsZero() async {
        mockHealth.sleepData = nil

        await sut.loadData(context: nil)

        XCTAssertEqual(sut.sleepScore, 0)
    }

    // MARK: - Strain Score

    func testStrainScore_withActiveEnergy_calculatesFromRealData() async {
        mockHealth.activeEnergy = 600.0
        mockHealth.exerciseTime = 60.0

        await sut.loadData(context: nil)

        XCTAssertGreaterThan(sut.strainScore, 0)
    }

    func testStrainScore_withNoActivity_returnsZero() async {
        mockHealth.activeEnergy = nil
        mockHealth.exerciseTime = nil

        await sut.loadData(context: nil)

        XCTAssertEqual(sut.strainScore, 0)
    }

    // MARK: - Activity Rings

    func testActivityRings_populatedFromHealthKit() async {
        mockHealth.activeEnergy = 450.0
        mockHealth.exerciseTime = 35.0
        mockHealth.standHours = 9

        await sut.loadData(context: nil)

        XCTAssertEqual(sut.moveCalories, 450.0)
        XCTAssertEqual(sut.exerciseMinutes, 35.0)
        XCTAssertEqual(sut.standHours, 9)
    }

    // MARK: - Load State

    func testLoadState_startsIdle() {
        XCTAssertEqual(sut.loadState, .idle)
    }

    func testLoadState_transitionsToLoadedAfterFetch() async {
        await sut.loadData(context: nil)

        XCTAssertEqual(sut.loadState, .loaded)
    }

    // MARK: - Daily Insight

    func testDailyInsight_neverContainsRandomValues() async {
        await sut.loadData(context: nil)

        let insight = sut.insightText
        // Should not contain random numbers - should be deterministic
        let insight2 = sut.insightText
        XCTAssertEqual(insight, insight2, "Insight text should be deterministic, not random")
    }
}
```

**Step 2: Run tests to verify they fail (HomeViewModel doesn't accept healthProvider yet)**

**Step 3: Rebuild HomeViewModel with dependency injection**

```swift
// gochange/ViewModels/HomeViewModel.swift
import SwiftUI
import SwiftData
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Load State
    enum LoadState: Equatable {
        case idle, loading, loaded, error(String)
    }

    @Published var loadState: LoadState = .idle

    // MARK: - Scores (0-100)
    @Published var recoveryScore: Int = 0
    @Published var sleepScore: Int = 0
    @Published var strainScore: Int = 0

    // MARK: - Vitals
    @Published var hrv: Double = 0
    @Published var restingHR: Double = 0
    @Published var respiratoryRate: Double?
    @Published var oxygenSaturation: Double?
    @Published var bodyTemperature: Double?
    @Published var vo2Max: Double?
    @Published var stepCount: Int = 0

    // MARK: - Sleep
    @Published var sleepData: SleepData?

    // MARK: - Activity Rings
    @Published var moveCalories: Double = 0
    @Published var moveTarget: Double = 600
    @Published var exerciseMinutes: Double = 0
    @Published var exerciseTarget: Double = 30
    @Published var standHours: Int = 0
    @Published var standTarget: Int = 12

    // MARK: - Workouts
    @Published var recentWorkouts: [WorkoutSession] = []

    // MARK: - Greeting
    @Published var greeting: String = ""

    // MARK: - Dependencies
    private let healthProvider: HealthDataProviding

    init(healthProvider: HealthDataProviding = HealthKitService.shared) {
        self.healthProvider = healthProvider
        updateGreeting()
    }

    func loadData(context: ModelContext?) async {
        loadState = .loading

        async let vitalsTask: () = loadVitals()
        async let sleepTask: () = loadSleep()
        async let activityTask: () = loadActivity()
        if let context = context {
            async let workoutsTask: () = loadWorkouts(context: context)
            _ = await (vitalsTask, sleepTask, activityTask, workoutsTask)
        } else {
            _ = await (vitalsTask, sleepTask, activityTask)
        }

        calculateScores()
        loadState = .loaded
    }

    private func loadVitals() async {
        let today = Calendar.current.startOfDay(for: Date())
        hrv = await healthProvider.getHeartRateVariability(for: today) ?? 0
        restingHR = await healthProvider.getRestingHeartRate(for: today) ?? 0
        respiratoryRate = await healthProvider.getRespiratoryRate(for: today)
        oxygenSaturation = await healthProvider.getOxygenSaturation(for: today)
        bodyTemperature = await healthProvider.getBodyTemperature(for: today)
        stepCount = await healthProvider.getStepCount(for: today)
        vo2Max = await healthProvider.getVO2Max()
    }

    private func loadSleep() async {
        let today = Calendar.current.startOfDay(for: Date())
        sleepData = await healthProvider.getSleepData(for: today)
    }

    private func loadActivity() async {
        let today = Date()
        moveCalories = await healthProvider.getActiveEnergyBurned(for: today) ?? 0
        exerciseMinutes = await healthProvider.getExerciseTime(for: today) ?? 0
        standHours = await healthProvider.getStandHours(for: today) ?? 0
    }

    private func loadWorkouts(context: ModelContext) async {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted && $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentWorkouts = (try? context.fetch(descriptor)) ?? []
    }

    private func calculateScores() {
        // Recovery: Based on HRV and RHR
        if hrv > 0 || restingHR > 0 {
            let hrvScore = hrv > 0 ? min(max((hrv / 60.0) * 60.0 + 20.0, 0), 100) : 50
            let rhrScore = restingHR > 0 ? min(max((65.0 / max(restingHR, 40.0)) * 60.0 + 10.0, 0), 100) : 50
            recoveryScore = Int((hrvScore + rhrScore) / 2.0)
        } else {
            recoveryScore = 0
        }

        // Sleep: Based on duration and quality
        if let sleep = sleepData {
            let hours = sleep.totalDuration / 3600.0
            let durationScore = min(max((hours / 8.0) * 60.0 + 20.0, 0), 100)
            let qualityScore = sleep.quality * 100.0
            sleepScore = Int((durationScore + qualityScore) / 2.0)
        } else {
            sleepScore = 0
        }

        // Strain: Based on active energy and exercise time
        if let energy = Optional(moveCalories), energy > 0 {
            let energyScore = min(energy / 8.0, 100)
            let exerciseScore = min(exerciseMinutes * 1.5, 100)
            strainScore = Int((energyScore + exerciseScore) / 2.0)
        } else {
            strainScore = 0
        }
    }

    // MARK: - Deterministic Insight Text
    var insightText: String {
        if recoveryScore >= 80 {
            return "Recovery is strong today. Great conditions for a challenging workout."
        } else if recoveryScore >= 60 {
            return "Solid recovery. You're ready for a normal training session."
        } else if recoveryScore >= 40 {
            return "Moderate recovery. Consider a lighter intensity today."
        } else if recoveryScore > 0 {
            return "Recovery is low. Prioritize rest or light movement today."
        } else {
            return "Connect Health to see personalized insights based on your data."
        }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good Morning"
        case 12..<17: greeting = "Good Afternoon"
        case 17..<22: greeting = "Good Evening"
        default: greeting = "Good Night"
        }
    }
}
```

**Step 4: Run tests to verify they pass**

**Step 5: Commit**

```
feat: rebuild HomeViewModel with DI, real data, deterministic insights (TDD)
```

---

### Task 8: Wire Activity Rings to Real HealthKit Data (TDD)

**Files:**
- Modify: `gochange/Views/Fitness/JournalView.swift`
- Modify: `gochange/Views/Home/SummaryRingsView.swift` (ActivityRingsCard)

**Step 1: Update JournalView to use ViewModel data instead of hardcoded values**

Replace:
```swift
ActivityRingsCard(
    moveCurrent: 550,
    moveTarget: 600,
    exerciseCurrent: 45,
    exerciseTarget: 60,
    standCurrent: 10,
    standTarget: 12
)
```

With:
```swift
ActivityRingsCard(
    moveCurrent: viewModel.moveCalories,
    moveTarget: viewModel.moveTarget,
    exerciseCurrent: viewModel.exerciseMinutes,
    exerciseTarget: viewModel.exerciseTarget,
    standCurrent: Double(viewModel.standHours),
    standTarget: Double(viewModel.standTarget)
)
```

**Step 2: Update JournalView daily insight**

Replace random insight text with `viewModel.insightText`.

**Step 3: Commit**

```
fix: wire activity rings and daily insight to real HealthKit data
```

---

### Task 9: Fix FitnessViewModel Cardio Data (TDD)

**Files:**
- Create: `gochangeTests/ViewModels/FitnessViewModelTests.swift`
- Modify: `gochange/ViewModels/FitnessViewModel.swift`

**Step 1: Write failing tests**

```swift
@MainActor
final class FitnessViewModelTests: XCTestCase {
    func testCardioFocusPercentage_calculatedFromSessions() {
        let vm = FitnessViewModel()
        // With 3 strength and 1 cardio session, cardio focus should be ~25%
        // Not hardcoded 0.94
        XCTAssertNotEqual(vm.cardioFocusPercentage, 0.94,
            "cardioFocusPercentage should not be hardcoded")
    }

    func testStrainCalculation_usesRealData() {
        let vm = FitnessViewModel()
        // Strain should be 0 with no data, not hardcoded 4.0
        XCTAssertEqual(vm.strainScore, 0,
            "Strain should start at 0 with no data")
    }
}
```

**Step 2: Fix FitnessViewModel**

- Remove hardcoded `cardioFocusPercentage = 0.94`
- Calculate from actual cardio vs strength session ratio
- Remove hardcoded cardio strain of 4.0
- Calculate from HealthKit active energy

**Step 3: Run tests, verify pass**

**Step 4: Commit**

```
fix: calculate cardio focus and strain from real data instead of hardcodes (TDD)
```

---

### Task 10: Fix AnalyticsViewModel Defaults

**Files:**
- Modify: `gochange/ViewModels/AnalyticsViewModel.swift`

**Step 1: Fix hardcoded "Bench Press" default**

Replace:
```swift
@Published var selectedExerciseForTrend: String = "Bench Press"
```

With dynamic selection that uses first available exercise from user data, falling back to empty string.

**Step 2: Commit**

```
fix: use dynamic exercise default instead of hardcoded Bench Press
```

---

### Task 11: Complete SleepView with Real Data

**Files:**
- Modify: `gochange/Views/Sleep/SleepView.swift`

**Step 1: Replace mock sleep stages with real HealthKit data**

Wire sleep stages (deep, REM, core, awake) from `HomeViewModel.sleepData` which gets real data from `HealthKitService.getSleepData()`.

Remove "Mock for now" comment and any hardcoded stage values.

**Step 2: Commit**

```
fix: complete SleepView with real HealthKit sleep stage data
```

---

### Task 12: Fix SessionHealthSummaryCard

**Files:**
- Modify: `gochange/Views/History/SessionHealthSummaryCard.swift`

**Step 1: Remove hardcoded "--" cardio impact values**

Either:
- Wire to actual pre/post workout heart rate if available from HealthKit
- Or remove the "Before/After" section entirely if data isn't available (show empty state)

**Step 2: Commit**

```
fix: remove hardcoded cardio impact values in session summary
```

---

### Task 13: Fix FitnessDashboardView Mock Thresholds

**Files:**
- Modify: `gochange/Views/Fitness/FitnessDashboardView.swift`

**Step 1: Remove "if load > 500" hardcoded threshold**

Replace with percentile-based or data-driven classification.

**Step 2: Remove "Mock lines" code**

**Step 3: Commit**

```
fix: remove hardcoded thresholds and mock lines from fitness dashboard
```

---

## Phase 3: Error Handling + States

### Task 14: Add LoadState to All ViewModels

**Files:**
- Already done for HomeViewModel (Task 7)
- Modify: `gochange/ViewModels/FitnessViewModel.swift`
- Modify: `gochange/ViewModels/AnalyticsViewModel.swift`

**Step 1: Add LoadState enum and published property to each ViewModel**

**Step 2: Wrap all data fetching in loadState transitions (idle -> loading -> loaded/error)**

**Step 3: Commit**

```
feat: add LoadState tracking to all ViewModels
```

---

### Task 15: Add Loading/Empty/Error States to Views

**Files:**
- Modify: `gochange/Views/Fitness/JournalView.swift`
- Modify: `gochange/Views/Fitness/FitnessDashboardView.swift`
- Modify: `gochange/Views/Analytics/PerformanceAnalyticsView.swift`

**Step 1: Add loading state UI**

When `viewModel.loadState == .loading`, show a ProgressView or skeleton.

**Step 2: Add empty state UI**

When data arrays are empty after loading, show ContentUnavailableView with appropriate message.

**Step 3: Add error state UI**

When `viewModel.loadState == .error(message)`, show error with retry button.

**Step 4: Commit**

```
feat: add loading, empty, and error states to all data views
```

---

## Phase 4: Watch App Fixes

### Task 16: Fix Watch-to-iPhone Workout Sync (CRITICAL)

**Files:**
- Modify: `gochange/Services/WatchConnectivityService.swift`
- Modify: `gochange/App/GoChangeApp.swift`
- Create: `gochangeTests/Services/WatchWorkoutImportTests.swift`

**Step 1: Write failing test for workout import**

```swift
final class WatchWorkoutImportTests: XCTestCase {
    func testParseWatchWorkoutTransfer_createsValidSession() {
        let transfer: [String: Any] = [
            "workoutDayName": "Push",
            "startTime": Date().timeIntervalSince1970,
            "endTime": Date().addingTimeInterval(3600).timeIntervalSince1970,
            "exercises": [
                [
                    "name": "Bench Press",
                    "sets": [
                        ["weight": 135.0, "reps": 8, "completed": true]
                    ]
                ]
            ]
        ]

        let result = WatchWorkoutImporter.parseWorkout(from: transfer)

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.workoutDayName, "Push")
        XCTAssertEqual(result?.exerciseLogs.count, 1)
    }
}
```

**Step 2: Create WatchWorkoutImporter utility**

Parse the watch transfer dictionary into WorkoutSession + ExerciseLogs + SetLogs and insert into SwiftData.

**Step 3: Wire onWorkoutReceived in GoChangeApp.swift**

```swift
WatchConnectivityService.shared.onWorkoutReceived = { workoutData in
    Task { @MainActor in
        guard let context = modelContainer.mainContext else { return }
        if let session = WatchWorkoutImporter.parseAndSave(from: workoutData, context: context) {
            try? context.save()
        }
    }
}
```

**Step 4: Run tests, verify pass**

**Step 5: Commit**

```
feat: implement Watch workout import handler to fix critical data loss (TDD)
```

---

### Task 17: Consolidate Watch HealthKit

**Files:**
- Modify: `GoChangeWatch Watch App/Services/WatchWorkoutManager.swift`
- Modify: `GoChangeWatch Watch App/GoChangeWatchApp.swift`

**Step 1: Remove duplicate HKWorkoutSession from WatchWorkoutManager**

Delegate all HealthKit operations to WatchHealthKitService.

**Step 2: Add HealthKit authorization on Watch launch**

```swift
// In GoChangeWatchApp.swift .onAppear:
Task {
    try? await WatchHealthKitService.shared.requestAuthorization()
}
```

**Step 3: Commit**

```
fix: consolidate Watch HealthKit into single service, add authorization
```

---

### Task 18: Add Watch Workout State Persistence

**Files:**
- Modify: `GoChangeWatch Watch App/Services/WatchWorkoutManager.swift`

**Step 1: Save active workout state to UserDefaults on Watch**

Mirror the iPhone pattern: serialize exercise logs, start time, current exercise index to UserDefaults. Restore on app launch.

**Step 2: Commit**

```
feat: persist active Watch workout state for crash recovery
```

---

## Phase 5: Polish + Remaining Features

### Task 19: Add Per-Exercise Rest Timer Presets

**Files:**
- Modify: `gochange/Models/Exercise.swift`
- Modify: `gochange/Services/WorkoutManager.swift`
- Modify: `gochange/Views/Workout/EditWorkoutDayView.swift`

**Step 1: Add defaultRestDuration to Exercise model**

```swift
var defaultRestDuration: TimeInterval? // nil = use global default (90s)
```

**Step 2: Use exercise-specific rest duration in WorkoutManager.startAutoRestTimer()**

**Step 3: Add rest timer input in EditWorkoutDayView**

**Step 4: Commit**

```
feat: add per-exercise rest timer presets
```

---

### Task 20: Verify ExerciseMiniChart with Real Data

**Files:**
- Review: `gochange/Views/Workout/ExerciseMiniChart.swift`

**Step 1: Verify the chart pulls from SwiftData ExerciseLog history**

**Step 2: Fix if using mock data**

**Step 3: Commit (if changes needed)**

```
fix: wire ExerciseMiniChart to real exercise history data
```

---

### Task 21: Audit All Views for Consistent Card Styling

**Files:**
- All view files

**Step 1: Search for inline card styling that doesn't use ViewModifiers.swift**

```bash
grep -rn "cornerRadius\|\.shadow\|\.overlay.*RoundedRectangle" gochange/Views/ | grep -v "ViewModifiers"
```

**Step 2: Replace inline styling with `.cardStyle()` or `.subCardStyle()` modifiers**

**Step 3: Commit**

```
refactor: standardize all card styling to use ViewModifiers
```

---

### Task 22: Final Cleanup

**Files:**
- All files

**Step 1: Remove any remaining TODO/FIXME/mock comments**

```bash
grep -rn "TODO\|FIXME\|mock\|Mock\|placeholder\|hardcoded" gochange/ --include="*.swift"
```

**Step 2: Remove unused imports**

**Step 3: Verify all files end with newline**

**Step 4: Final commit**

```
chore: remove remaining TODOs, clean up imports, final polish
```

---

## Execution Checklist

- [ ] Phase 1: Task 1-6 (Foundation)
- [ ] Phase 2: Task 7-13 (Data Layer)
- [ ] Phase 3: Task 14-15 (Error Handling)
- [ ] Phase 4: Task 16-18 (Watch App)
- [ ] Phase 5: Task 19-22 (Polish)
- [ ] All tests pass
- [ ] No hardcoded mock data remains
- [ ] All views use unified design system
- [ ] Watch sync works end-to-end
