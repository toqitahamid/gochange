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

    @Published var cardioFocusPercentage: Double = 0
    @Published var cardioLoadHistory: [Double] = []
    
    // RHR Status
    @Published var rhrStatus: String = "Normal"
    
    // Strain Data
    @Published var strainScore: Double = 0
    @Published var targetStrainLow: Double = 0
    @Published var targetStrainHigh: Double = 0
    @Published var strainStatus: String = "Optimal" // Optimal, Overreaching, Restoring, Undertraining
    
    // Strain vs Recovery Correlation Data
    @Published var strainRecoveryData: [StrainRecoveryDataPoint] = []
    @Published var isLoadingStrainRecoveryData: Bool = false
    
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
    func fetchData(for range: TimeRange = .month) async {
        currentTimeRange = range
        
        // Fetch HealthKit Data
        if let rhr = await healthKitService.getRestingHeartRate(for: Date()) {
            self.restingHeartRate = rhr
            updateRHRStatus(rhr)
        }
        
        // Fetch Cardio Load History based on selected range
        let history = await healthKitService.getHistoricalActiveEnergy(days: range.days)
        // Sort by date and extract values
        let sortedHistory = history.sorted { $0.key < $1.key }.map { $0.value }
        self.cardioLoadHistory = sortedHistory
        
        // Refresh Strength Data with range
        fetchStrengthData(for: range)

        // Update cardio focus metrics from fetched load history
        updateCardioFocusMetrics()

        // Fetch Strain vs Recovery correlation data
        await fetchStrainRecoveryData(for: range)
    }
    
    // Track current time range
    private var currentTimeRange: TimeRange = .month
    
    private func fetchStrengthData(for range: TimeRange = .month) {
        guard let context = modelContext else { return }
        
        // Calculate start date based on selected range
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        
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
    
    /// Update cardioFocusPercentage and cardioFocusStatus from session data.
    /// Cardio focus = days with active energy recorded / total days in the loaded history.
    private func updateCardioFocusMetrics() {
        guard !cardioLoadHistory.isEmpty else {
            cardioFocusPercentage = 0
            cardioFocusStatus = "No Data"
            return
        }
        let activeDays = cardioLoadHistory.filter { $0 > 0 }.count
        let percentage = Double(activeDays) / Double(cardioLoadHistory.count)
        cardioFocusPercentage = percentage

        switch percentage {
        case 0.75...:
            cardioFocusStatus = "High Aerobic"
        case 0.5..<0.75:
            cardioFocusStatus = "Moderate Aerobic"
        case 0.25..<0.5:
            cardioFocusStatus = "Low Aerobic"
        default:
            cardioFocusStatus = "Minimal Aerobic"
        }
    }

    /// Calculate strain score from workout volume (0-21 scale)
    /// - Parameters:
    ///   - totalVolume: Total weight volume in lbs/kg
    ///   - duration: Optional workout duration in seconds
    /// - Returns: Strain score on 0-21 scale
    private func calculateStrainScore(totalVolume: Double, duration: TimeInterval = 0) -> Double {
        // Simplified Strain Calculation
        // In a real app, this would combine Heart Rate data (Cardio Load) + Muscular Load
        
        // 1. Calculate Strength Strain (Logarithmic scale based on volume)
        // Assuming 10,000 lbs volume is a "moderate" workout (~10 strain)
        let strengthStrain = totalVolume > 0 ? 5.0 * log10(totalVolume / 100 + 1) : 0
        
        // 2. Calculate Cardio Strain from active energy history (kcal-based estimate)
        // Average daily active energy; 500 kcal/day maps to ~4 strain on 0-21 scale
        let avgActiveEnergy = cardioLoadHistory.isEmpty ? 0.0 : cardioLoadHistory.reduce(0, +) / Double(cardioLoadHistory.count)
        let cardioStrain = avgActiveEnergy > 0 ? min(10.0, avgActiveEnergy / 125.0) : 0.0
        
        // 3. Combine (Weighted average or max?)
        // Strain is usually cumulative. Let's add them but dampen the sum.
        let totalRawStrain = strengthStrain + cardioStrain
        
        // Cap at 21 for Whoop-like scale
        return min(21.0, totalRawStrain)
    }
    
    /// Convert strain score from 0-21 scale to 0-100 scale
    private func strainScoreToPercentage(_ score: Double) -> Double {
        return min(100.0, (score / 21.0) * 100.0)
    }
    
    private func calculateStrain(totalVolume: Double) {
        // Calculate strain score (0-21 scale)
        let rawStrain = calculateStrainScore(totalVolume: totalVolume)
        self.strainScore = rawStrain
        
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
    
    private func updateRHRStatus(_ rhr: Double) {
        if rhr < 60 {
            rhrStatus = "Excellent"
        } else if rhr < 70 {
            rhrStatus = "Good"
        } else if rhr < 80 {
            rhrStatus = "Fair"
        } else {
            rhrStatus = "Elevated"
        }
    }
    
    // MARK: - Strain vs Recovery Correlation
    
    /// Fetch historical strain and recovery data for correlation chart
    func fetchStrainRecoveryData(for range: TimeRange = .month) async {
        guard let context = modelContext else { return }
        
        isLoadingStrainRecoveryData = true
        defer { isLoadingStrainRecoveryData = false }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -range.days, to: Date()) ?? Date()
        let endDate = Date()
        
        // Fetch recovery metrics
        let recoveryDescriptor = FetchDescriptor<RecoveryMetrics>(
            predicate: #Predicate { metrics in
                metrics.date >= startDate && metrics.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        let recoveryMetrics = (try? context.fetch(recoveryDescriptor)) ?? []
        
        // Fetch workout sessions for strain calculation
        let sessionDescriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.isCompleted && session.date >= startDate && session.date <= endDate
            },
            sortBy: [SortDescriptor(\.date)]
        )
        
        let sessions = (try? context.fetch(sessionDescriptor)) ?? []
        
        // Group sessions by date
        var sessionsByDate: [Date: [WorkoutSession]] = [:]
        for session in sessions {
            let dayStart = calendar.startOfDay(for: session.date)
            sessionsByDate[dayStart, default: []].append(session)
        }
        
        // Create data points for each day
        var dataPoints: [StrainRecoveryDataPoint] = []
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            
            // Calculate recovery score for this day
            let recoveryScore: Double = {
                if let metric = recoveryMetrics.first(where: { calendar.isDate($0.date, inSameDayAs: dayStart) }) {
                    return metric.overallRecoveryScore * 100 // Convert to 0-100 scale
                }
                return 0
            }()
            
            // Calculate strain score for this day
            let strainScore: Double = {
                if let daySessions = sessionsByDate[dayStart], !daySessions.isEmpty {
                    // Calculate total volume for the day
                    let totalVolume = daySessions.reduce(0.0) { sessionSum, session in
                        sessionSum + session.exerciseLogs.reduce(0.0) { logSum, log in
                            logSum + log.sets.reduce(0.0) { setSum, set in
                                if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                                    return setSum + (weight * Double(reps))
                                }
                                return setSum
                            }
                        }
                    }
                    
                    // Calculate duration
                    let totalDuration = daySessions.reduce(0.0) { $0 + ($1.duration ?? 0) }
                    
                    // Calculate strain using standardized method
                    let rawStrain = calculateStrainScore(totalVolume: totalVolume, duration: totalDuration)
                    
                    // Convert to 0-100 scale (from 0-21 scale)
                    return strainScoreToPercentage(rawStrain)
                }
                return 0
            }()
            
            // Only add data point if we have at least recovery or strain data
            if recoveryScore > 0 || strainScore > 0 {
                dataPoints.append(StrainRecoveryDataPoint(
                    date: dayStart,
                    recoveryScore: recoveryScore,
                    strainScore: strainScore
                ))
            }
            
            // Move to next day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? endDate
        }
        
        self.strainRecoveryData = dataPoints
    }
}

// MARK: - Supporting Types

struct StrainRecoveryDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let recoveryScore: Double // 0-100
    let strainScore: Double // 0-100
}
