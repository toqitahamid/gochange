import ActivityKit
import SwiftUI

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var exerciseCount: Int
        var completedSets: Int
        var totalSets: Int
        var currentExerciseName: String?
        var isPaused: Bool
        
        // Rest Timer State (nil when not resting)
        var restEndTime: Date?
        var restTotalDuration: TimeInterval?
        var restAfterSetNumber: Int?
    }
    
    var workoutName: String
    var workoutColor: String
}
