import Foundation
import SwiftData
import HealthKit
import Combine

/// Service for managing recovery tracking and providing recommendations
@MainActor
class RecoveryService: ObservableObject {
    static let shared = RecoveryService()

    private let healthKitService = HealthKitService.shared

    @Published var todaysRecoveryMetrics: RecoveryMetrics?
    @Published var todaysRestDay: RestDay?
    @Published var recoveryRecommendation: RecoveryRecommendation?

    private init() {}

    // MARK: - Recovery Metrics

    /// Fetch or create today's recovery metrics
    func getTodaysRecoveryMetrics(context: ModelContext) -> RecoveryMetrics {
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<RecoveryMetrics>(
            predicate: #Predicate { metrics in
                metrics.date >= today
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        if let existing = try? context.fetch(descriptor).first {
            return existing
        }

        let newMetrics = RecoveryMetrics(date: today)
        context.insert(newMetrics)
        return newMetrics
    }

    /// Sync recovery data from HealthKit
    func syncRecoveryData(for date: Date = Date(), context: ModelContext) async {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: date)

        print("🔄 Syncing recovery data for: \(targetDate.formatted(date: .abbreviated, time: .omitted))")
        print("   HealthKit available: \(healthKitService.isHealthKitAvailable)")
        print("   HealthKit authorized: \(healthKitService.isAuthorized)")

        let metrics = getTodaysRecoveryMetrics(context: context)

        // Fetch sleep data
        if let sleepData = await healthKitService.getSleepData(for: targetDate) {
            metrics.sleepDuration = sleepData.totalDuration
            metrics.sleepQuality = sleepData.quality
            metrics.deepSleepDuration = sleepData.deepSleepDuration
            metrics.remSleepDuration = sleepData.remSleepDuration
            print("✅ Sleep data synced")
        } else {
            print("⚠️ No sleep data available")
        }

        // Fetch resting heart rate
        if let restingHR = await healthKitService.getRestingHeartRate(for: targetDate) {
            metrics.restingHeartRate = restingHR
            print("✅ Resting HR synced")
        } else {
            print("⚠️ No resting HR available")
        }

        // Fetch HRV
        if let hrv = await healthKitService.getHeartRateVariability(for: targetDate) {
            metrics.heartRateVariability = hrv
            print("✅ HRV synced")
        } else {
            print("⚠️ No HRV available")
        }

        metrics.updatedAt = Date()
        try? context.save()

        self.todaysRecoveryMetrics = metrics
        print("✅ Recovery sync complete")
        await generateRecoveryRecommendation(metrics: metrics, context: context)
    }

    /// Update muscle recovery status based on recent workouts
    func updateMuscleRecovery(context: ModelContext) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        // Fetch recent workout sessions
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.date >= sevenDaysAgo && session.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        guard let sessions = try? context.fetch(descriptor) else { return }

        var muscleGroupMap: [String: (lastWorked: Date, intensity: Int)] = [:]

        // Analyze workouts to determine muscle group status
        for session in sessions {
            let muscleGroups = extractMuscleGroups(from: session)

            for group in muscleGroups {
                if muscleGroupMap[group] == nil {
                    let intensity = calculateWorkoutIntensity(session: session)
                    muscleGroupMap[group] = (session.date, intensity)
                }
            }
        }

        // Calculate soreness for each muscle group
        var muscleRecovery: [MuscleGroupRecovery] = []

        for (group, data) in muscleGroupMap {
            let daysSince = calendar.dateComponents([.day], from: data.lastWorked, to: today).day ?? 0
            let soreness = calculateSoreness(daysSince: daysSince, intensity: data.intensity)

            muscleRecovery.append(MuscleGroupRecovery(
                muscleGroup: group,
                sorenessLevel: soreness,
                lastWorked: data.lastWorked
            ))
        }

        // Update today's metrics
        let metrics = getTodaysRecoveryMetrics(context: context)
        metrics.muscleRecovery = muscleRecovery
        metrics.updatedAt = Date()
        try? context.save()

