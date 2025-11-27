import Foundation
import SwiftData

/// Service for processing workout data and generating analytics
struct AnalyticsService {

    // MARK: - Volume Analytics

    /// Calculate total volume (weight × reps) for a time period
    static func calculateVolume(sessions: [WorkoutSession], period: TimePeriod) -> [VolumeDataPoint] {
        let filteredSessions = filterSessions(sessions, for: period)
        let groupedByDate = groupSessionsByDate(filteredSessions)

        return groupedByDate.map { date, sessions in
            let totalVolume = sessions.reduce(0.0) { sum, session in
                sum + calculateSessionVolume(session)
            }
            return VolumeDataPoint(date: date, volume: totalVolume)
        }.sorted { $0.date < $1.date }
    }

    /// Calculate volume by muscle group
    static func calculateVolumeByMuscleGroup(sessions: [WorkoutSession]) -> [MuscleGroupVolume] {
        var muscleGroupData: [String: Double] = [:]

        for session in sessions.filter({ $0.isCompleted }) {
            for log in session.exerciseLogs {
                // Get muscle group from exercise name/log
                let muscleGroup = extractMuscleGroup(from: log)
                let volume = log.sets.reduce(0.0) { sum, set in
                    guard set.isCompleted,
                          let weight = set.weight,
                          let reps = set.actualReps else { return sum }
                    return sum + (weight * Double(reps))
                }
                muscleGroupData[muscleGroup, default: 0] += volume
            }
        }

        return muscleGroupData.map { MuscleGroupVolume(muscleGroup: $0.key, volume: $0.value) }
            .sorted { $0.volume > $1.volume }
    }

    // MARK: - New Analytics

    /// Calculate total active days for a time period
    static func calculateActiveDays(sessions: [WorkoutSession], period: TimePeriod) -> Int {
        let filteredSessions = filterSessions(sessions, for: period)
        let calendar = Calendar.current
        let uniqueDays = Set(filteredSessions.map { calendar.startOfDay(for: $0.date) })
        return uniqueDays.count
    }

    /// Calculate total exercises performed for a time period
    static func calculateTotalExercises(sessions: [WorkoutSession], period: TimePeriod) -> Int {
        let filteredSessions = filterSessions(sessions, for: period)
        return filteredSessions.reduce(0) { sum, session in
            sum + session.exerciseLogs.count
        }
    }

    /// Calculate total reps performed for a time period
    static func calculateTotalReps(sessions: [WorkoutSession], period: TimePeriod) -> Int {
        let filteredSessions = filterSessions(sessions, for: period)
        return filteredSessions.reduce(0) { sessionSum, session in
            sessionSum + session.exerciseLogs.reduce(0) { logSum, log in
                logSum + log.sets.reduce(0) { setSum, set in
                    guard set.isCompleted, let reps = set.actualReps else { return setSum }
                    return setSum + reps
                }
            }
        }
    }

    /// Calculate top exercises by frequency
    static func calculateTopExercises(sessions: [WorkoutSession], period: TimePeriod, limit: Int = 5) -> [ExerciseStats] {
        let filteredSessions = filterSessions(sessions, for: period)
        var exerciseStats: [String: (count: Int, volume: Double, reps: Int)] = [:]

        for session in filteredSessions {
            for log in session.exerciseLogs {
                let name = log.exerciseName
                let current = exerciseStats[name] ?? (count: 0, volume: 0, reps: 0)
                
                let logVolume = log.sets.reduce(0.0) { sum, set in
                    guard set.isCompleted, let weight = set.weight, let reps = set.actualReps else { return sum }
                    return sum + (weight * Double(reps))
                }
                
                let logReps = log.sets.reduce(0) { sum, set in
                    guard set.isCompleted, let reps = set.actualReps else { return sum }
                    return sum + reps
                }

                exerciseStats[name] = (
                    count: current.count + 1,
                    volume: current.volume + logVolume,
                    reps: current.reps + logReps
                )
            }
        }

        return exerciseStats.map { name, stats in
            ExerciseStats(
                exerciseName: name,
                count: stats.count,
                totalVolume: stats.volume,
                totalReps: stats.reps
            )
        }
        .sorted { $0.count > $1.count } // Sort by frequency
        .prefix(limit)
        .map { $0 }
    }

    /// Calculate total reps for a time period (for graph)
    static func calculateRepsOverTime(sessions: [WorkoutSession], period: TimePeriod) -> [RepsDataPoint] {
        let filteredSessions = filterSessions(sessions, for: period)
        let groupedByDate = groupSessionsByDate(filteredSessions)

        return groupedByDate.map { date, sessions in
            let totalReps = sessions.reduce(0) { sessionSum, session in
                sessionSum + session.exerciseLogs.reduce(0) { logSum, log in
                    logSum + log.sets.reduce(0) { setSum, set in
                        guard set.isCompleted, let reps = set.actualReps else { return setSum }
                        return setSum + reps
                    }
                }
            }
            return RepsDataPoint(date: date, reps: totalReps)
        }.sorted { $0.date < $1.date }
    }

