import SwiftData
import Foundation

@Model
final class ExerciseLog {
    @Attribute(.unique) var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var order: Int
    var notes: String?
    @Relationship(deleteRule: .cascade) var sets: [SetLog]
    @Relationship(inverse: \WorkoutSession.exerciseLogs) var session: WorkoutSession?
    
    init(exerciseId: UUID, exerciseName: String, order: Int) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.order = order
        self.sets = []
    }
}

