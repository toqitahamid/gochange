import SwiftUI
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var loadState: LoadState = .idle

    // MARK: - Scores (0-100)
    @Published var recoveryScore: Int = 0
    @Published var sleepScore: Int = 0
    @Published var strainScore: Int = 0

    // MARK: - Vitals
    @Published var hrv: Double = 0
    @Published var restingHR: Double = 0
    @Published var respiratoryRate: Double?
    @Published var oxygenSaturation: Double?
    @Published var bodyTemperature: Double?
    @Published var vo2Max: Double?
    @Published var stepCount: Int = 0

    // MARK: - Sleep
    @Published var sleepData: SleepData?

    // MARK: - Activity Rings
    @Published var moveCalories: Double = 0
    @Published var moveTarget: Double = 600
    @Published var exerciseMinutes: Double = 0
    @Published var exerciseTarget: Double = 30
    @Published var standHours: Int = 0
    @Published var standTarget: Int = 12

    // MARK: - Workouts
    @Published var recentWorkouts: [WorkoutSession] = []

    // MARK: - Greeting
    @Published var greeting: String = ""

    // MARK: - Dependencies
    private let healthProvider: HealthDataProviding

    init(healthProvider: HealthDataProviding = HealthKitService.shared) {
        self.healthProvider = healthProvider
        updateGreeting()
    }

    func loadData(context: ModelContext?) async {
        loadState = .loading

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadVitals() }
            group.addTask { await self.loadSleep() }
            group.addTask { await self.loadActivity() }
            if let context = context {
                group.addTask { await self.loadWorkouts(context: context) }
            }
        }

        calculateScores()
        loadState = .loaded
    }

    private func loadVitals() async {
        let today = Calendar.current.startOfDay(for: Date())
        hrv = await healthProvider.getHeartRateVariability(for: today) ?? 0
        restingHR = await healthProvider.getRestingHeartRate(for: today) ?? 0
        respiratoryRate = await healthProvider.getRespiratoryRate(for: today)
        oxygenSaturation = await healthProvider.getOxygenSaturation(for: today)
        bodyTemperature = await healthProvider.getBodyTemperature(for: today)
        stepCount = await healthProvider.getStepCount(for: today)
        vo2Max = await healthProvider.getVO2Max()
    }

    private func loadSleep() async {
        let today = Calendar.current.startOfDay(for: Date())
        sleepData = await healthProvider.getSleepData(for: today)
    }

    private func loadActivity() async {
        let today = Date()
        moveCalories = await healthProvider.getActiveEnergyBurned(for: today) ?? 0
        exerciseMinutes = await healthProvider.getExerciseTime(for: today) ?? 0
        standHours = await healthProvider.getStandHours(for: today) ?? 0
    }

    private func loadWorkouts(context: ModelContext) async {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted && $0.date >= sevenDaysAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentWorkouts = (try? context.fetch(descriptor)) ?? []
    }

    private func calculateScores() {
        // Recovery: Based on HRV and RHR
        if hrv > 0 || restingHR > 0 {
            let hrvScore = hrv > 0 ? min(max((hrv / 60.0) * 60.0 + 20.0, 0), 100) : 50
            let rhrScore = restingHR > 0 ? min(max((65.0 / max(restingHR, 40.0)) * 60.0 + 10.0, 0), 100) : 50
            recoveryScore = Int((hrvScore + rhrScore) / 2.0)
        } else {
            recoveryScore = 0
        }

        // Sleep: Based on duration and quality
        if let sleep = sleepData {
            let hours = sleep.totalDuration / 3600.0
            let durationScore = min(max((hours / 8.0) * 60.0 + 20.0, 0), 100)
            let qualityScore = sleep.quality * 100.0
            sleepScore = Int((durationScore + qualityScore) / 2.0)
        } else {
            sleepScore = 0
        }

        // Strain: Based on active energy and exercise time
        if moveCalories > 0 {
            let energyScore = min(moveCalories / 8.0, 100)
            let exerciseScore = min(exerciseMinutes * 1.5, 100)
            strainScore = Int((energyScore + exerciseScore) / 2.0)
        } else {
            strainScore = 0
        }
    }

    // MARK: - Deterministic Insight Text
    var insightText: String {
        if recoveryScore >= 80 {
            return "Recovery is strong today. Great conditions for a challenging workout."
        } else if recoveryScore >= 60 {
            return "Solid recovery. You're ready for a normal training session."
        } else if recoveryScore >= 40 {
            return "Moderate recovery. Consider a lighter intensity today."
        } else if recoveryScore > 0 {
            return "Recovery is low. Prioritize rest or light movement today."
        } else {
            return "Connect Health to see personalized insights based on your data."
        }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: greeting = "Good Morning"
        case 12..<17: greeting = "Good Afternoon"
        case 17..<22: greeting = "Good Evening"
        default: greeting = "Good Night"
        }
    }
}