    // MARK: - Frequency Analytics

    /// Generate workout frequency data for heatmap
    static func calculateWorkoutFrequency(sessions: [WorkoutSession], startDate: Date, endDate: Date) -> [WorkoutFrequencyPoint] {
        let calendar = Calendar.current
        let filteredSessions = sessions.filter {
            $0.isCompleted && $0.date >= startDate && $0.date <= endDate
        }

        // Group sessions by day
        var frequencyMap: [Date: Int] = [:]
        for session in filteredSessions {
            let dayStart = calendar.startOfDay(for: session.date)
            frequencyMap[dayStart, default: 0] += 1
        }

        // Create data points for all days in range
        var dataPoints: [WorkoutFrequencyPoint] = []
        var currentDate = calendar.startOfDay(for: startDate)

        while currentDate <= endDate {
            let count = frequencyMap[currentDate] ?? 0
            let intensity = calculateIntensity(count: count)
            dataPoints.append(WorkoutFrequencyPoint(date: currentDate, workoutCount: count, intensity: intensity))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dataPoints
    }

    // MARK: - Progress Summaries

    /// Generate monthly progress summaries
    static func calculateMonthlyProgress(sessions: [WorkoutSession]) -> [MonthlyProgress] {
        let calendar = Calendar.current
        var monthlyData: [String: MonthlyProgressBuilder] = [:]

        for session in sessions.filter({ $0.isCompleted }) {
            let components = calendar.dateComponents([.year, .month], from: session.date)
            let monthKey = "\(components.year!)-\(String(format: "%02d", components.month!))"

            if monthlyData[monthKey] == nil {
                monthlyData[monthKey] = MonthlyProgressBuilder(
                    year: components.year!,
                    month: components.month!
                )
            }

            monthlyData[monthKey]?.workoutCount += 1
            monthlyData[monthKey]?.totalVolume += calculateSessionVolume(session)
            if let duration = session.duration {
                monthlyData[monthKey]?.totalDuration += duration
            }
        }

        return monthlyData.values.map { builder in
            MonthlyProgress(
                year: builder.year,
                month: builder.month,
                workoutCount: builder.workoutCount,
                totalVolume: builder.totalVolume,
                totalDuration: builder.totalDuration,
                averageDuration: builder.workoutCount > 0 ? builder.totalDuration / Double(builder.workoutCount) : 0
            )
        }.sorted {
            if $0.year != $1.year {
                return $0.year > $1.year
            }
            return $0.month > $1.month
        }
    }

    /// Generate yearly progress summaries
    static func calculateYearlyProgress(sessions: [WorkoutSession]) -> [YearlyProgress] {
        let calendar = Calendar.current
        var yearlyData: [Int: YearlyProgressBuilder] = [:]

        for session in sessions.filter({ $0.isCompleted }) {
            let year = calendar.component(.year, from: session.date)

            if yearlyData[year] == nil {
                yearlyData[year] = YearlyProgressBuilder(year: year)
            }

            yearlyData[year]?.workoutCount += 1
            yearlyData[year]?.totalVolume += calculateSessionVolume(session)
            if let duration = session.duration {
                yearlyData[year]?.totalDuration += duration
            }
        }

        return yearlyData.values.map { builder in
            YearlyProgress(
                year: builder.year,
                workoutCount: builder.workoutCount,
                totalVolume: builder.totalVolume,
                totalDuration: builder.totalDuration,
                averageDuration: builder.workoutCount > 0 ? builder.totalDuration / Double(builder.workoutCount) : 0
            )
        }.sorted { $0.year > $1.year }
    }

    // MARK: - Personal Records

    /// Find personal records for exercises
    static func calculatePersonalRecords(sessions: [WorkoutSession]) -> [PersonalRecord] {
        var recordsByExercise: [String: PersonalRecordBuilder] = [:]

        for session in sessions.filter({ $0.isCompleted }) {
            for log in session.exerciseLogs {
                if recordsByExercise[log.exerciseName] == nil {
                    recordsByExercise[log.exerciseName] = PersonalRecordBuilder(exerciseName: log.exerciseName)
                }

                for set in log.sets where set.isCompleted {
                    if let weight = set.weight, let reps = set.actualReps {
                        let builder = recordsByExercise[log.exerciseName]!

                        // Max weight
                        if weight > builder.maxWeight {
                            recordsByExercise[log.exerciseName]?.maxWeight = weight
                            recordsByExercise[log.exerciseName]?.maxWeightDate = session.date
                        }

                        // Max reps
                        if reps > builder.maxReps {
                            recordsByExercise[log.exerciseName]?.maxReps = reps
                            recordsByExercise[log.exerciseName]?.maxRepsDate = session.date
                        }

                        // Max volume (single set)
                        let volume = weight * Double(reps)
                        if volume > builder.maxVolume {
                            recordsByExercise[log.exerciseName]?.maxVolume = volume
                            recordsByExercise[log.exerciseName]?.maxVolumeDate = session.date
                        }
                    }
                }
            }
        }

        return recordsByExercise.values.map { builder in
            PersonalRecord(
                exerciseName: builder.exerciseName,
                maxWeight: builder.maxWeight,
                maxWeightDate: builder.maxWeightDate,
                maxReps: builder.maxReps,
                maxRepsDate: builder.maxRepsDate,
                maxVolume: builder.maxVolume,
                maxVolumeDate: builder.maxVolumeDate
            )
        }.sorted { $0.exerciseName < $1.exerciseName }
    }

    // MARK: - Helper Methods

    private static func calculateSessionVolume(_ session: WorkoutSession) -> Double {
        var total = 0.0
        for log in session.exerciseLogs {
            for set in log.sets where set.isCompleted {
                if let weight = set.weight, let reps = set.actualReps {
                    total += weight * Double(reps)
                }
            }
        }
        return total
    }

    private static func filterSessions(_ sessions: [WorkoutSession], for period: TimePeriod) -> [WorkoutSession] {
        let startDate = period.startDate
        return sessions.filter { $0.isCompleted && $0.date >= startDate }
    }

    private static func groupSessionsByDate(_ sessions: [WorkoutSession]) -> [(Date, [WorkoutSession])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.date)
        }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }
    }

    private static func extractMuscleGroup(from log: ExerciseLog) -> String {
        // Common muscle groups based on exercise name patterns
        let name = log.exerciseName.lowercased()

        if name.contains("chest") || name.contains("bench") || name.contains("press") && (name.contains("chest") || name.contains("pec")) {
            return "Chest"
        } else if name.contains("back") || name.contains("row") || name.contains("pull") || name.contains("lat") {
            return "Back"
        } else if name.contains("shoulder") || name.contains("lateral") || name.contains("overhead") {
            return "Shoulders"
        } else if name.contains("bicep") || name.contains("curl") && !name.contains("leg") {
            return "Biceps"
        } else if name.contains("tricep") || name.contains("extension") || name.contains("dip") {
            return "Triceps"
        } else if name.contains("quad") || name.contains("squat") || name.contains("leg press") {
            return "Quadriceps"
        } else if name.contains("hamstring") || name.contains("leg curl") {
            return "Hamstrings"
        } else if name.contains("calf") || name.contains("calves") {
            return "Calves"
        } else if name.contains("glute") {
            return "Glutes"
        } else if name.contains("ab") || name.contains("core") || name.contains("plank") {
            return "Core"
        } else {
            return "Other"
        }
    }

    private static func calculateIntensity(count: Int) -> Double {
        // Map workout count to intensity (0-1)
        switch count {
        case 0: return 0.0
        case 1: return 0.3
        case 2: return 0.6
        default: return 1.0
        }
    }
}

