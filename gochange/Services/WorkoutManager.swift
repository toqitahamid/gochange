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
    let duration: TimeInterval?
    let weightUnit: SetLog.WeightUnit
}

// MARK: - Rest Timer State
struct RestTimerState {
    let endTime: Date
    let setContext: String
    let exerciseName: String

    var remainingTime: TimeInterval {
        endTime.timeIntervalSinceNow
    }

    var isExpired: Bool {
        remainingTime <= 0
    }
}

// MARK: - Set Timer State
struct SetTimerState {
    let startTime: Date
    let exerciseName: String
    let exerciseIndex: Int
    let setIndex: Int
    let setNumber: Int
    let setType: SetLog.SetType
    var isPaused: Bool = false
    var pauseStartTime: Date? = nil
    var totalPausedDuration: TimeInterval = 0
    
    var elapsedTime: TimeInterval {
        let rawElapsed = Date().timeIntervalSince(startTime)
        return isPaused ? (pauseStartTime?.timeIntervalSince(startTime) ?? rawElapsed) - totalPausedDuration : rawElapsed - totalPausedDuration
    }
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
    @Published var isPaused = false
    @Published var showingRestTimer = false
    @Published var currentWorkoutDay: WorkoutDay?
    @Published var sessionNotes: String = ""
    @Published var showingSessionNotes = false
    @Published var currentHeartRate: Double?

    // Workout summary
    @Published var showingSummary = false
    @Published var workoutSummary: WorkoutSummaryData?
    @Published var summaryAccentColor: Color = .blue
    
    // Pause tracking
    private var pausedTime: Date?
    private var totalPausedDuration: TimeInterval = 0
    
    // Previous workout data for reference
    @Published var previousSetData: [UUID: [PreviousSetInfo]] = [:]  // exerciseId -> sets

    // Auto rest timer
    @Published var activeRestTimer: RestTimerState? = nil

    // Set timer
    @Published var activeSetTimer: SetTimerState? = nil

    // Progressive overload suggestions
    @Published var suggestions: [UUID: OverloadSuggestion] = [:] // exerciseId -> suggestion

    // MARK: - Dependencies
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var restTimerCancellable: AnyCancellable?
    
