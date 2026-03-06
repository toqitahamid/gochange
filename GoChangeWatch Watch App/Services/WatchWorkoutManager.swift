import SwiftUI
import HealthKit
import Combine

@MainActor
class WatchWorkoutManager: ObservableObject {
    // MARK: - Published State

    @Published var isWorkoutActive = false
    @Published var workoutDayName = ""
    @Published var workoutColorHex = "#00D4AA"

    @Published var currentExerciseIndex = 0
    @Published var currentSetIndex = 0
    @Published var completedSets = 0
    @Published var totalExercises = 0

    @Published var currentWeight: Double = 0
    @Published var currentReps: Int = 8
    @Published var weightUnit = "lbs"

    @Published var elapsedTime: TimeInterval = 0

    // MARK: - Private State

    @Published var isPaused = false

    private var workoutDay: WatchWorkoutDay?
    private var exerciseLogs: [[WatchSetLog]] = []
    private var startTime: Date?
    private var timer: Timer?

    private let healthKit = WatchHealthKitService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var currentHeartRate: Double? { healthKit.currentHeartRate }
    
    var currentExercise: WatchExercise? {
        guard let workoutDay = workoutDay,
              currentExerciseIndex < workoutDay.exercises.count else {
            return nil
        }
        return workoutDay.exercises[currentExerciseIndex]
    }
    
    var elapsedTimeString: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Persistence Keys
    private enum PersistenceKey {
        static let state = "watchWorkoutState"
    }

    // MARK: - Initialization

    init() {
        restoreStateIfNeeded()
    }

    // MARK: - State Persistence

