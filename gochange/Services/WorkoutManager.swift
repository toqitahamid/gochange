import SwiftUI
import SwiftData
import Combine

@MainActor
class WorkoutManager: ObservableObject {
    // MARK: - Published State
    @Published var currentSession: WorkoutSession?
    @Published var exerciseLogs: [ExerciseLog] = []
    @Published var startTime: Date?
    @Published var isWorkoutActive = false
    @Published var isMinimized = false
    @Published var showingRestTimer = false
    @Published var currentWorkoutDay: WorkoutDay?
    
    // MARK: - Dependencies
    private var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    var completedSetsCount: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }
    }
    
    var totalSetsCount: Int {
        exerciseLogs.reduce(0) { $0 + $1.sets.count }
    }
    
    var canComplete: Bool {
        exerciseLogs.contains { log in
            log.sets.contains { $0.isCompleted }
        }
    }
    
    // MARK: - Setup
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Workout Management
    func start(workoutDay: WorkoutDay) {
        // Create new session
        let session = WorkoutSession(
            date: Date(),
            workoutDayId: workoutDay.id,
            workoutDayName: workoutDay.name
        )
        
        self.currentSession = session
        self.currentWorkoutDay = workoutDay
        self.startTime = Date()
        self.isWorkoutActive = true
        self.isMinimized = false
        
        // Setup logs
        setupExerciseLogs(for: workoutDay)
        
        // Start Live Activity
        startWorkoutLiveActivity(workoutDay: workoutDay)
    }
    
    func minimize() {
        isMinimized = true
    }
    
    func resume() {
        isMinimized = false
    }
    
    func cancel() {
        endWorkoutActivity()
        resetState()
    }
    
    func complete() {
        guard let session = currentSession, let startTime = startTime, let context = modelContext else { return }
        
        // End Live Activity
        endWorkoutActivity()
        
        // Update session details
        session.endTime = Date()
        session.duration = session.endTime?.timeIntervalSince(startTime)
        session.isCompleted = true
        
        // Attach logs
        for log in exerciseLogs {
            session.exerciseLogs.append(log)
        }
        
        // Save to database
        context.insert(session)
        try? context.save()
        
        resetState()
    }
    
    private func resetState() {
        currentSession = nil
        currentWorkoutDay = nil
        exerciseLogs = []
        startTime = nil
        isWorkoutActive = false
        isMinimized = false
        showingRestTimer = false
    }
    
    // MARK: - Exercise Management
    private func setupExerciseLogs(for workoutDay: WorkoutDay) {
        // Get weight unit preference
        @AppStorage("weightUnit") var weightUnit: String = "lbs"
        let unit: SetLog.WeightUnit = weightUnit == "kg" ? .kg : .lbs
        
        exerciseLogs = workoutDay.exercises.enumerated().map { index, exercise in
            let log = ExerciseLog(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                order: index
            )
            
            for setNum in 1...exercise.defaultSets {
                let setLog = SetLog(
                    setNumber: setNum,
                    targetReps: exercise.defaultReps,
                    weightUnit: unit
                )
                log.sets.append(setLog)
            }
            
            return log
        }
    }
    
    func addSet(to exerciseIndex: Int, defaultReps: String) {
        guard exerciseIndex < exerciseLogs.count else { return }
        
        @AppStorage("weightUnit") var weightUnit: String = "lbs"
        let unit: SetLog.WeightUnit = weightUnit == "kg" ? .kg : .lbs
        
        let newSetNumber = exerciseLogs[exerciseIndex].sets.count + 1
        let newSet = SetLog(
            setNumber: newSetNumber,
            targetReps: defaultReps,
            weightUnit: unit
        )
        exerciseLogs[exerciseIndex].sets.append(newSet)
        
        updateWorkoutLiveActivity()
    }
    
    func removeSet(at setIndex: Int, from exerciseIndex: Int) {
        guard exerciseIndex < exerciseLogs.count,
              setIndex < exerciseLogs[exerciseIndex].sets.count,
              exerciseLogs[exerciseIndex].sets.count > 1 else { return }
        
        exerciseLogs[exerciseIndex].sets.remove(at: setIndex)
        
        // Renumber remaining sets
        for (index, _) in exerciseLogs[exerciseIndex].sets.enumerated() {
            exerciseLogs[exerciseIndex].sets[index].setNumber = index + 1
        }
        
        updateWorkoutLiveActivity()
    }
    
    func toggleSetCompletion(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < exerciseLogs.count,
              setIndex < exerciseLogs[exerciseIndex].sets.count else { return }
        
        exerciseLogs[exerciseIndex].sets[setIndex].isCompleted.toggle()
        updateWorkoutLiveActivity()
    }
    
    // MARK: - Live Activity
    private func startWorkoutLiveActivity(workoutDay: WorkoutDay) {
        WorkoutActivityManager.shared.start(
            workoutName: workoutDay.name,
            workoutColor: workoutDay.colorHex,
            exerciseCount: workoutDay.exercises.count,
            totalSets: totalSetsCount
        )
    }
    
    private func updateWorkoutLiveActivity() {
        WorkoutActivityManager.shared.update(
            completedSets: completedSetsCount,
            totalSets: totalSetsCount,
            exerciseCount: exerciseLogs.count
        )
    }
    
    private func endWorkoutActivity() {
        WorkoutActivityManager.shared.end()
    }
}
