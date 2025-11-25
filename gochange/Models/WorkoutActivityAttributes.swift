import ActivityKit
import SwiftUI

struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var exerciseCount: Int
        var completedSets: Int
        var totalSets: Int
    }
    
    var workoutName: String
    var workoutColor: String
}

