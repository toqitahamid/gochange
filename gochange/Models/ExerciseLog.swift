import SwiftData
import Foundation

@Model
final class ExerciseLog {
    @Attribute(.unique) var id: UUID
    var exerciseId: UUID
    var exerciseName: String
    var order: Int
    var notes: String?
    var groupId: UUID?           // Exercises with same groupId are grouped together
    var groupType: GroupType?    // Type of grouping (superset or circuit)
    @Relationship(deleteRule: .cascade) var sets: [SetLog]
    @Relationship(inverse: \WorkoutSession.exerciseLogs) var session: WorkoutSession?

    enum GroupType: String, Codable {
        case superset
        case circuit

        var displayName: String {
            switch self {
            case .superset: return "Superset"
            case .circuit: return "Circuit"
            }
        }

        var icon: String {
            switch self {
            case .superset: return "arrow.left.arrow.right"
            case .circuit: return "arrow.triangle.2.circlepath.circle"
            }
        }

        var color: String {
            switch self {
            case .superset: return "#FF9500"
            case .circuit: return "#AF52DE"
            }
        }
    }

    init(exerciseId: UUID, exerciseName: String, order: Int) {
        self.id = UUID()
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.order = order
        self.sets = []
        self.groupId = nil
        self.groupType = nil
    }
}

