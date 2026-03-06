import Foundation

struct SleepData {
    let totalDuration: TimeInterval
    let deepDuration: TimeInterval
    let remDuration: TimeInterval
    let coreDuration: TimeInterval
    let quality: Double // 0.0 - 1.0
    let startDate: Date?
    let endDate: Date?

    var deepPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return deepDuration / totalDuration
    }

    var remPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return remDuration / totalDuration
    }

    var qualityPercentage: Int {
        Int(quality * 100)
    }

    var formattedTotal: String {
        let hours = Int(totalDuration / 3600)
        let minutes = Int(totalDuration.truncatingRemainder(dividingBy: 3600) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

protocol HealthDataProviding: Sendable {
    // Vitals
    func getHeartRateVariability(for date: Date) async -> Double?
    func getRestingHeartRate(for date: Date) async -> Double?
    func getRespiratoryRate(for date: Date) async -> Double?
    func getOxygenSaturation(for date: Date) async -> Double?
    func getBodyTemperature(for date: Date) async -> Double?
    func getVO2Max() async -> Double?

    // Activity
    func getStepCount(for date: Date) async -> Int
    func getActiveEnergyBurned(for date: Date) async -> Double?
    func getExerciseTime(for date: Date) async -> Double?
    func getStandHours(for date: Date) async -> Int?
    func getWalkingRunningDistance(for date: Date) async -> Double?

    // Sleep
    func getSleepData(for date: Date) async -> SleepData?

    // Historical
    func getHistoricalHRV(days: Int) async -> [(date: Date, value: Double)]
    func getHistoricalRHR(days: Int) async -> [(date: Date, value: Double)]
    func getHistoricalSleep(days: Int) async -> [(date: Date, duration: TimeInterval)]
    func getHistoricalActiveEnergy(days: Int) async -> [(date: Date, value: Double)]
    func getDailyActivityStats(days: Int) async -> [(date: Date, count: Int)]

    // Workouts
    func saveWorkout(workoutName: String, startTime: Date, endTime: Date,
                     duration: TimeInterval, totalVolume: Double) async throws

    // Authorization
    func requestAuthorization() async throws
}