    private func saveState() {
        guard let workoutDay, let startTime else {
            UserDefaults.standard.removeObject(forKey: PersistenceKey.state)
            return
        }
        let state = WatchWorkoutState(
            workoutDay: workoutDay,
            exerciseLogs: exerciseLogs,
            startTime: startTime,
            currentExerciseIndex: currentExerciseIndex,
            currentSetIndex: currentSetIndex,
            completedSets: completedSets
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: PersistenceKey.state)
        }
    }

    private func restoreStateIfNeeded() {
        guard
            let data = UserDefaults.standard.data(forKey: PersistenceKey.state),
            let state = try? JSONDecoder().decode(WatchWorkoutState.self, from: data)
        else { return }

        workoutDay = state.workoutDay
        workoutDayName = state.workoutDay.name
        workoutColorHex = state.workoutDay.colorHex
        totalExercises = state.workoutDay.exercises.count
        exerciseLogs = state.exerciseLogs
        startTime = state.startTime
        currentExerciseIndex = state.currentExerciseIndex
        currentSetIndex = state.currentSetIndex
        completedSets = state.completedSets
        elapsedTime = Date().timeIntervalSince(state.startTime)
        isWorkoutActive = true
        startTimer()
    }
    
    // MARK: - Workout Lifecycle
    
    func startWorkout(workoutDay: WatchWorkoutDay) {
        self.workoutDay = workoutDay
        self.workoutDayName = workoutDay.name
        self.workoutColorHex = workoutDay.colorHex
        self.totalExercises = workoutDay.exercises.count
        self.currentExerciseIndex = 0
        self.currentSetIndex = 0
        self.completedSets = 0
        self.startTime = Date()
        self.elapsedTime = 0
        
        // Initialize exercise logs
        exerciseLogs = workoutDay.exercises.map { exercise in
            (0..<exercise.defaultSets).map { setNum in
                WatchSetLog(
                    setNumber: setNum + 1,
                    targetReps: exercise.defaultReps
                )
            }
        }
        
        // Load previous weight for first exercise
        loadPreviousWeight()
        
        // Start timer
        startTimer()
        
        // Start HealthKit workout session via shared service
        Task { try? await healthKit.startWorkoutSession() }
        
        isWorkoutActive = true
        saveState()

        // Notify iPhone
        WatchConnectivityManager.shared.sendMessage([
            "type": "workoutStarted",
            "date": Date()
        ])
    }
    
    func endWorkout() {
        timer?.invalidate()
        timer = nil
        
        // End HealthKit session via shared service
        Task { try? await healthKit.endWorkoutSession() }
        
        // Send completed workout to iPhone
        sendCompletedWorkout()
        
        // Notify iPhone of end
        WatchConnectivityManager.shared.sendMessage([
            "type": "workoutEnded",
            "date": Date()
        ])
        
        // Reset state
        isWorkoutActive = false
        isPaused = false
        workoutDay = nil
        exerciseLogs = []
        currentExerciseIndex = 0
        currentSetIndex = 0
        completedSets = 0
        saveState() // clears persisted state
    }
    
    func pauseWorkout() {
        guard isWorkoutActive && !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
        
        // Pause HealthKit session
        WatchHealthKitService.shared.pauseWorkout()
    }
    
    func resumeWorkout() {
        guard isWorkoutActive && isPaused else { return }
        isPaused = false
        startTimer()
        
        // Resume HealthKit session
        WatchHealthKitService.shared.resumeWorkout()
    }
    
    // MARK: - Set Management
    
    func completeSet() {
        guard currentExerciseIndex < exerciseLogs.count,
              currentSetIndex < exerciseLogs[currentExerciseIndex].count else {
            return
        }
        
        // Save current set
        exerciseLogs[currentExerciseIndex][currentSetIndex].weight = currentWeight
        exerciseLogs[currentExerciseIndex][currentSetIndex].actualReps = currentReps
        exerciseLogs[currentExerciseIndex][currentSetIndex].isCompleted = true
        exerciseLogs[currentExerciseIndex][currentSetIndex].weightUnit = weightUnit
        
        completedSets += 1
        saveState()

        // Haptic feedback
        WKInterfaceDevice.current().play(.success)
        
        // Move to next set or exercise
        if currentSetIndex + 1 < exerciseLogs[currentExerciseIndex].count {
            currentSetIndex += 1
        } else {
            // Move to next exercise
            moveToNextExercise()
        }
    }
    
    func skipExercise() {
        moveToNextExercise()
    }
    
    func previousExercise() {
        guard currentExerciseIndex > 0 else { return }
        currentExerciseIndex -= 1
        currentSetIndex = 0
        loadPreviousWeight()
    }
    
    private func moveToNextExercise() {
        if currentExerciseIndex + 1 < totalExercises {
            currentExerciseIndex += 1
            currentSetIndex = 0
            loadPreviousWeight()
        }
        // If we're on the last exercise, just stay there
    }
    
    private func loadPreviousWeight() {
        // Extract first number from reps string (e.g., "8-12" -> 8, "12" -> 12)
        if let repsString = currentExercise?.defaultReps,
           let firstNum = repsString.components(separatedBy: CharacterSet.decimalDigits.inverted)
               .first(where: { !$0.isEmpty }),
           let reps = Int(firstNum) {
            currentReps = reps
        } else {
            currentReps = 8
        }
        
        // Try to get previous weight for this exercise
        // For now, default to 0 - could be enhanced with UserDefaults storage
        currentWeight = 0
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                guard let self = self, let startTime = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    // MARK: - Send to iPhone
    
    private func sendCompletedWorkout() {
        guard let workoutDay = workoutDay,
              let startTime = startTime else { return }
        
        let endTime = Date()
        
        var logs: [[String: Any]] = []
        for (exerciseIndex, exercise) in workoutDay.exercises.enumerated() {
            var sets: [[String: Any]] = []
            for setLog in exerciseLogs[exerciseIndex] where setLog.isCompleted {
                sets.append([
                    "setNumber": setLog.setNumber,
                    "targetReps": setLog.targetReps,
                    "actualReps": setLog.actualReps ?? 0,
                    "weight": setLog.weight ?? 0,
                    "weightUnit": setLog.weightUnit,
                    "isCompleted": setLog.isCompleted
                ])
            }
            
            if !sets.isEmpty {
                logs.append([
                    "exerciseId": exercise.id.uuidString,
                    "exerciseName": exercise.name,
                    "order": exerciseIndex,
                    "sets": sets
                ])
            }
        }
        
        let workoutData: [String: Any] = [
            "type": "completedWorkout",
            "workout": [
                "workoutDayId": workoutDay.id.uuidString,
                "workoutDayName": workoutDay.name,
                "startTime": startTime.timeIntervalSince1970,
                "endTime": endTime.timeIntervalSince1970,
                "duration": endTime.timeIntervalSince(startTime),
                "exerciseLogs": logs,
                "averageHeartRate": healthKit.averageHeartRate ?? 0,
                "activeCalories": healthKit.activeCalories
            ]
        ]
        
        WatchConnectivityManager.shared.sendMessage(workoutData)
    }
}


// MARK: - Watch Models

struct WatchSetLog: Codable {
    let setNumber: Int
    let targetReps: String
    var actualReps: Int?
    var weight: Double?
    var weightUnit: String = "lbs"
    var isCompleted: Bool = false
}

struct WatchWorkoutState: Codable {
    let workoutDay: WatchWorkoutDay
    let exerciseLogs: [[WatchSetLog]]
    let startTime: Date
    let currentExerciseIndex: Int
    let currentSetIndex: Int
    let completedSets: Int
}

