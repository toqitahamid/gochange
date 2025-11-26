import SwiftUI
import SwiftData
import Combine

/// ViewModel for analytics dashboard
@MainActor
class AnalyticsViewModel: ObservableObject {
    @Published var volumeData: [VolumeDataPoint] = []
    @Published var frequencyData: [WorkoutFrequencyPoint] = []
    @Published var muscleGroupData: [MuscleGroupVolume] = []
    @Published var monthlyProgress: [MonthlyProgress] = []
    @Published var yearlyProgress: [YearlyProgress] = []
    @Published var personalRecords: [PersonalRecord] = []

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

        // Workout frequency for last 90 days
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
        volumeData = AnalyticsService.calculateVolume(sessions: sessions, period: period)
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
