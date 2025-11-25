import ActivityKit
import WidgetKit
import SwiftUI

struct RestTimerWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RestTimerAttributes.self) { context in
            // Lock Screen/Banner UI
            RestTimerActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Label("Rest", systemImage: "timer")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                        .padding(.leading)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                        .padding(.trailing)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text("Resting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Optional: Add progress bar or more details
                }
            } compactLeading: {
                Image(systemName: "timer")
                    .foregroundColor(.accentColor)
                    .padding(.leading, 4)
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .frame(width: 50)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "timer")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct RestTimerActivityView: View {
    let context: ActivityViewContext<RestTimerAttributes>
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.accentColor)
                Text("Rest Timer")
                    .font(.headline)
                Spacer()
                Text(timerInterval: Date()...context.state.endTime, countsDown: true)
                    .font(.title)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            .padding()
        }
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(Color.white)
    }
}
