import WidgetKit
import SwiftUI

// Note: @main attribute is applied in widget extension target only
// This file is conditionally compiled to avoid conflicts

struct WorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutActivityWidget()
        // GoChangeStaticWidget() - TODO: Fix target membership
    }
}
