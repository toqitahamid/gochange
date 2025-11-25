import SwiftData
import Foundation

@Model
final class WorkoutDay {
    @Attribute(.unique) var id: UUID
    var name: String              // "Push", "Pull", "Legs", "Fullbody"
    var dayNumber: Int            // 1, 2, 3, 4
    var colorHex: String          // For UI theming
    @Relationship(deleteRule: .cascade) var exercises: [Exercise]
    
    init(name: String, dayNumber: Int, colorHex: String, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.dayNumber = dayNumber
        self.colorHex = colorHex
        self.exercises = exercises
    }
}

