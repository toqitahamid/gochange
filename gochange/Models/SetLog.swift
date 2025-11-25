import SwiftData
import Foundation

@Model
final class SetLog {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var targetReps: String
    var actualReps: Int?
    var weight: Double?
    var weightUnit: WeightUnit
    var rir: Int?                 // Reps In Reserve (0-5 typically)
    var isCompleted: Bool
    var notes: String?
    @Relationship(inverse: \ExerciseLog.sets) var exerciseLog: ExerciseLog?
    
    enum WeightUnit: String, Codable {
        case kg
        case lbs
    }
    
    init(setNumber: Int, targetReps: String, weightUnit: WeightUnit = .lbs) {
        self.id = UUID()
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.weightUnit = weightUnit
        self.isCompleted = false
    }
}

