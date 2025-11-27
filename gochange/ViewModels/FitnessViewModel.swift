import SwiftUI
import SwiftData
import HealthKit
import Combine

@MainActor
class FitnessViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var muscleGroupVolumes: [String: Double] = [
        "Chest": 0, "Back": 0, "Legs": 0, "Shoulders": 0, "Core": 0, "Arms": 0
    ]
    @Published var muscleGroupFrequency: [String: Double] = [
        "Chest": 0, "Back": 0, "Legs": 0, "Shoulders": 0, "Core": 0, "Arms": 0
    ]
    @Published var muscleGroupLoad: [String: Double] = [
        "Chest": 0, "Back": 0, "Legs": 0, "Shoulders": 0, "Core": 0, "Arms": 0
    ]
    
    @Published var selectedStrengthMetric: StrengthMetric = .muscularLoad
    
    enum StrengthMetric: String, CaseIterable {
        case totalVolume = "Total Volume"
        case workoutFrequency = "Workout Frequency"
        case muscularLoad = "Muscular Load"
    }
    
    @Published var totalVolume: Double = 0
    
    // HealthKit Data
    @Published var restingHeartRate: Double = 0
    @Published var cardioFocusStatus: String = "Low Aerobic"
    @Published var cardioFocusPercentage: Double = 0.94
    
    private var healthKitService = HealthKitService.shared
    private var modelContext: ModelContext?
    
    // MARK: - Setup
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchStrengthData()
    }
    
    // MARK: - Data Fetching
    func fetchData() async {
        // Fetch HealthKit Data
        if let rhr = await healthKitService.getRestingHeartRate(for: Date()) {
            self.restingHeartRate = rhr
        }
        
        // Refresh Strength Data
        fetchStrengthData()
    }
    
    private func fetchStrengthData() {
        guard let context = modelContext else { return }
        
        // Calculate start date (30 days ago)
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Fetch completed sessions
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.isCompleted && session.date >= startDate
            }
        )
        
        guard let sessions = try? context.fetch(descriptor) else { return }
        
        var volumes: [String: Double] = [
            "Chest": 0, "Back": 0, "Legs": 0, "Shoulders": 0, "Core": 0, "Arms": 0
        ]
        var frequency: [String: Double] = [
            "Chest": 0, "Back": 0, "Legs": 0, "Shoulders": 0, "Core": 0, "Arms": 0
        ]
        var total: Double = 0
        
        // Fetch all exercises to map IDs to muscle groups
        // Note: In a real app, we might want to cache this or optimize the query
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let allExercises = (try? context.fetch(exerciseDescriptor)) ?? []
        let exerciseMap = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
        
        for session in sessions {
            for log in session.exerciseLogs {
                guard let exercise = exerciseMap[log.exerciseId] else { continue }
                
                let exerciseVolume = log.sets.reduce(0.0) { result, set in
                    if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                        return result + (weight * Double(reps))
                    }
                    return result
                }
                
                // Normalize muscle group names if needed
                let group = normalizeMuscleGroup(exercise.muscleGroup)
                volumes[group, default: 0] += exerciseVolume
                total += exerciseVolume
                
                // Count frequency (sets or sessions? Let's do sets for granularity, or just 1 per session if present)
                // For now, let's count sets as "frequency" of hitting that muscle
                frequency[group, default: 0] += Double(log.sets.count)
            }
        }
        
        self.muscleGroupVolumes = volumes
        self.muscleGroupFrequency = frequency
        self.totalVolume = total
        
        // Calculate Muscular Load (Percentage of Total Volume)
        var load: [String: Double] = [:]
        for (group, vol) in volumes {
            load[group] = total > 0 ? (vol / total) : 0
        }
        self.muscleGroupLoad = load
    }
    
    private func normalizeMuscleGroup(_ group: String) -> String {
        // Map various inputs to our standard 6 categories
        // This depends on what strings are actually stored in Exercise.muscleGroup
        let lower = group.lowercased()
        if lower.contains("chest") { return "Chest" }
        if lower.contains("back") || lower.contains("lats") { return "Back" }
        if lower.contains("leg") || lower.contains("quad") || lower.contains("hamstring") || lower.contains("calf") || lower.contains("glute") { return "Legs" }
        if lower.contains("shoulder") || lower.contains("delt") { return "Shoulders" }
        if lower.contains("core") || lower.contains("ab") { return "Core" }
        if lower.contains("arm") || lower.contains("bicep") || lower.contains("tricep") { return "Arms" }
        return "Other"
    }
}
