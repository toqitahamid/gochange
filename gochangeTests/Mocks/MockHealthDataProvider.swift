import Foundation
@testable import gochange

final class MockHealthDataProvider: HealthDataProviding, @unchecked Sendable {
    var hrvValue: Double? = 45.0
    var rhrValue: Double? = 62.0
    var respiratoryRate: Double? = 16.0
    var oxygenSaturation: Double? = 98.0
    var bodyTemperature: Double? = 36.6
    var vo2Max: Double? = 42.0
    var stepCount: Int = 8500
    var activeEnergy: Double? = 450.0
    var exerciseTime: Double? = 45.0
    var standHours: Int? = 10
    var walkingDistance: Double? = 5.2
    var sleepData: SleepData? = SleepData(
        totalDuration: 7.5 * 3600,
        deepDuration: 1.5 * 3600,
        remDuration: 1.8 * 3600,
        coreDuration: 4.2 * 3600,
        quality: 0.82,
        startDate: nil, endDate: nil
    )
    var savedWorkouts: [(String, Date, Date)] = []

    func getHeartRateVariability(for date: Date) async -> Double? { hrvValue }
    func getRestingHeartRate(for date: Date) async -> Double? { rhrValue }
    func getRespiratoryRate(for date: Date) async -> Double? { respiratoryRate }
    func getOxygenSaturation(for date: Date) async -> Double? { oxygenSaturation }
    func getBodyTemperature(for date: Date) async -> Double? { bodyTemperature }
    func getVO2Max() async -> Double? { vo2Max }
    func getStepCount(for date: Date) async -> Int { stepCount }
    func getActiveEnergyBurned(for date: Date) async -> Double? { activeEnergy }
    func getExerciseTime(for date: Date) async -> Double? { exerciseTime }
    func getStandHours(for date: Date) async -> Int? { standHours }
    func getWalkingRunningDistance(for date: Date) async -> Double? { walkingDistance }
    func getSleepData(for date: Date) async -> SleepData? { sleepData }
    func getHistoricalHRV(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getHistoricalRHR(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getHistoricalSleep(days: Int) async -> [(date: Date, duration: TimeInterval)] { [] }
    func getHistoricalActiveEnergy(days: Int) async -> [(date: Date, value: Double)] { [] }
    func getDailyActivityStats(days: Int) async -> [(date: Date, count: Int)] { [] }
    func saveWorkout(workoutName: String, startTime: Date, endTime: Date,
                     duration: TimeInterval, totalVolume: Double) async throws {
        savedWorkouts.append((workoutName, startTime, endTime))
    }
    func requestAuthorization() async throws {}
}
