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
    @Published var hasDeniedReadPermissions = false
    private var hasRequestedAuthorization = false
    
    // MARK: - Health Data Types
    
    private let workoutType = HKObjectType.workoutType()
    
    private let typesToWrite: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]

    private let typesToRead: Set<HKObjectType> = [
        // Activity & Workouts
        HKObjectType.workoutType(),
        HKSeriesType.workoutRoute(),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceCycling),
        HKQuantityType(.distanceSwimming),
        HKQuantityType(.distanceWalkingRunning),
        HKQuantityType(.distanceWheelchair),
        HKQuantityType(.distanceDownhillSnowSports),
        HKQuantityType(.swimmingStrokeCount),
        HKQuantityType(.flightsClimbed),
        HKQuantityType(.pushCount), // Wheelchair pushes
        
        // Vitals & Measurements
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.respiratoryRate),
        HKQuantityType(.oxygenSaturation),
        HKQuantityType(.bodyTemperature),
        HKQuantityType(.vo2Max),
        HKQuantityType(.walkingHeartRateAverage),
        HKQuantityType(.runningPower),
        HKQuantityType(.runningSpeed),
        HKQuantityType(.walkingSpeed),
        HKQuantityType(.cyclingPower),
        HKQuantityType(.cyclingSpeed),
        HKQuantityType(.cyclingCadence),
        HKQuantityType(.runningStrideLength),
        HKQuantityType(.runningVerticalOscillation),
        HKQuantityType(.runningGroundContactTime),
        HKQuantityType(.environmentalAudioExposure),
        HKQuantityType(.headphoneAudioExposure),
        
        // Sleep & Mindfulness
        HKCategoryType(.sleepAnalysis),
        HKCategoryType(.mindfulSession),
        
        // Characteristics
        HKCharacteristicType(.dateOfBirth),
        HKCharacteristicType(.biologicalSex),
        HKCharacteristicType(.wheelchairUse),
        HKCharacteristicType(.activityMoveMode)
    ]
    
    // ... (Existing code) ...

    // MARK: - Respiratory Rate
    
    func getRespiratoryRate(for date: Date) async -> Double? {
        return await getQuantitySample(for: .respiratoryRate, unit: HKUnit.count().unitDivided(by: .minute()), date: date)
    }
    
    // MARK: - Oxygen Saturation
    
    func getOxygenSaturation(for date: Date) async -> Double? {
        return await getQuantitySample(for: .oxygenSaturation, unit: .percent(), date: date)
    }
    
    // MARK: - Body Temperature
    
    func getBodyTemperature(for date: Date) async -> Double? {
        return await getQuantitySample(for: .bodyTemperature, unit: .degreeCelsius(), date: date)
    }
    
    // MARK: - Steps
    
    func getStepCount(for date: Date) async -> Int {
        guard isHealthKitAvailable else { return 0 }
        
        let stepType = HKQuantityType(.stepCount)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("❌ Step count query error: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - VO2 Max
    
    func getVO2Max() async -> Double? {
        // VO2 Max is not daily, so we look back a bit further (e.g., 30 days) to find the latest reading
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        return await getQuantitySample(for: .vo2Max, unit: HKUnit(from: "ml/kg*min"), date: endDate, startDate: startDate)
    }
    
    // MARK: - Helper
    
    private func getQuantitySample(for typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date, startDate: Date? = nil) async -> Double? {
        guard isHealthKitAvailable else { return nil }
        
        let type = HKQuantityType(typeIdentifier)
        let calendar = Calendar.current
        
        // Default to daily query if no specific start date provided
        let queryEndDate = date
        let queryStartDate = startDate ?? calendar.startOfDay(for: date)
        
        // If looking for a daily metric (like RHR), we might want the latest sample in that day
        // If looking for something sporadic (like VO2 Max), we provided a wider range
        
        let predicate = HKQuery.predicateForSamples(withStart: queryStartDate, end: queryEndDate, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("❌ \(typeIdentifier.rawValue) query error: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let sample = (samples as? [HKQuantitySample])?.first else {
                    // Only print warning for common metrics, not sporadic ones to avoid noise
                    if typeIdentifier != .vo2Max {
                         print("⚠️ No data found for \(typeIdentifier.rawValue)")
                    }
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Heart Rate Variability
    
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

        // Check workout write permission (more reliable than read permissions)
        let workoutStatus = healthStore.authorizationStatus(for: workoutType)
        authorizationStatus = workoutStatus

        // If workout is authorized, we know user has granted permissions before
        if workoutStatus == .sharingAuthorized {
            hasRequestedAuthorization = true
        }
        
        // For read permissions, HealthKit does not allow apps to check status
        // It always returns .notDetermined or .sharingDenied to protect user privacy
        // We can only infer authorization if we've successfully requested it (based on write status)
        
        // Only mark as denied if workout write is explicitly denied
        // This is a proxy check - if workout is authorized, user has likely granted permissions
        let deniedReadPermissions = workoutStatus == .sharingDenied
        
        self.hasDeniedReadPermissions = deniedReadPermissions
        
        // Consider authorized if workout write is authorized
        isAuthorized = workoutStatus == .sharingAuthorized

        print("🔐 HealthKit Auth Status:")
        print("   Read Permissions: Status is private (HealthKit does not reveal read status)")
        print("   Workout (Write): \(workoutStatus == .notDetermined ? "Not Determined" : workoutStatus == .sharingDenied ? "Denied" : "Authorized")")
        print("   Has requested: \(hasRequestedAuthorization)")
        print("   Is authorized: \(isAuthorized)")
    }
    
    /// Check if we can read a specific health data type
    /// Returns false if authorization is explicitly denied or not determined
    func canRead(_ objectType: HKObjectType) -> Bool {
        guard isHealthKitAvailable else { return false }
        let status = healthStore.authorizationStatus(for: objectType)
        // HealthKit quirk: read permissions return .notDetermined even when granted
        // So we only check if it's explicitly denied
        return status != .sharingDenied
    }
    
    /// Check if authorization is needed for a specific type
    func needsAuthorization(for objectType: HKObjectType) -> Bool {
        guard isHealthKitAvailable else { return false }
        let status = healthStore.authorizationStatus(for: objectType)
        return status == .notDetermined
    }
    
    /// Request authorization to read/write health data
    @discardableResult
    func requestAuthorization() async -> Bool {
        guard isHealthKitAvailable else {
            print("❌ HealthKit is not available on this device")
            return false
        }

        print("📱 Requesting HealthKit authorization...")
        print("   Requesting to WRITE: \(typesToWrite.map { $0.identifier })")
        print("   Requesting to READ: \(typesToRead.map { $0.identifier })")

        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            hasRequestedAuthorization = true
            print("✅ HealthKit authorization request completed")
            checkAuthorizationStatus()
            return true // Always return true after request, as HealthKit doesn't reveal if user granted/denied read access
        } catch {
            print("❌ HealthKit authorization error: \(error.localizedDescription)")
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
    
    // MARK: - Activity Stats for Heatmap
    
    /// Get daily activity stats (workout count) for a date range
    func getDailyActivityStats(from startDate: Date, to endDate: Date) async -> [Date: Int] {
        guard isHealthKitAvailable else { return [:] }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("Workout query error: \(error.localizedDescription)")
                    continuation.resume(returning: [:])
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    continuation.resume(returning: [:])
                    return
                }
                
                var stats: [Date: Int] = [:]
                let calendar = Calendar.current
                
                for workout in workouts {
                    let date = calendar.startOfDay(for: workout.startDate)
                    stats[date, default: 0] += 1
                }
                
                continuation.resume(returning: stats)
            }
            
            healthStore.execute(query)
        }
    }

    // MARK: - Sleep Data

    /// Get sleep analysis data for a given date
    /// Looks for sleep that ended on the given date (i.e., wake-up date)
    func getSleepData(for date: Date) async -> SleepData? {
        guard isHealthKitAvailable else { return nil }

        let sleepType = HKCategoryType(.sleepAnalysis)
        
        // Note: HealthKit's authorizationStatus(for:) is unreliable for read permissions
        // It can return .sharingDenied even when permission is granted in Settings
        // We proceed with the query and let HealthKit handle authorization properly
        // The query will fail with an authorization error if truly denied

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

        // Query for sleep that occurred the night before (typically 8-12 hours before wake-up)
        // This captures sleep that started the previous night and ended on the given date
        let startTime = calendar.date(byAdding: .hour, value: -12, to: startOfDay) ?? startOfDay

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
                    // Check if it's an authorization error
                    if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                        print("❌ Sleep query error: Authorization denied")
                    } else {
                        print("❌ Sleep query error: \(error.localizedDescription)")
                    }
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

        let restingHRType = HKQuantityType(.restingHeartRate)
        
        // Note: HealthKit's authorizationStatus(for:) is unreliable for read permissions
        // It can return .sharingDenied even when permission is granted in Settings
        // We proceed with the query and let HealthKit handle authorization properly
        // The query will fail with an authorization error if truly denied

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

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
                    // Check if it's an authorization error
                    if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                        print("❌ Resting HR query error: Authorization denied")
                    } else {
                        print("❌ Resting HR query error: \(error.localizedDescription)")
                    }
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

        let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
        
        // Note: HealthKit's authorizationStatus(for:) is unreliable for read permissions
        // It can return .sharingDenied even when permission is granted in Settings
        // We proceed with the query and let HealthKit handle authorization properly
        // The query will fail with an authorization error if truly denied

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

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
                    // Check if it's an authorization error
                    if let hkError = error as? HKError, hkError.code == .errorAuthorizationDenied {
                        print("❌ HRV query error: Authorization denied")
                    } else {
                        print("❌ HRV query error: \(error.localizedDescription)")
                    }
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

    
    // MARK: - Daily Activity Metrics
    
    /// Get total steps for a specific date
    func getSteps(for date: Date) async -> Double {
        return await getSumQuantity(for: .stepCount, unit: .count(), date: date)
    }
    
    /// Get total walking/running distance for a specific date (in meters)
    func getWalkingRunningDistance(for date: Date) async -> Double {
        return await getSumQuantity(for: .distanceWalkingRunning, unit: .meter(), date: date)
    }
    
    /// Get total active energy burned for a specific date (in kcal)
    func getActiveEnergyBurned(for date: Date) async -> Double {
        return await getSumQuantity(for: .activeEnergyBurned, unit: .kilocalorie(), date: date)
    }
    
    /// Get total exercise time for a specific date (in minutes)
    func getExerciseTime(for date: Date) async -> Double {
        return await getSumQuantity(for: .appleExerciseTime, unit: .minute(), date: date)
    }
    
    // MARK: - Helper for Sum Queries
    
    private func getSumQuantity(for typeIdentifier: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) async -> Double {
        guard isHealthKitAvailable else { return 0 }
        
        let type = HKQuantityType(typeIdentifier)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("❌ \(typeIdentifier.rawValue) query error: \(error.localizedDescription)")
                    continuation.resume(returning: 0)
                    return
                }
                
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - User Characteristics
    
    /// Get user's date of birth from HealthKit
    func getBirthdate() -> Date? {
        guard isHealthKitAvailable else { return nil }
        
        do {
            let birthdateComponents = try healthStore.dateOfBirthComponents()
            return Calendar.current.date(from: birthdateComponents)
        } catch {
            print("❌ Error fetching birthdate: \(error.localizedDescription)")
            return nil
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

