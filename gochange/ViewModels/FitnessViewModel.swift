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
    
    // Strain Data
    @Published var strainScore: Double = 0
    @Published var targetStrainLow: Double = 0
    @Published var targetStrainHigh: Double = 0
    @Published var strainStatus: String = "Optimal" // Optimal, Overreaching, Restoring, Undertraining
    
    private var healthKitService = HealthKitService.shared
    private var modelContext: ModelContext?
    
    // MARK: - Advanced Metrics
    @Published var dailyReadinessScore: Double = 0
    @Published var sleepDebt: Double = 0
    @Published var acwr: Double = 0
    @Published var systemicLoad: Double = 0
    
    // Status Messages
    @Published var dailyReadinessStatus: String = "Recovering"
    @Published var sleepDebtStatus: String = "Good"
    @Published var acwrStatus: String = "Optimal"
    
    // Internal Data for Calculations
    private var acuteLoad: Double = 0
    private var chronicLoad: Double = 0
    
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
        
        calculateStrain(totalVolume: total)
    }
    
    private func calculateStrain(totalVolume: Double) {
        // Simplified Strain Calculation
        // In a real app, this would combine Heart Rate data (Cardio Load) + Muscular Load
        
        // 1. Calculate Strength Strain (Logarithmic scale based on volume)
        // Assuming 10,000 lbs volume is a "moderate" workout (~10 strain)
        let strengthStrain = totalVolume > 0 ? 5.0 * log10(totalVolume / 100 + 1) : 0
        
        // 2. Calculate Cardio Strain (Mocked for now, or use HealthKit active energy)
        // Let's assume some base cardio strain from daily activity
        let cardioStrain = 4.0 // Placeholder
        
        // 3. Combine (Weighted average or max?)
        // Strain is usually cumulative. Let's add them but dampen the sum.
        let totalRawStrain = strengthStrain + cardioStrain
        
        // Cap at 21 for Whoop-like scale, or just let it ride.
        // Let's use a 0-21 scale.
        self.strainScore = min(21.0, totalRawStrain)
        
        // Calculate Target Strain based on Recovery (Mocked for now)
        // If recovery is high, target is high.
        let recoveryScore = 0.8 // 80%
        let baseTarget = 10.0 + (recoveryScore * 5.0) // 14.0
        
        self.targetStrainLow = baseTarget - 2.0
        self.targetStrainHigh = baseTarget + 2.0
        
        // Determine Status
        if strainScore < targetStrainLow {
            strainStatus = "Restoring"
        } else if strainScore > targetStrainHigh {
            strainStatus = "Overreaching"
        } else {
            strainStatus = "Optimal"
        }
    }
    
    private func calculateAdvancedMetrics() async {
        // 1. Daily Readiness Score
        // Formula: (HRV_Z * 0.4) + (Sleep_Z * 0.4) - (RHR_Z * 0.2)
        // We need historical data for Z-scores
        
        let hrvHistory = await healthKitService.getHistoricalHeartRateVariability(days: 30)
        let rhrHistory = await healthKitService.getHistoricalRestingHeartRate(days: 30)
        let sleepHistory = await healthKitService.getHistoricalSleepData(days: 30)
        
        // Get today's values
        let today = Calendar.current.startOfDay(for: Date())
        let todayHRV = await healthKitService.getHeartRateVariability(for: today) ?? 0
        let todayRHR = await healthKitService.getRestingHeartRate(for: today) ?? 0
        let todaySleep = (await healthKitService.getSleepData(for: today)?.totalDuration ?? 0)
        
        if !hrvHistory.isEmpty && !rhrHistory.isEmpty {
            let hrvZ = zScore(value: todayHRV, values: Array(hrvHistory.values))
            let rhrZ = zScore(value: todayRHR, values: Array(rhrHistory.values))
            let sleepZ = zScore(value: todaySleep, values: Array(sleepHistory.values))
            
            // Invert RHR Z-score (lower is better)
            let rawScore = (hrvZ * 0.4) + (sleepZ * 0.4) - (rhrZ * 0.2)
            
            // Normalize to 0-100 (assuming raw score range roughly -3 to +3)
            // Map -3 -> 0, +3 -> 100
            let normalized = max(0, min(100, (rawScore + 3.0) / 6.0 * 100.0))
            self.dailyReadinessScore = normalized
            
            // Determine Status
            if normalized >= 85 { dailyReadinessStatus = "Prime" }
            else if normalized >= 70 { dailyReadinessStatus = "Ready" }
            else if normalized >= 50 { dailyReadinessStatus = "Steady" }
            else if normalized >= 30 { dailyReadinessStatus = "Recovering" }
            else { dailyReadinessStatus = "Low" }
        }
        
        // 2. Sleep Debt
        // Rolling 14-day difference vs 8 hours (28800 seconds)
        let sleepNeed: TimeInterval = 28800
        var totalDebt: TimeInterval = 0
        
        // We need last 14 days of sleep
        let recentSleep = await healthKitService.getHistoricalSleepData(days: 14)
        for i in 0..<14 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            let dayStart = Calendar.current.startOfDay(for: date)
            let actualSleep = recentSleep[dayStart] ?? 0
            // If no data, assume they met need? Or assume 0? Let's assume 0 for debt calculation if strictly tracking.
            // But for user friendliness, maybe assume 0 debt if missing?
            // Let's assume debt accumulates if data exists, otherwise ignore day.
            if recentSleep[dayStart] != nil {
                totalDebt += (sleepNeed - actualSleep)
            }
        }
        
        self.sleepDebt = max(0, totalDebt / 3600.0) // In hours
        
        if sleepDebt < 2 { sleepDebtStatus = "Well Rested" }
        else if sleepDebt < 5 { sleepDebtStatus = "Minor Debt" }
        else if sleepDebt < 10 { sleepDebtStatus = "Moderate Debt" }
        else { sleepDebtStatus = "High Debt" }
        
        // 3. ACWR & Systemic Load
        // We need daily loads for last 28 days
        // Load = Strength Volume/100 + Cardio TRIMP (mocked)
        
        // Fetch sessions for last 28 days
        // Note: We already fetched sessions for strength data, but we need to process them day by day
        // For simplicity, let's re-use logic or just calculate from what we have if possible.
        // But fetchStrengthData stores aggregates.
        // Let's do a quick fetch for ACWR specifically or rely on AnalyticsService if we could.
        // Since this is ViewModel, let's do a quick calculation.
        
        let acwrData = AnalyticsService.calculateACWRTrend(sessions: await fetchSessionsForACWR())
        if let lastPoint = acwrData.last {
            self.acwr = lastPoint.ratio
            self.acuteLoad = lastPoint.acuteLoad
            self.chronicLoad = lastPoint.chronicLoad
            
            if acwr >= 0.8 && acwr <= 1.3 { acwrStatus = "Sweet Spot" }
            else if acwr > 1.5 { acwrStatus = "High Risk" }
            else { acwrStatus = "Undertraining" }
        }
        
        // Systemic Load (Today)
        let systemicData = AnalyticsService.calculateSystemicLoadBreakdown(sessions: await fetchSessionsForACWR())
        if let todayLoad = systemicData.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            self.systemicLoad = todayLoad.totalLoad
        } else {
            self.systemicLoad = 0
        }
    }
    
    private func fetchSessionsForACWR() async -> [WorkoutSession] {
        guard let context = modelContext else { return [] }
        let startDate = Calendar.current.date(byAdding: .day, value: -60, to: Date())!
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted && $0.date >= startDate }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    private func zScore(value: Double, values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let stdDev = sqrt(values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count))
        return stdDev > 0 ? (value - mean) / stdDev : 0
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
