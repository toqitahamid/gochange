import Foundation
import HealthKit
import Combine

/// Service for HealthKit integration - saves workouts to Apple Health and reads heart rate data
@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // MARK: - Health Data Types
    
    private let workoutType = HKObjectType.workoutType()
    
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]

    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKCategoryType(.sleepAnalysis)
    ]
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Check if HealthKit is available on this device
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }
        
        let status = healthStore.authorizationStatus(for: workoutType)
        authorizationStatus = status
        isAuthorized = status == .sharingAuthorized
    }
    
    /// Request authorization to read/write health data
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            print("HealthKit is not available on this device")
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            checkAuthorizationStatus()
            return isAuthorized
        } catch {
            print("HealthKit authorization error: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Save Workout

    /// Save a completed workout session to HealthKit
    func saveWorkout(
        workoutName: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        totalVolume: Double? = nil
    ) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        // Estimate calories burned (approximately 3-5 cal/minute for strength training)
        // Using 4 cal/minute as a middle ground
        let caloriesPerMinute: Double = 4.0
        let estimatedCalories = (duration / 60.0) * caloriesPerMinute

        // Use HKWorkoutBuilder (iOS 17+)
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .traditionalStrengthTraining

        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: workoutConfiguration, device: .local())

        // Add metadata
        try await builder.addMetadata([
            HKMetadataKeyWorkoutBrandName: "GoChange",
            "WorkoutName": workoutName
        ])

        // Begin the workout
        try await builder.beginCollection(at: startTime)

        // Add energy burned sample
        let energyType = HKQuantityType(.activeEnergyBurned)
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: startTime,
            end: endTime
        )
        try await builder.addSamples([energySample])

        // End collection and finish the workout
        try await builder.endCollection(at: endTime)
        try await builder.finishWorkout()

        print("Successfully saved workout to HealthKit: \(workoutName), \(Int(estimatedCalories)) kcal")
    }
    
    // MARK: - Heart Rate
    
    /// Get heart rate samples for a given time period
    func getHeartRateSamples(from startDate: Date, to endDate: Date) async -> [HeartRateSample] {
        guard isHealthKitAvailable else { return [] }
        
        let heartRateType = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("Heart rate query error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let heartRateSamples = (samples as? [HKQuantitySample])?.map { sample in
                    HeartRateSample(
                        date: sample.startDate,
                        bpm: sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    )
                } ?? []
                
                continuation.resume(returning: heartRateSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Get average heart rate for a time period
    func getAverageHeartRate(from startDate: Date, to endDate: Date) async -> Double? {
        let samples = await getHeartRateSamples(from: startDate, to: endDate)
        guard !samples.isEmpty else { return nil }
        
        let totalBPM = samples.reduce(0) { $0 + $1.bpm }
        return totalBPM / Double(samples.count)
    }
    
    /// Get max heart rate for a time period
    func getMaxHeartRate(from startDate: Date, to endDate: Date) async -> Double? {
        let samples = await getHeartRateSamples(from: startDate, to: endDate)
        return samples.map { $0.bpm }.max()
    }
    
    // MARK: - Workout Query
    
    /// Get recent workouts from HealthKit
    func getRecentWorkouts(limit: Int = 10) async -> [HKWorkout] {
        guard isHealthKitAvailable else { return [] }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("Workout query error: \(error.localizedDescription)")
                    continuation.resume(returning: [])
                    return
                }
                
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Data

    /// Get sleep analysis data for a given date
    /// Looks for sleep that ended on the given date (i.e., wake-up date)
    func getSleepData(for date: Date) async -> SleepData? {
        guard isHealthKitAvailable else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        // Query for sleep that occurred the night before (typically 8-12 hours before wake-up)
        // This captures sleep that started the previous night and ended on the given date
        let startTime = calendar.date(byAdding: .hour, value: -12, to: startOfDay) ?? startOfDay

        let sleepType = HKCategoryType(.sleepAnalysis)
        // Use strictEndDate to find sleep that ended on this date (wake-up date)
        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endOfDay, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Sleep query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sleepSamples = samples as? [HKCategorySample] else {
                    print("⚠️ No sleep samples found or invalid sample type")
                    continuation.resume(returning: nil)
                    return
                }

                print("✅ Found \(sleepSamples.count) sleep samples for date: \(date.formatted(date: .abbreviated, time: .omitted))")

                var totalSleep: TimeInterval = 0
                var deepSleep: TimeInterval = 0
                var remSleep: TimeInterval = 0
                var coreSleep: TimeInterval = 0

                for sample in sleepSamples {
                    let duration = sample.endDate.timeIntervalSince(sample.startDate)

                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        deepSleep += duration
                        totalSleep += duration
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        remSleep += duration
                        totalSleep += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        coreSleep += duration
                        totalSleep += duration
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        totalSleep += duration
                    default:
                        break
                    }
                }

                guard totalSleep > 0 else {
                    print("⚠️ No sleep time recorded in samples")
                    continuation.resume(returning: nil)
                    return
                }

                print("💤 Total sleep: \(Int(totalSleep/3600))h \(Int((totalSleep.truncatingRemainder(dividingBy: 3600))/60))m")
                print("   Deep: \(Int(deepSleep/60))m, REM: \(Int(remSleep/60))m, Core: \(Int(coreSleep/60))m")

                // Calculate sleep quality based on sleep stage distribution
                // Deep sleep should be 15-25%, REM should be 20-25% of total sleep
                let deepPercentage = deepSleep / totalSleep
                let remPercentage = remSleep / totalSleep

                var quality = 0.5 // Base quality

                // Bonus for good deep sleep (optimal: 15-25%)
                if deepPercentage >= 0.15 && deepPercentage <= 0.25 {
                    quality += 0.25
                } else if deepPercentage >= 0.10 && deepPercentage <= 0.30 {
                    quality += 0.15
                }

                // Bonus for good REM sleep (optimal: 20-25%)
                if remPercentage >= 0.20 && remPercentage <= 0.25 {
                    quality += 0.25
                } else if remPercentage >= 0.15 && remPercentage <= 0.30 {
                    quality += 0.15
                }

                quality = min(quality, 1.0) // Cap at 1.0

                let sleepData = SleepData(
                    totalDuration: totalSleep,
                    deepSleepDuration: deepSleep,
                    remSleepDuration: remSleep,
                    coreSleepDuration: coreSleep,
                    quality: quality,
                    startDate: sleepSamples.first?.startDate ?? startOfDay,
                    endDate: sleepSamples.last?.endDate ?? endOfDay
                )

                print("✅ Sleep quality calculated: \(Int(quality * 100))%")
                continuation.resume(returning: sleepData)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Resting Heart Rate

    /// Get resting heart rate for a given date
    func getRestingHeartRate(for date: Date) async -> Double? {
        guard isHealthKitAvailable else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let restingHRType = HKQuantityType(.restingHeartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: restingHRType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ Resting HR query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = (samples as? [HKQuantitySample])?.first else {
                    print("⚠️ No resting heart rate data found for date: \(date.formatted(date: .abbreviated, time: .omitted))")
                    continuation.resume(returning: nil)
                    return
                }

                let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                print("💓 Resting HR: \(Int(bpm)) BPM")
                continuation.resume(returning: bpm)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Heart Rate Variability

    /// Get heart rate variability (HRV) for a given date
    func getHeartRateVariability(for date: Date) async -> Double? {
        guard isHealthKitAvailable else { return nil }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ HRV query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let hrvSamples = samples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                    print("⚠️ No HRV data found for date: \(date.formatted(date: .abbreviated, time: .omitted))")
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate average HRV for the day
                let totalHRV = hrvSamples.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                }
                let averageHRV = totalHRV / Double(hrvSamples.count)

                print("📊 HRV: \(Int(averageHRV))ms (from \(hrvSamples.count) samples)")
                continuation.resume(returning: averageHRV)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Supporting Types

struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
}

struct SleepData {
    let totalDuration: TimeInterval
    let deepSleepDuration: TimeInterval
    let remSleepDuration: TimeInterval
    let coreSleepDuration: TimeInterval
    let quality: Double // 0-1
    let startDate: Date
    let endDate: Date

    var formattedTotal: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int((totalDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }

    var formattedDeep: String {
        let minutes = Int(deepSleepDuration / 60)
        return "\(minutes) min"
    }

    var formattedREM: String {
        let minutes = Int(remSleepDuration / 60)
        return "\(minutes) min"
    }

    var formattedCore: String {
        let minutes = Int(coreSleepDuration / 60)
        return "\(minutes) min"
    }

    var qualityPercentage: Int {
        Int(quality * 100)
    }
}

enum HealthKitError: LocalizedError {
    case notAuthorized
    case notAvailable
    case saveFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit access not authorized. Please enable in Settings."
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .saveFailed(let error):
            return "Failed to save to HealthKit: \(error.localizedDescription)"
        }
    }
}

