import SwiftUI
import SwiftData
import Combine

/// Main view model for workout operations
@MainActor
class WorkoutViewModel: ObservableObject {
    private let modelContext: ModelContext
    
    @Published var workoutDays: [WorkoutDay] = []
    @Published var sessions: [WorkoutSession] = []
    @Published var isLoading = false
    @Published var error: String?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        do {
            let dayDescriptor = FetchDescriptor<WorkoutDay>(sortBy: [SortDescriptor(\.dayNumber)])
            workoutDays = try modelContext.fetch(dayDescriptor)
            
            let sessionDescriptor = FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            sessions = try modelContext.fetch(sessionDescriptor)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Workout Day Operations
    
    func addExercise(to workoutDay: WorkoutDay, name: String, sets: Int, reps: String, muscleGroup: String) {
        let exercise = Exercise(name: name, defaultSets: sets, defaultReps: reps, muscleGroup: muscleGroup)
        workoutDay.exercises.append(exercise)
        saveContext()
    }
    
    func removeExercise(_ exercise: Exercise, from workoutDay: WorkoutDay) {
        workoutDay.exercises.removeAll { $0.id == exercise.id }
        modelContext.delete(exercise)
        saveContext()
    }
    
    func reorderExercises(in workoutDay: WorkoutDay, from source: IndexSet, to destination: Int) {
        workoutDay.exercises.move(fromOffsets: source, toOffset: destination)
        saveContext()
    }
    
    // MARK: - Session Operations
    
    func startSession(for workoutDay: WorkoutDay) -> WorkoutSession {
        let session = WorkoutSession(
            date: Date(),
            workoutDayId: workoutDay.id,
            workoutDayName: workoutDay.name
        )
        
        // Pre-populate exercise logs
        for (index, exercise) in workoutDay.exercises.enumerated() {
            let log = ExerciseLog(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                order: index
            )
            
            for setNum in 1...exercise.defaultSets {
                let setLog = SetLog(setNumber: setNum, targetReps: exercise.defaultReps)
                log.sets.append(setLog)
            }
            
            session.exerciseLogs.append(log)
        }
        
        modelContext.insert(session)
        sessions.insert(session, at: 0)
        
        return session
    }
    
    func completeSession(_ session: WorkoutSession) {
        session.endTime = Date()
        session.duration = session.endTime?.timeIntervalSince(session.startTime)
        session.isCompleted = true
        saveContext()
    }
    
    func deleteSession(_ session: WorkoutSession) {
        sessions.removeAll { $0.id == session.id }
        modelContext.delete(session)
        saveContext()
    }
    
    // MARK: - Statistics
    
    var completedSessionsThisWeek: Int {
        let startOfWeek = Date().startOfWeek
        return sessions.filter { session in
            session.isCompleted && session.date >= startOfWeek
        }.count
    }
    
    var totalVolume: Double {
        sessions.filter { $0.isCompleted }.reduce(0) { total, session in
            total + session.exerciseLogs.reduce(0) { logTotal, log in
                logTotal + log.sets.filter { $0.isCompleted }.reduce(0) { setTotal, set in
                    if let weight = set.weight, let reps = set.actualReps {
                        return setTotal + (weight * Double(reps))
                    }
                    return setTotal
                }
            }
        }
    }
    
    var averageWorkoutDuration: TimeInterval {
        let completedSessions = sessions.filter { $0.isCompleted && $0.duration != nil }
        guard !completedSessions.isEmpty else { return 0 }
        
        let totalDuration = completedSessions.reduce(0) { $0 + ($1.duration ?? 0) }
        return totalDuration / Double(completedSessions.count)
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func suggestedNextWorkout() -> WorkoutDay? {
        SchedulingService.suggestNextWorkout(sessions: sessions, workoutDays: workoutDays)
    }
}

