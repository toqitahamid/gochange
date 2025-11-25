import SwiftData
import Foundation

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var defaultSets: Int
    var defaultReps: String       // String to handle ranges like "6-8"
    var muscleGroup: String
    var notes: String?
    var mediaURL: String?         // Local file path for video/image
    var mediaType: MediaType?
    @Relationship(inverse: \WorkoutDay.exercises) var workoutDay: WorkoutDay?
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    init(name: String, defaultSets: Int, defaultReps: String, muscleGroup: String) {
        self.id = UUID()
        self.name = name
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.muscleGroup = muscleGroup
    }
}