// MARK: - Data Models

enum TimePeriod {
    case week
    case month
    case threeMonths
    case sixMonths
    case year
    case allTime

    var startDate: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now)!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now)!
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now)!
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)!
        case .allTime:
            return Date.distantPast
        }
    }

    var displayName: String {
        switch self {
        case .week: return "7 Days"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        case .allTime: return "All Time"
        }
    }
}

struct VolumeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}

struct MuscleGroupVolume: Identifiable {
    let id = UUID()
    let muscleGroup: String
    let volume: Double

    var percentage: Double = 0
}

struct WorkoutFrequencyPoint: Identifiable {
    let id = UUID()
    let date: Date
    let workoutCount: Int
    let intensity: Double
}

struct MonthlyProgress: Identifiable {
    let id = UUID()
    let year: Int
    let month: Int
    let workoutCount: Int
    let totalVolume: Double
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month))!
        return formatter.string(from: date)
    }

    var displayDate: String {
        "\(monthName) \(year)"
    }
}

struct YearlyProgress: Identifiable {
    let id = UUID()
    let year: Int
    let workoutCount: Int
    let totalVolume: Double
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
}

struct PersonalRecord: Identifiable {
    let id = UUID()
    let exerciseName: String
    let maxWeight: Double
    let maxWeightDate: Date
    let maxReps: Int
    let maxRepsDate: Date
    let maxVolume: Double
    let maxVolumeDate: Date
}

struct ExerciseStats: Identifiable {
    let id = UUID()
    let exerciseName: String
    let count: Int
    let totalVolume: Double
    let totalReps: Int
}

struct RepsDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let reps: Int
}

// MARK: - Builder Helpers

private struct MonthlyProgressBuilder {
    let year: Int
    let month: Int
    var workoutCount: Int = 0
    var totalVolume: Double = 0
    var totalDuration: TimeInterval = 0
}

private struct YearlyProgressBuilder {
    let year: Int
    var workoutCount: Int = 0
    var totalVolume: Double = 0
    var totalDuration: TimeInterval = 0
}

private struct PersonalRecordBuilder {
    let exerciseName: String
    var maxWeight: Double = 0
    var maxWeightDate: Date = Date()
    var maxReps: Int = 0
    var maxRepsDate: Date = Date()
    var maxVolume: Double = 0
    var maxVolumeDate: Date = Date()
}
