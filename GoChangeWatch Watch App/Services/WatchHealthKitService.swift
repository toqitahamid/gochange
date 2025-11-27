import Foundation
import HealthKit
import Combine

/// HealthKit service for Apple Watch - handles workout sessions and heart rate monitoring
class WatchHealthKitService: NSObject, ObservableObject {
    static let shared = WatchHealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var currentHeartRate: Double?
    @Published var averageHeartRate: Double?
    @Published var maxHeartRate: Double?
    @Published var activeCalories: Double = 0
    
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateSamples: [Double] = []
    
    // MARK: - Health Data Types
    
    private let typesToShare: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.activeEnergyBurned)
    ]
    
    private let typesToRead: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKQuantityType(.heartRate),
        HKQuantityType(.activeEnergyBurned)
    ]
    
    // MARK: - Initialization
    
    override private init() {
        super.init()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        let status = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        isAuthorized = status == .sharingAuthorized
    }
    
    func requestAuthorization() async -> Bool {
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            checkAuthorizationStatus()
            return isAuthorized
        } catch {
            print("HealthKit authorization error: \(error)")
            return false
        }
    }
    
    // MARK: - Workout Session Management
    
    func startWorkoutSession(workoutType: HKWorkoutActivityType = .traditionalStrengthTraining) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor
        
        workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
        workoutBuilder = workoutSession?.associatedWorkoutBuilder()
        
        workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        workoutSession?.delegate = self
        workoutBuilder?.delegate = self
        
        // Reset stats
        heartRateSamples = []
        currentHeartRate = nil
        averageHeartRate = nil
        maxHeartRate = nil
        activeCalories = 0
        
        let startDate = Date()
        workoutSession?.startActivity(with: startDate)
        
        try await workoutBuilder?.beginCollection(at: startDate)
    }
    
    func pauseWorkout() {
        workoutSession?.pause()
    }
    
    func resumeWorkout() {
        workoutSession?.resume()
    }
    
    func endWorkoutSession() async throws -> HKWorkout? {
        guard let workoutSession = workoutSession,
              let workoutBuilder = workoutBuilder else {
            return nil
        }
        
        let endDate = Date()
        workoutSession.end()
        
        let workout = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKWorkout?, Error>) in
            workoutBuilder.endCollection(withEnd: endDate) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                workoutBuilder.finishWorkout { workout, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let workout = workout {
                        continuation.resume(returning: workout)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
        
        // Clean up
        self.workoutSession = nil
        self.workoutBuilder = nil
        
        return workout
    }
    
    // MARK: - Heart Rate Helpers
    
    private func updateHeartRateStats(_ heartRate: Double) {
        heartRateSamples.append(heartRate)
        
        DispatchQueue.main.async {
            self.currentHeartRate = heartRate
            self.maxHeartRate = self.heartRateSamples.max()
            self.averageHeartRate = self.heartRateSamples.reduce(0, +) / Double(self.heartRateSamples.count)
        }
        
        // Send heart rate to iPhone
        WatchConnectivityManager.shared.sendMessage([
            "type": "heartRateUpdate",
            "heartRate": heartRate,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Statistics
    
    func getWorkoutStatistics() -> WorkoutStatistics {
        return WorkoutStatistics(
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            activeCalories: activeCalories,
            heartRateSamples: heartRateSamples
        )
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchHealthKitService: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print("Workout session running")
        case .paused:
            print("Workout session paused")
        case .ended:
            print("Workout session ended")
        default:
            break
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchHealthKitService: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events (e.g., pause/resume markers)
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            switch quantityType {
            case HKQuantityType(.heartRate):
                if let heartRate = statistics?.mostRecentQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) {
                    updateHeartRateStats(heartRate)
                }
                
            case HKQuantityType(.activeEnergyBurned):
                if let calories = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    DispatchQueue.main.async {
                        self.activeCalories = calories
                    }
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - Supporting Types

struct WorkoutStatistics {
    let averageHeartRate: Double?
    let maxHeartRate: Double?
    let activeCalories: Double
    let heartRateSamples: [Double]
    
    var heartRateZone: HeartRateZone {
        guard let avgHR = averageHeartRate else { return .unknown }
        
        // Simplified zone calculation (would need user's max HR for accuracy)
        switch avgHR {
        case 0..<100: return .warmup
        case 100..<130: return .fatBurn
        case 130..<160: return .cardio
        case 160..<180: return .peak
        default: return .peak
        }
    }
}

enum HeartRateZone: String {
    case unknown = "Unknown"
    case warmup = "Warm Up"
    case fatBurn = "Fat Burn"
    case cardio = "Cardio"
    case peak = "Peak"
    
    var color: String {
        switch self {
        case .unknown: return "#808080"
        case .warmup: return "#64B5F6"
        case .fatBurn: return "#4DB6AC"
        case .cardio: return "#FFB74D"
        case .peak: return "#FF6B6B"
        }
    }
}

