import ActivityKit
import SwiftUI

struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var endTime: Date
    }

    // Fixed non-changing properties about your activity go here!
    var timerName: String
}
