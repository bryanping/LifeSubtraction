//
//  LifeSubtractionWidgetLiveActivity.swift
//  LifeSubtractionWidget
//
//  人生減法 Live Activity（鎖定畫面 / 動態島）。
//  目前 App 沒呼叫 ActivityKit 啟動 activity，這個檔案僅作為 Widget Bundle 的成員，
//  保留以便未來想做「年度倒數」之類的 Live Activity 直接擴充。
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LifeSubtractionWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var daysRemaining: Int
        var percentUsed: Double
    }
    var goalLabel: String
}

struct LifeSubtractionWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LifeSubtractionWidgetAttributes.self) { context in
            // Lock Screen / Banner
            HStack(spacing: 14) {
                Image(systemName: "hourglass")
                    .foregroundStyle(LifeTheme.accent)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.goalLabel)
                        .font(.caption).foregroundStyle(LifeTheme.textSecondary)  // // modified
                    Text("剩餘 \(context.state.daysRemaining.formatted()) 天")
                        .font(.headline)
                }
                Spacer()
                Text("\(Int(context.state.percentUsed * 100))%")
                    .font(.system(.title3, design: .rounded)).fontWeight(.semibold)
                    .foregroundStyle(LifeTheme.accent)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.4))
            .activitySystemActionForegroundColor(LifeTheme.accent)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "hourglass")
                        .foregroundStyle(LifeTheme.accent)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.percentUsed * 100))%")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(LifeTheme.accent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("剩餘 \(context.state.daysRemaining.formatted()) 天")
                        .font(.subheadline)
                }
            } compactLeading: {
                Image(systemName: "hourglass")
                    .foregroundStyle(LifeTheme.accent)
            } compactTrailing: {
                Text("\(Int(context.state.percentUsed * 100))%")
            } minimal: {
                Image(systemName: "hourglass")
                    .foregroundStyle(LifeTheme.accent)
            }
        }
    }
}

extension LifeSubtractionWidgetAttributes {
    fileprivate static var preview: LifeSubtractionWidgetAttributes {
        LifeSubtractionWidgetAttributes(goalLabel: "人生倒數")
    }
}

extension LifeSubtractionWidgetAttributes.ContentState {
    fileprivate static var sample: LifeSubtractionWidgetAttributes.ContentState {
        LifeSubtractionWidgetAttributes.ContentState(daysRemaining: 18250, percentUsed: 0.375)
    }
}

#Preview("Notification", as: .content, using: LifeSubtractionWidgetAttributes.preview) {
    LifeSubtractionWidgetLiveActivity()
} contentStates: {
    LifeSubtractionWidgetAttributes.ContentState.sample
}
