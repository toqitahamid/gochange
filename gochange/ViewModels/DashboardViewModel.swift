import SwiftUI
import SwiftData
import HealthKit
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Scores (0-100)
    @Published var recoveryScore: Int = 0
    @Published var sleepScore: Int = 0
    @Published var strainScore: Int = 0
    
    // Metrics
    @Published var hrv: Double = 0
    @Published var restingHR: Double = 0
    @Published var sleepData: SleepData?
    @Published var activeCalories: Double = 0
    @Published var workoutDuration: TimeInterval = 0
    
    // Status
    @Published var isLoading: Bool = false
    @Published var greeting: String = ""
    
    // Services
    private let healthKitService = HealthKitService.shared
    private let recoveryService = RecoveryService.shared
    
    // MARK: - Initialization
    
    init() {
        updateGreeting()
    }
    
    // MARK: - Data Loading
    
    func loadData(context: ModelContext) async {
        isLoading = true
        
        // Parallel data fetching
        async let recoveryTask: () = loadRecoveryData(context: context)
        async let sleepTask: () = loadSleepData()
        async let workoutTask: () = loadWorkoutData(context: context)
        
        _ = await (recoveryTask, sleepTask, workoutTask)
        
        isLoading = false
    }
    
    private func loadRecoveryData(context: ModelContext) async {
        // Sync latest data
        await recoveryService.syncRecoveryData(context: context)
        
        // Get today's metrics
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch HRV and RHR directly from HealthKit for real-time display
        if let hrvVal = await healthKitService.getHeartRateVariability(for: today) {
            self.hrv = hrvVal
        }
        
        if let rhrVal = await healthKitService.getRestingHeartRate(for: today) {
            self.restingHR = rhrVal
        }
        
        // Calculate Recovery Score (simplified logic for now, can be enhanced)
        // Base on HRV relative to baseline (mock baseline of 50ms for now)
        let hrvScore = min(max((hrv / 50.0) * 50.0 + 25.0, 0), 100)
        let rhrScore = min(max((60.0 / max(restingHR, 40.0)) * 50.0 + 25.0, 0), 100)
        
        self.recoveryScore = Int((hrvScore + rhrScore) / 2.0)
    }
    
    private func loadSleepData() async {
        let today = Date()
        if let data = await healthKitService.getSleepData(for: today) {
            self.sleepData = data
            self.sleepScore = data.qualityPercentage
        } else {
            // Mock data if no sleep data available (for demo purposes)
            // In production, handle empty state gracefully
            self.sleepScore = 0
        }
    }
    
    private func loadWorkoutData(context: ModelContext) async {
        // Fetch today's workouts from SwiftData
        let todayStart = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.date >= todayStart
            }
        )
        
        do {
            let sessions = try context.fetch(descriptor)
            let completedSessions = sessions.filter { $0.isCompleted }
            
            self.workoutDuration = completedSessions.reduce(0) { $0 + ($1.duration ?? 0) }
            
            // Calculate strain based on duration and volume
            // This is a simplified strain calculation
            let volume = completedSessions.reduce(0.0) { sessionSum, session in
                sessionSum + session.exerciseLogs.reduce(0.0) { logSum, log in
                    logSum + log.sets.reduce(0.0) { setSum, set in
                        setSum + (set.weight ?? 0) * Double(set.actualReps ?? 0)
                    }
                }
            }
            
            // Normalize strain (arbitrary scaling for demo)
            let durationScore = min(workoutDuration / 3600.0 * 50.0, 50.0)
            let volumeScore = min(volume / 10000.0 * 50.0, 50.0)
            self.strainScore = Int(durationScore + volumeScore)
            
            // Estimate calories (mock)
            self.activeCalories = (workoutDuration / 60.0) * 5.0 // ~5 active cals/min
            
        } catch {
            print("Failed to fetch workout data: \(error)")
        }
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good Morning"
        case 12..<17: greeting = "Good Afternoon"
        default: greeting = "Good Evening"
        }
    }
}
