import SwiftUI
import SwiftData
import Combine

/// ViewModel for analytics dashboard
@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var repsData: [RepsDataPoint] = []
    @Published var frequencyData: [WorkoutFrequencyPoint] = []
    @Published var muscleGroupData: [MuscleGroupVolume] = []
    @Published var monthlyProgress: [MonthlyProgress] = []
    @Published var yearlyProgress: [YearlyProgress] = []
    @Published var personalRecords: [PersonalRecord] = []
    @Published var topExercises: [ExerciseStats] = []

    @Published var activeDays: Int = 0
    @Published var totalExercises: Int = 0
    @Published var totalReps: Int = 0

    @Published var selectedTimePeriod: TimePeriod = .month
    @Published var isLoading = false

    private var sessions: [WorkoutSession] = []

    // MARK: - Data Loading

    func loadAnalytics(sessions: [WorkoutSession]) {
        self.sessions = sessions
        isLoading = true

        Task {
            await refreshAllAnalytics()
            isLoading = false
        }
    }

    func refreshAllAnalytics() async {
        // Volume trends
        volumeData = AnalyticsService.calculateVolume(sessions: sessions, period: selectedTimePeriod)

        // Reps trends
        repsData = AnalyticsService.calculateRepsOverTime(sessions: sessions, period: selectedTimePeriod)

        // New Metrics
        activeDays = AnalyticsService.calculateActiveDays(sessions: sessions, period: selectedTimePeriod)
        totalExercises = AnalyticsService.calculateTotalExercises(sessions: sessions, period: selectedTimePeriod)
        totalReps = AnalyticsService.calculateTotalReps(sessions: sessions, period: selectedTimePeriod)
        topExercises = AnalyticsService.calculateTopExercises(sessions: sessions, period: selectedTimePeriod)

        // Workout frequency for last 90 days (heatmap always shows 90 days context)
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -90, to: endDate)!
        frequencyData = AnalyticsService.calculateWorkoutFrequency(
            sessions: sessions,
            startDate: startDate,
            endDate: endDate
        )

        // Muscle group distribution
        var muscleGroups = AnalyticsService.calculateVolumeByMuscleGroup(sessions: sessions)
        let totalVolume = muscleGroups.reduce(0) { $0 + $1.volume }
        muscleGroups = muscleGroups.map { group in
            var updated = group
            updated.percentage = totalVolume > 0 ? (group.volume / totalVolume) * 100 : 0
            return updated
        }
        muscleGroupData = muscleGroups

        // Progress summaries
        monthlyProgress = AnalyticsService.calculateMonthlyProgress(sessions: sessions)
        yearlyProgress = AnalyticsService.calculateYearlyProgress(sessions: sessions)

        // Personal records
        personalRecords = AnalyticsService.calculatePersonalRecords(sessions: sessions)
    }

    func updateTimePeriod(_ period: TimePeriod) {
        selectedTimePeriod = period
        // Refresh period-dependent data
        volumeData = AnalyticsService.calculateVolume(sessions: sessions, period: period)
        repsData = AnalyticsService.calculateRepsOverTime(sessions: sessions, period: period)
        activeDays = AnalyticsService.calculateActiveDays(sessions: sessions, period: period)
        totalExercises = AnalyticsService.calculateTotalExercises(sessions: sessions, period: period)
        totalReps = AnalyticsService.calculateTotalReps(sessions: sessions, period: period)
        topExercises = AnalyticsService.calculateTopExercises(sessions: sessions, period: period)
    }

    // MARK: - Computed Properties

    var totalWorkouts: Int {
        sessions.filter { $0.isCompleted }.count
    }

    var totalVolume: Double {
        sessions.filter { $0.isCompleted }.reduce(0) { sum, session in
            sum + session.exerciseLogs.reduce(0) { logSum, log in
                logSum + log.sets.reduce(0) { setSum, set in
                    guard set.isCompleted, let weight = set.weight, let reps = set.actualReps else {
                        return setSum
                    }
                    return setSum + (weight * Double(reps))
                }
            }
        }
    }

    var averageWorkoutDuration: TimeInterval {
        let completed = sessions.filter { $0.isCompleted && $0.duration != nil }
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0) { $0 + ($1.duration ?? 0) }
        return total / Double(completed.count)
    }

    var workoutsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return sessions.filter { $0.isCompleted && $0.date >= startOfMonth }.count
    }

    var volumeThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return sessions.filter { $0.isCompleted && $0.date >= startOfMonth }.reduce(0) { sum, session in
            sum + session.exerciseLogs.reduce(0) { logSum, log in
                logSum + log.sets.reduce(0) { setSum, set in
                    guard set.isCompleted, let weight = set.weight, let reps = set.actualReps else {
                        return setSum
                    }
                    return setSum + (weight * Double(reps))
                }
            }
        }
    }

    var volumeTrend: String {
        guard volumeData.count >= 2 else { return "0%" }
        let recent = volumeData.suffix(7).map { $0.volume }.reduce(0, +) / 7.0
        let previous = volumeData.prefix(7).map { $0.volume }.reduce(0, +) / 7.0
        guard previous > 0 else { return "0%" }
        let change = ((recent - previous) / previous) * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))%"
    }

    var mostTrainedMuscleGroup: String {
        muscleGroupData.first?.muscleGroup ?? "N/A"
    }

    var leastTrainedMuscleGroup: String {
        muscleGroupData.last?.muscleGroup ?? "N/A"
    }
}
