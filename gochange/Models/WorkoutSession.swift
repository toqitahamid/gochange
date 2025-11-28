import SwiftData
import Foundation

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var workoutDayId: UUID
    var workoutDayName: String
    var startTime: Date
    var endTime: Date?
    var duration: TimeInterval?
    var notes: String?
    var isCompleted: Bool
    var rpe: Double?
    @Relationship(deleteRule: .cascade) var exerciseLogs: [ExerciseLog]
    
    init(date: Date, workoutDayId: UUID, workoutDayName: String) {
        self.id = UUID()
        self.date = date
        self.workoutDayId = workoutDayId
        self.workoutDayName = workoutDayName
        self.startTime = Date()
        self.isCompleted = false
        self.exerciseLogs = []
    }
}

