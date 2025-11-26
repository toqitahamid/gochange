import SwiftUI
import SwiftData
import Combine
import WidgetKit
import HealthKit

// MARK: - Previous Set Info
struct PreviousSetInfo {
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let weightUnit: SetLog.WeightUnit
}

// MARK: - Widget Data Model (shared with widget)
struct WidgetWorkoutData: Codable {
    let workoutsThisWeek: Int
    let totalWorkoutDays: Int
    let currentStreak: Int
    let nextWorkoutName: String?
    let lastUpdated: Date
    
    static let placeholder = WidgetWorkoutData(
        workoutsThisWeek: 2,
        totalWorkoutDays: 4,
        currentStreak: 3,
        nextWorkoutName: "Push",
        lastUpdated: Date()
    )
}

// MARK: - Widget Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.toqitahamid.gochange") ?? UserDefaults.standard
    private let dataKey = "widgetWorkoutData"
    
    func saveData(_ data: WidgetWorkoutData) {
        if let encoded = try? JSONEncoder().encode(data) {
            userDefaults.set(encoded, forKey: dataKey)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func loadData() -> WidgetWorkoutData {
        guard let data = userDefaults.data(forKey: dataKey),
              let decoded = try? JSONDecoder().decode(WidgetWorkoutData.self, from: data) else {
            return WidgetWorkoutData.placeholder
        }
        return decoded
    }
}

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
    @Published var sessionNotes: String = ""
    @Published var showingSessionNotes = false
    
    // Previous workout data for reference
    @Published var previousSetData: [UUID: [PreviousSetInfo]] = [:]  // exerciseId -> sets
    
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
        
        // Fetch previous workout data for reference
        fetchPreviousWorkoutData(for: workoutDay)
        
        // Setup logs
        setupExerciseLogs(for: workoutDay)
        
        // Start Live Activity
        startWorkoutLiveActivity(workoutDay: workoutDay)
    }
    
    private func fetchPreviousWorkoutData(for workoutDay: WorkoutDay) {
        guard let context = modelContext else { return }
        
        // Capture the UUID value for the predicate
        let workoutDayId = workoutDay.id
        
        // Fetch completed sessions for this workout day
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate<WorkoutSession> { session in
                session.workoutDayId == workoutDayId && session.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let sessions = try? context.fetch(descriptor),
              let lastSession = sessions.first else {
            previousSetData = [:]
            return
        }
        
        // Build previous set data dictionary
        var data: [UUID: [PreviousSetInfo]] = [:]
        for exerciseLog in lastSession.exerciseLogs {
            let sets = exerciseLog.sets
                .filter { $0.isCompleted }
                .sorted { $0.setNumber < $1.setNumber }
                .map { setLog in
                    PreviousSetInfo(
                        setNumber: setLog.setNumber,
                        weight: setLog.weight,
                        reps: setLog.actualReps,
                        weightUnit: setLog.weightUnit
                    )
                }
            data[exerciseLog.exerciseId] = sets
        }
        previousSetData = data
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
        let endTime = Date()
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        session.isCompleted = true
        session.notes = sessionNotes.isEmpty ? nil : sessionNotes
        
        // Attach logs
        for log in exerciseLogs {
            session.exerciseLogs.append(log)
        }
        
        // Save to database
        context.insert(session)
        try? context.save()
        
        // Update widget data
        updateWidgetData(context: context)
        
        // Save to HealthKit if enabled
        let workoutName = session.workoutDayName
        let duration = session.duration ?? endTime.timeIntervalSince(startTime)
        saveToHealthKitIfEnabled(workoutName: workoutName, startTime: startTime, endTime: endTime, duration: duration)
        
        resetState()
    }
    
    // MARK: - HealthKit Integration
    
    private func saveToHealthKitIfEnabled(workoutName: String, startTime: Date, endTime: Date, duration: TimeInterval) {
        // Check if HealthKit is enabled in settings
        let healthKitEnabled = UserDefaults.standard.bool(forKey: "healthKitEnabled")
        guard healthKitEnabled else { return }
        
        // Calculate total volume for metadata
        let totalVolume = exerciseLogs.reduce(0.0) { total, log in
            total + log.sets.reduce(0.0) { setTotal, set in
                if set.isCompleted, let weight = set.weight, let reps = set.actualReps {
                    return setTotal + (weight * Double(reps))
                }
                return setTotal
            }
        }
        
        Task {
            do {
                try await HealthKitService.shared.saveWorkout(
                    workoutName: workoutName,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    totalVolume: totalVolume
                )
            } catch {
                print("Failed to save workout to HealthKit: \(error)")
            }
        }
    }
    
    private func updateWidgetData(context: ModelContext) {
        // Fetch all completed sessions
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.isCompleted
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        guard let sessions = try? context.fetch(descriptor) else { return }
        
        // Calculate this week's workouts
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        let workoutsThisWeek = sessions.filter { $0.date >= startOfWeek }.count
        
        // Get total workout days from workout days
        let workoutDaysDescriptor = FetchDescriptor<WorkoutDay>()
        let totalWorkoutDays = (try? context.fetch(workoutDaysDescriptor).count) ?? 4
        
        // Calculate streak (weeks with at least one workout)
        var streak = 0
        var checkDate = Date()
        while true {
            let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: checkDate)) ?? checkDate
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? checkDate
            
            let hasWorkoutInWeek = sessions.contains { $0.date >= weekStart && $0.date < weekEnd }
            if hasWorkoutInWeek || calendar.isDate(checkDate, equalTo: Date(), toGranularity: .weekOfYear) {
                if hasWorkoutInWeek {
                    streak += 1
                }
                checkDate = calendar.date(byAdding: .day, value: -7, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        
        // Get next suggested workout
        let workoutDays = (try? context.fetch(workoutDaysDescriptor)) ?? []
        let nextWorkoutName = workoutDays.first?.name
        
        // Save widget data
        let widgetData = WidgetWorkoutData(
            workoutsThisWeek: workoutsThisWeek,
            totalWorkoutDays: totalWorkoutDays,
            currentStreak: streak,
            nextWorkoutName: nextWorkoutName,
            lastUpdated: Date()
        )
        
        WidgetDataManager.shared.saveData(widgetData)
    }
    
    private func resetState() {
        currentSession = nil
        currentWorkoutDay = nil
        exerciseLogs = []
        startTime = nil
        isWorkoutActive = false
        isMinimized = false
        showingRestTimer = false
        sessionNotes = ""
        showingSessionNotes = false
        previousSetData = [:]
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
