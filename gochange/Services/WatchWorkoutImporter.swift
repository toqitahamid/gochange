import Foundation
import SwiftData

/// Converts a completed Watch workout payload into SwiftData models.
struct WatchWorkoutImporter {

    /// Parse the raw [String: Any] dictionary sent by WatchWorkoutManager and persist
    /// it as a WorkoutSession (with ExerciseLogs and SetLogs) in the given context.
    @MainActor
    static func importWorkout(from payload: [String: Any], context: ModelContext) throws {
        guard
            let workoutDayIdStr = payload["workoutDayId"] as? String,
            let workoutDayId = UUID(uuidString: workoutDayIdStr),
            let workoutDayName = payload["workoutDayName"] as? String,
            let startEpoch = payload["startTime"] as? TimeInterval,
            let endEpoch = payload["endTime"] as? TimeInterval,
            let duration = payload["duration"] as? TimeInterval
        else {
            throw ImportError.missingRequiredFields
        }

        let startTime = Date(timeIntervalSince1970: startEpoch)
        let endTime = Date(timeIntervalSince1970: endEpoch)

        // Avoid duplicates: check if a session for this day already exists at the same startTime
        let startOfSession = Calendar.current.startOfDay(for: startTime)
        let descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { session in
                session.workoutDayId == workoutDayId &&
                session.date >= startOfSession
            }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.contains(where: { abs($0.startTime.timeIntervalSince(startTime)) < 60 }) {
            return // Already imported, skip
        }

        // Build exercise logs
        let rawLogs = payload["exerciseLogs"] as? [[String: Any]] ?? []
        var exerciseLogs: [ExerciseLog] = rawLogs.compactMap { logDict in
            guard
                let exerciseIdStr = logDict["exerciseId"] as? String,
                let exerciseId = UUID(uuidString: exerciseIdStr),
                let exerciseName = logDict["exerciseName"] as? String,
                let order = logDict["order"] as? Int
            else { return nil }

            let rawSets = logDict["sets"] as? [[String: Any]] ?? []
            let setLogs: [SetLog] = rawSets.compactMap { setDict in
                guard
                    let setNumber = setDict["setNumber"] as? Int,
                    let isCompleted = setDict["isCompleted"] as? Bool
                else { return nil }

                let targetReps = setDict["targetReps"] as? String ?? "10"
                let actualReps = setDict["actualReps"] as? Int
                let weight = setDict["weight"] as? Double
                let weightUnitStr = setDict["weightUnit"] as? String ?? "lbs"
                let weightUnit: SetLog.WeightUnit = weightUnitStr == "kg" ? .kg : .lbs

                let setLog = SetLog(setNumber: setNumber, targetReps: targetReps)
                setLog.actualReps = actualReps
                setLog.weight = weight
                setLog.weightUnit = weightUnit
                setLog.isCompleted = isCompleted
                return setLog
            }

            let exerciseLog = ExerciseLog(exerciseId: exerciseId, exerciseName: exerciseName, order: order)
            exerciseLog.sets = setLogs
            return exerciseLog
        }

        // Create the session
        let session = WorkoutSession(date: startTime, workoutDayId: workoutDayId, workoutDayName: workoutDayName)
        session.startTime = startTime
        session.endTime = endTime
        session.duration = duration
        session.isCompleted = true
        session.exerciseLogs = exerciseLogs

        context.insert(session)
        try context.save()
    }

    enum ImportError: Error {
        case missingRequiredFields
    }
}
