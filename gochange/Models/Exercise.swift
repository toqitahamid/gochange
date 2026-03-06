import SwiftData
import Foundation

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var defaultSets: Int
    var defaultWeight: Double?
    var defaultReps: String       // String to handle ranges like "6-8"
    var muscleGroup: String
    var notes: String?
    var mediaURL: String?         // Local file path for video/image
    var mediaType: MediaType?
    var defaultRestDuration: TimeInterval = AppConstants.Defaults.restTimerDuration
    var sortOrder: Int = 0
    @Relationship(inverse: \WorkoutDay.exercises) var workoutDay: WorkoutDay?
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    init(name: String, defaultSets: Int, defaultReps: String, defaultWeight: Double? = nil, muscleGroup: String) {
        self.id = UUID()
        self.name = name
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.defaultWeight = defaultWeight
        self.muscleGroup = muscleGroup
    }
}

