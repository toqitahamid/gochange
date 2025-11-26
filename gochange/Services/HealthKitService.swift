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
        HKQuantityType(.activeEnergyBurned)
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
}

// MARK: - Supporting Types

struct HeartRateSample: Identifiable {
    let id = UUID()
    let date: Date
    let bpm: Double
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

