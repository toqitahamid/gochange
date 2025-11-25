//
//  GoChangeWidgetLiveActivity.swift
//  GoChangeWidget
//
//  Created by Toqi Tahamid Sarker on 11/25/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct GoChangeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct GoChangeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GoChangeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension GoChangeWidgetAttributes {
    fileprivate static var preview: GoChangeWidgetAttributes {
        GoChangeWidgetAttributes(name: "World")
    }
}

extension GoChangeWidgetAttributes.ContentState {
    fileprivate static var smiley: GoChangeWidgetAttributes.ContentState {
        GoChangeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: GoChangeWidgetAttributes.ContentState {
         GoChangeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: GoChangeWidgetAttributes.preview) {
   GoChangeWidgetLiveActivity()
} contentStates: {
    GoChangeWidgetAttributes.ContentState.smiley
    GoChangeWidgetAttributes.ContentState.starEyes
}