        self.todaysRecoveryMetrics = metrics
    }

    // MARK: - Rest Day Management

    /// Log a rest day
    func logRestDay(
        date: Date = Date(),
        type: RestDayType,
        notes: String? = nil,
        quality: Int = 3,
        musclesSore: [String] = [],
        energyLevel: Int = 3,
        stressLevel: Int = 3,
        context: ModelContext
    ) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)

        // Check if rest day already exists
        let descriptor = FetchDescriptor<RestDay>(
            predicate: #Predicate { restDay in
                restDay.date >= dayStart
            }
        )

        if let existing = try? context.fetch(descriptor).first {
            // Update existing
            existing.type = type
            existing.notes = notes
            existing.quality = quality
            existing.musclesSore = musclesSore
            existing.energyLevel = energyLevel
            existing.stressLevel = stressLevel
        } else {
            // Create new
            let restDay = RestDay(
                date: dayStart,
                type: type,
                notes: notes,
                quality: quality,
                musclesSore: musclesSore,
                energyLevel: energyLevel,
                stressLevel: stressLevel
            )
            context.insert(restDay)
        }

        try? context.save()
    }

    /// Sync sleep data to today's rest day if it exists
    func syncSleepToRestDay(context: ModelContext) async {
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<RestDay>(
            predicate: #Predicate { restDay in
                restDay.date >= today
            }
        )

        guard let restDay = try? context.fetch(descriptor).first else { return }

        // Fetch sleep data from HealthKit
        if let sleepData = await healthKitService.getSleepData(for: today) {
            restDay.sleepDuration = sleepData.totalDuration
            restDay.sleepQuality = sleepData.quality
            try? context.save()
            self.todaysRestDay = restDay
        }
    }

    // MARK: - Recommendations

    /// Generate recovery recommendation based on current metrics
    func generateRecoveryRecommendation(metrics: RecoveryMetrics, context: ModelContext) async {
        let readiness = metrics.readinessToTrain
        let recoveryScore = metrics.overallRecoveryScore

        var recommendation = RecoveryRecommendation(
            readiness: readiness,
            score: recoveryScore,
            message: readiness.recommendation,
            shouldRest: readiness == .needsRest,
            suggestedActivities: []
        )

        // Determine suggested activities
        switch readiness {
        case .optimal:
            recommendation.suggestedActivities = [
                "High-intensity workout",
                "Personal records attempt",
                "Progressive overload"
            ]

        case .ready:
            recommendation.suggestedActivities = [
                "Normal training session",
                "Moderate intensity workout",
                "Skill practice"
            ]

        case .moderate:
            // Check which muscle groups are recovered
            let recoveredMuscles = metrics.muscleRecovery.filter { $0.isFullyRecovered }
            if !recoveredMuscles.isEmpty {
                recommendation.suggestedActivities = [
                    "Light workout on recovered muscles: \(recoveredMuscles.map { $0.muscleGroup }.joined(separator: ", "))",
                    "Technique-focused training",
                    "Mobility work"
                ]
            } else {
                recommendation.suggestedActivities = [
                    "Active recovery (walking, yoga)",
                    "Stretching and mobility",
                    "Light cardio"
                ]
            }

        case .needsRest:
            recommendation.suggestedActivities = [
                "Complete rest",
                "Gentle stretching",
                "Focus on sleep and nutrition",
                "Consider massage or foam rolling"
            ]

            // Check for specific issues
            if let sleepDuration = metrics.sleepDuration, sleepDuration < 6 * 3600 {
                recommendation.message += " You're low on sleep (\(metrics.formattedSleepDuration)). Prioritize rest tonight."
            }

            if metrics.overallFatigue >= 4 {
                recommendation.message += " High fatigue detected. Your body needs recovery time."
            }
        }

        // Check for overtraining indicators
        if let hrv = metrics.heartRateVariability, hrv < 20 {
            recommendation.message += " Low HRV detected - consider additional rest."
            recommendation.shouldRest = true
        }

        self.recoveryRecommendation = recommendation
    }

    // MARK: - Helper Methods

    private func extractMuscleGroups(from session: WorkoutSession) -> Set<String> {
        var groups = Set<String>()

        // Map workout day names to muscle groups
        let workoutName = session.workoutDayName.lowercased()

        if workoutName.contains("push") {
            groups.insert("Chest")
            groups.insert("Shoulders")
            groups.insert("Triceps")
        } else if workoutName.contains("pull") {
            groups.insert("Back")
            groups.insert("Biceps")
        } else if workoutName.contains("leg") {
            groups.insert("Legs")
            groups.insert("Glutes")
        } else if workoutName.contains("full") {
            groups.insert("Full Body")
        }

        // Muscle groups are already extracted from workout day name
        // Exercise-specific muscle groups could be added here if needed

        return groups
    }

    private func calculateWorkoutIntensity(session: WorkoutSession) -> Int {
        // Calculate intensity based on completed sets and RIR
        guard !session.exerciseLogs.isEmpty else { return 3 }

        var totalRIR = 0.0
        var setCount = 0

        for exerciseLog in session.exerciseLogs {
            for setLog in exerciseLog.sets where setLog.isCompleted {
                if let rir = setLog.rir {
                    totalRIR += Double(rir)
                    setCount += 1
                }
            }
        }

        guard setCount > 0 else { return 3 }

        let avgRIR = totalRIR / Double(setCount)

        // Lower RIR = higher intensity
        if avgRIR <= 1 {
            return 5 // Very high intensity
        } else if avgRIR <= 2 {
            return 4
        } else if avgRIR <= 3 {
            return 3
        } else {
            return 2
        }
    }

    private func calculateSoreness(daysSince: Int, intensity: Int) -> Int {
        // Soreness calculation based on days since workout and intensity
        // Peak soreness typically 24-48 hours after workout

        switch (daysSince, intensity) {
        case (0, _):
            return intensity >= 4 ? 3 : 2
        case (1, 5):
            return 5
        case (1, 4):
            return 4
        case (1, _):
            return 3
        case (2, 5):
            return 4
        case (2, 4):
            return 3
        case (2, _):
            return 2
        case (3, 5):
            return 3
        case (3, _):
            return 2
        case (4...5, _):
            return intensity >= 4 ? 2 : 1
        default:
            return 1 // Fully recovered after 6+ days
        }
    }
}

// MARK: - Supporting Types

struct RecoveryRecommendation {
    let readiness: TrainingReadiness
    let score: Double
    var message: String
    var shouldRest: Bool
    var suggestedActivities: [String]

    var scorePercentage: Int {
        Int(score * 100)
    }
}
