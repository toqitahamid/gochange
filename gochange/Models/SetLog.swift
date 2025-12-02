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
    var duration: TimeInterval?   // Duration in seconds
    var rir: Int?                 // Reps In Reserve (0-5 typically)
    var isCompleted: Bool
    var setType: SetType
    var notes: String?
    @Relationship(inverse: \ExerciseLog.sets) var exerciseLog: ExerciseLog?
    
    enum WeightUnit: String, Codable {
        case kg
        case lbs
    }

    enum SetType: String, Codable {
        case normal
        case warmup
        case cooldown
        case failure
        case dropset

        var displayName: String {
            switch self {
            case .normal: return "Normal"
            case .warmup: return "Warmup"
            case .cooldown: return "Cooldown"
            case .failure: return "Failure"
            case .dropset: return "Dropset"
            }
        }

        var icon: String {
            switch self {
            case .normal: return "circle.fill"
            case .warmup: return "flame.fill"
            case .cooldown: return "snowflake"
            case .failure: return "bolt.fill"
            case .dropset: return "arrow.down.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .normal: return "#5B7FFF"
            case .warmup: return "#FF9500"
            case .cooldown: return "#34C759"
            case .failure: return "#FF3B30"
            case .dropset: return "#AF52DE"
            }
        }
    }

    init(setNumber: Int, targetReps: String, weightUnit: WeightUnit = .lbs) {
        self.id = UUID()
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.weightUnit = weightUnit
        self.isCompleted = false
        self.setType = .normal
    }
}

