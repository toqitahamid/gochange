import Foundation
import SwiftData

/// Service for data export/import and backup operations
class DataExportService {
    
    // MARK: - Export Data
    
    struct ExportData: Codable {
        let exportDate: Date
        let version: String
        let workoutDays: [WorkoutDayExport]
        let sessions: [SessionExport]
    }
    
    struct WorkoutDayExport: Codable {
        let id: UUID
        let name: String
        let dayNumber: Int
        let colorHex: String
        let exercises: [ExerciseExport]
    }
    
    struct ExerciseExport: Codable {
        let id: UUID
        let name: String
        let defaultSets: Int
        let defaultReps: String
        let muscleGroup: String
        let notes: String?
    }
    
    struct SessionExport: Codable {
        let id: UUID
        let date: Date
        let workoutDayId: UUID
        let workoutDayName: String
        let startTime: Date
        let endTime: Date?
        let duration: TimeInterval?
        let notes: String?
        let isCompleted: Bool
        let exerciseLogs: [ExerciseLogExport]
    }
    
    struct ExerciseLogExport: Codable {
        let id: UUID
        let exerciseId: UUID
        let exerciseName: String
        let order: Int
        let notes: String?
        let sets: [SetLogExport]
    }
    
    struct SetLogExport: Codable {
        let id: UUID
        let setNumber: Int
        let targetReps: String
        let actualReps: Int?
        let weight: Double?
        let weightUnit: String
        let rir: Int?
        let isCompleted: Bool
        let notes: String?
    }
    
    /// Exports all data to JSON
    func exportData(workoutDays: [WorkoutDay], sessions: [WorkoutSession]) -> Data? {
        let exportData = ExportData(
            exportDate: Date(),
            version: "1.0",
            workoutDays: workoutDays.map { day in
                WorkoutDayExport(
                    id: day.id,
                    name: day.name,
                    dayNumber: day.dayNumber,
                    colorHex: day.colorHex,
                    exercises: day.exercises.map { exercise in
                        ExerciseExport(
                            id: exercise.id,
                            name: exercise.name,
                            defaultSets: exercise.defaultSets,
                            defaultReps: exercise.defaultReps,
                            muscleGroup: exercise.muscleGroup,
                            notes: exercise.notes
                        )
                    }
                )
            },
            sessions: sessions.map { session in
                SessionExport(
                    id: session.id,
                    date: session.date,
                    workoutDayId: session.workoutDayId,
                    workoutDayName: session.workoutDayName,
                    startTime: session.startTime,
                    endTime: session.endTime,
                    duration: session.duration,
                    notes: session.notes,
                    isCompleted: session.isCompleted,
                    exerciseLogs: session.exerciseLogs.map { log in
                        ExerciseLogExport(
                            id: log.id,
                            exerciseId: log.exerciseId,
                            exerciseName: log.exerciseName,
                            order: log.order,
                            notes: log.notes,
                            sets: log.sets.map { set in
                                SetLogExport(
                                    id: set.id,
                                    setNumber: set.setNumber,
                                    targetReps: set.targetReps,
                                    actualReps: set.actualReps,
                                    weight: set.weight,
                                    weightUnit: set.weightUnit.rawValue,
                                    rir: set.rir,
                                    isCompleted: set.isCompleted,
                                    notes: set.notes
                                )
                            }
                        )
                    }
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try? encoder.encode(exportData)
    }
    
    /// Imports data from JSON
    func importData(from data: Data, context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(ExportData.self, from: data)
        
        // Import workout days and exercises
        for dayExport in importData.workoutDays {
            let exercises = dayExport.exercises.map { exerciseExport in
                let exercise = Exercise(
                    name: exerciseExport.name,
                    defaultSets: exerciseExport.defaultSets,
                    defaultReps: exerciseExport.defaultReps,
                    muscleGroup: exerciseExport.muscleGroup
                )
                exercise.notes = exerciseExport.notes
                return exercise
            }
            
            let workoutDay = WorkoutDay(
                name: dayExport.name,
                dayNumber: dayExport.dayNumber,
                colorHex: dayExport.colorHex,
                exercises: exercises
            )
            
            context.insert(workoutDay)
        }
        
        // Import sessions
        for sessionExport in importData.sessions {
            let session = WorkoutSession(
                date: sessionExport.date,
                workoutDayId: sessionExport.workoutDayId,
                workoutDayName: sessionExport.workoutDayName
            )
            session.startTime = sessionExport.startTime
            session.endTime = sessionExport.endTime
            session.duration = sessionExport.duration
            session.notes = sessionExport.notes
            session.isCompleted = sessionExport.isCompleted
            
            for logExport in sessionExport.exerciseLogs {
                let log = ExerciseLog(
                    exerciseId: logExport.exerciseId,
                    exerciseName: logExport.exerciseName,
                    order: logExport.order
                )
                log.notes = logExport.notes
                
                for setExport in logExport.sets {
                    let setLog = SetLog(
                        setNumber: setExport.setNumber,
                        targetReps: setExport.targetReps,
                        weightUnit: SetLog.WeightUnit(rawValue: setExport.weightUnit) ?? .lbs
                    )
                    setLog.actualReps = setExport.actualReps
                    setLog.weight = setExport.weight
                    setLog.rir = setExport.rir
                    setLog.isCompleted = setExport.isCompleted
                    setLog.notes = setExport.notes
                    
                    log.sets.append(setLog)
                }
                
                session.exerciseLogs.append(log)
            }
            
            context.insert(session)
        }
        
        try context.save()
    }
    
    /// Gets file URL for export
    func getExportFileURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "workout_backup_\(dateFormatter.string(from: Date())).json"
        return documentsPath.appendingPathComponent(fileName)
    }
}