    init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: .watchHeartRateUpdate)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                if let heartRate = notification.userInfo?["heartRate"] as? Double {
                    self?.currentHeartRate = heartRate
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: .watchWorkoutEnded)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.currentHeartRate = nil
            }
            .store(in: &cancellables)
    }
    
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

        // Calculate progressive overload suggestions
        calculateSuggestions()

        // Start Live Activity
        startWorkoutLiveActivity(workoutDay: workoutDay)
    }

    private func calculateSuggestions() {
        suggestions = ProgressiveOverloadService.shared.calculateSuggestions(
            for: exerciseLogs,
            previousData: previousSetData
        )
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
                        duration: setLog.duration,
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
    
    func pause() {
        guard !isPaused else { return }
        isPaused = true
        pausedTime = Date()
        
        // Also pause the set timer if active
        if activeSetTimer != nil {
            pauseSetTimer()
        }
    }
    
    func resumeWorkout() {
        guard isPaused, let pausedTime = pausedTime else { return }
        totalPausedDuration += Date().timeIntervalSince(pausedTime)
        isPaused = false
        self.pausedTime = nil
        
        // Also resume the set timer if it was paused
        if activeSetTimer != nil {
            resumeSetTimer()
        }
    }
    
    func togglePause() {
        if isPaused {
            resumeWorkout()
        } else {
            pause()
        }
    }
    
    func cancel() {
        endWorkoutActivity()
        resetState()
    }
    
    func complete(rpe: Double? = nil) {
        guard let session = currentSession, let startTime = startTime, let context = modelContext else { return }

        // End Live Activity
        endWorkoutActivity()

        // Update session details
        let endTime = Date()
        session.endTime = endTime
        session.duration = endTime.timeIntervalSince(startTime)
        session.isCompleted = true
        session.notes = sessionNotes.isEmpty ? nil : sessionNotes
        session.rpe = rpe

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

        // Build summary data before resetting
        buildAndShowSummary(
            workoutName: workoutName,
            date: session.date,
            duration: duration,
            rpe: rpe,
            context: context
        )
    }

    private func buildAndShowSummary(workoutName: String, date: Date, duration: TimeInterval, rpe: Double?, context: ModelContext) {
        // Get previous session for comparison
        let previousSession = fetchPreviousSession(workoutDayName: workoutName, context: context)

        // Build exercise summaries
        let exerciseSummaries: [WorkoutSummaryData.ExerciseSummary] = exerciseLogs.map { log in
            let completedSets = log.sets.filter { $0.isCompleted }
            let totalVolume = completedSets.reduce(0.0) { total, set in
                if let weight = set.weight, let reps = set.actualReps {
                    return total + (weight * Double(reps))
                }
                return total
            }

            // Find best set (highest volume)
            let bestSet = completedSets.max { a, b in
                let volA = (a.weight ?? 0) * Double(a.actualReps ?? 0)
                let volB = (b.weight ?? 0) * Double(b.actualReps ?? 0)
                return volA < volB
            }

            // Check for PR (compare to previous best)
            let isPR = checkForPR(exerciseId: log.exerciseId, currentBestWeight: bestSet?.weight, currentBestReps: bestSet?.actualReps, context: context)

            return WorkoutSummaryData.ExerciseSummary(
                name: log.exerciseName,
                muscleGroup: currentWorkoutDay?.exercises.first { $0.id == log.exerciseId }?.muscleGroup ?? "—",
                completedSets: completedSets.count,
                totalSets: log.sets.count,
                totalVolume: totalVolume,
                topWeight: bestSet?.weight,
                topReps: bestSet?.actualReps,
                isPR: isPR
            )
        }

        // Build previous session data for comparison
        var previousData: WorkoutSummaryData.PreviousSessionData? = nil
        if let prev = previousSession {
            let prevVolume = prev.exerciseLogs.reduce(0.0) { total, log in
                total + log.sets.filter { $0.isCompleted }.reduce(0.0) { setTotal, set in
                    if let weight = set.weight, let reps = set.actualReps {
                        return setTotal + (weight * Double(reps))
                    }
                    return setTotal
                }
            }
            let prevSets = prev.exerciseLogs.reduce(0) { $0 + $1.sets.filter { $0.isCompleted }.count }

            previousData = WorkoutSummaryData.PreviousSessionData(
                duration: prev.duration ?? 0,
                totalVolume: prevVolume,
                totalSets: prevSets
            )
        }

        // Store accent color before reset
        if let workoutDay = currentWorkoutDay {
            summaryAccentColor = Color(hex: workoutDay.colorHex)
        }

        // Create summary
        workoutSummary = WorkoutSummaryData(
            workoutName: workoutName,
            date: date,
            duration: duration,
            rpe: rpe,
            exercises: exerciseSummaries,
            previousSession: previousData
        )

        // Show summary (don't reset state yet)
        showingSummary = true
    }

    private func fetchPreviousSession(workoutDayName: String, context: ModelContext) -> WorkoutSession? {
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.isCompleted && session.workoutDayName == workoutDayName
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            let sessions = try context.fetch(descriptor)
            // Return the second most recent (since current one is now saved)
            return sessions.count > 1 ? sessions[1] : nil
        } catch {
            return nil
        }
    }

    private func checkForPR(exerciseId: UUID, currentBestWeight: Double?, currentBestReps: Int?, context: ModelContext) -> Bool {
        guard let weight = currentBestWeight, let reps = currentBestReps else { return false }

        // Fetch all previous logs for this exercise
        let descriptor = FetchDescriptor<ExerciseLog>(
            predicate: #Predicate { log in
                log.exerciseId == exerciseId
            }
        )

        do {
            let logs = try context.fetch(descriptor)
            // Find previous best volume (weight × reps)
            let currentVolume = weight * Double(reps)
            let previousBest = logs.flatMap { $0.sets }
                .filter { $0.isCompleted }
                .compactMap { set -> Double? in
                    guard let w = set.weight, let r = set.actualReps else { return nil }
                    return w * Double(r)
                }
                .max() ?? 0

            // It's a PR if current is higher than all previous
            return currentVolume > previousBest
        } catch {
            return false
        }
    }

    func dismissSummary() {
        showingSummary = false
        workoutSummary = nil
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
        isPaused = false
        pausedTime = nil
        totalPausedDuration = 0
        showingRestTimer = false
        sessionNotes = ""
        showingSessionNotes = false
        previousSetData = [:]
        activeSetTimer = nil
        activeRestTimer = nil
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
                if let defaultWeight = exercise.defaultWeight {
                    setLog.weight = defaultWeight
                }
                
                // Pre-fill actual reps if target is a simple number
                if let reps = Int(exercise.defaultReps) {
                    setLog.actualReps = reps
                }
                
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
        
        // Check if we are removing the currently active set
        if let timer = activeSetTimer, timer.exerciseIndex == exerciseIndex {
            if timer.setIndex == setIndex {
                // We are removing the active set - stop the timer
                activeSetTimer = nil
            } else if timer.setIndex > setIndex {
                // We are removing a set before the active one - shift the index down
                activeSetTimer = SetTimerState(
                    startTime: timer.startTime,
                    exerciseName: timer.exerciseName,
                    exerciseIndex: timer.exerciseIndex,
                    setIndex: timer.setIndex - 1,
                    setNumber: timer.setNumber - 1, // Assuming set numbers are sequential
                    setType: timer.setType,
                    isPaused: timer.isPaused,
                    pauseStartTime: timer.pauseStartTime,
                    totalPausedDuration: timer.totalPausedDuration
                )
            }
        }
        
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

        let wasCompleted = exerciseLogs[exerciseIndex].sets[setIndex].isCompleted
        exerciseLogs[exerciseIndex].sets[setIndex].isCompleted.toggle()
        updateWorkoutLiveActivity()

        // Auto-start rest timer when marking set as complete
        if !wasCompleted {
            startAutoRestTimer(exerciseIndex: exerciseIndex, setIndex: setIndex)
        } else {
            // If unchecking, stop the timer
            stopRestTimer()
        }
    }

    // MARK: - Auto Rest Timer

    private func startAutoRestTimer(exerciseIndex: Int, setIndex: Int) {
        let exerciseLog = exerciseLogs[exerciseIndex]
        let isLastSet = setIndex == exerciseLog.sets.count - 1

        // Use longer rest for last set, shorter for others
        let duration: TimeInterval = isLastSet ? 180 : 90

        let endTime = Date().addingTimeInterval(duration)
        activeRestTimer = RestTimerState(
            endTime: endTime,
            setContext: "Set \(setIndex + 1)",
            exerciseName: exerciseLog.exerciseName
        )

        // Update unified Live Activity with rest timer state
        WorkoutActivityManager.shared.startRestTimer(
            endTime: endTime,
            totalDuration: duration,
            afterSetNumber: setIndex + 1,
            exerciseName: exerciseLog.exerciseName
        )
        NotificationService.shared.scheduleRestTimerNotification(endTime: endTime)

        // Auto-dismiss timer when it expires
        restTimerCancellable?.cancel()
        restTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let timer = self.activeRestTimer, timer.isExpired {
                    self.stopRestTimer()
                }
            }
    }

    // MARK: - Set Timer Management
    
    func startSetTimer(exerciseIndex: Int, setIndex: Int) {
        guard exerciseIndex < exerciseLogs.count,
              setIndex < exerciseLogs[exerciseIndex].sets.count else { return }
        
        let exerciseLog = exerciseLogs[exerciseIndex]
        let setLog = exerciseLog.sets[setIndex]
        
        activeSetTimer = SetTimerState(
            startTime: Date(),
            exerciseName: exerciseLog.exerciseName,
            exerciseIndex: exerciseIndex,
            setIndex: setIndex,
            setNumber: setLog.setNumber,
            setType: setLog.setType
        )
    }
    
    func pauseSetTimer() {
        guard var timer = activeSetTimer, !timer.isPaused else { return }
        timer.isPaused = true
        timer.pauseStartTime = Date()
        activeSetTimer = timer
    }
    
    func resumeSetTimer() {
        guard var timer = activeSetTimer, timer.isPaused else { return }
        if let pauseStart = timer.pauseStartTime {
            timer.totalPausedDuration += Date().timeIntervalSince(pauseStart)
        }
        timer.isPaused = false
        timer.pauseStartTime = nil
        activeSetTimer = timer
    }
    
    func stopSetTimer() {
        guard let timer = activeSetTimer else { return }
        
        // Complete the set
        exerciseLogs[timer.exerciseIndex].sets[timer.setIndex].isCompleted = true
        updateWorkoutLiveActivity()
        
        // Stop the set timer
        activeSetTimer = nil
        
        // Start rest timer for 180 seconds
        let duration: TimeInterval = 180
        let endTime = Date().addingTimeInterval(duration)
        activeRestTimer = RestTimerState(
            endTime: endTime,
            setContext: "Set \(timer.setNumber)",
            exerciseName: timer.exerciseName
        )
        
        // Update unified Live Activity with rest timer state
        WorkoutActivityManager.shared.startRestTimer(
            endTime: endTime,
            totalDuration: duration,
            afterSetNumber: timer.setNumber,
            exerciseName: timer.exerciseName
        )
        NotificationService.shared.scheduleRestTimerNotification(endTime: endTime)
        
        // Auto-dismiss timer when it expires
        restTimerCancellable?.cancel()
        restTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if let timer = self.activeRestTimer, timer.isExpired {
                    self.stopRestTimer()
                }
            }
    }

    func stopRestTimer() {
        activeRestTimer = nil
        restTimerCancellable?.cancel()
        restTimerCancellable = nil
        WorkoutActivityManager.shared.stopRestTimer()
        NotificationService.shared.cancelRestTimerNotification()
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
