//
//  WidgetGlucoseLiveActivity.swift
//  WidgetGlucose
//
//  Created by Victoria Marin on 08/06/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WidgetGlucoseAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WidgetGlucoseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WidgetGlucoseAttributes.self) { context in
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

extension WidgetGlucoseAttributes {
    fileprivate static var preview: WidgetGlucoseAttributes {
        WidgetGlucoseAttributes(name: "World")
    }
}

extension WidgetGlucoseAttributes.ContentState {
    fileprivate static var smiley: WidgetGlucoseAttributes.ContentState {
        WidgetGlucoseAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WidgetGlucoseAttributes.ContentState {
         WidgetGlucoseAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WidgetGlucoseAttributes.preview) {
   WidgetGlucoseLiveActivity()
} contentStates: {
    WidgetGlucoseAttributes.ContentState.smiley
    WidgetGlucoseAttributes.ContentState.starEyes
}
