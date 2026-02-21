//
//  BabyBuddyWidgetLiveActivity.swift
//  BabyBuddyWidget
//
//  Created by Aniket Patil on 2/19/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BabyBuddyWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct BabyBuddyWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BabyBuddyWidgetAttributes.self) { context in
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

extension BabyBuddyWidgetAttributes {
    fileprivate static var preview: BabyBuddyWidgetAttributes {
        BabyBuddyWidgetAttributes(name: "World")
    }
}

extension BabyBuddyWidgetAttributes.ContentState {
    fileprivate static var smiley: BabyBuddyWidgetAttributes.ContentState {
        BabyBuddyWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: BabyBuddyWidgetAttributes.ContentState {
         BabyBuddyWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: BabyBuddyWidgetAttributes.preview) {
   BabyBuddyWidgetLiveActivity()
} contentStates: {
    BabyBuddyWidgetAttributes.ContentState.smiley
    BabyBuddyWidgetAttributes.ContentState.starEyes
}
