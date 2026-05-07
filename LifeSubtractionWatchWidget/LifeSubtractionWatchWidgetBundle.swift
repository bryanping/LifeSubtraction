import WidgetKit
import SwiftUI

@main
struct LifeSubtractionWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        WatchLifeWidget()
    }
}

// 專為 watchOS 表面設計的 complication
struct WatchLifeWidget: Widget {
    let kind = "WatchLifeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeProvider()) { entry in
            WatchComplicationView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("人生減法")
        .description("在錶面上看見你剩下的時間。")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

struct WatchComplicationView: View {
    let entry: LifeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:    circular
        case .accessoryCorner:      corner
        case .accessoryInline:      inline
        case .accessoryRectangular: rectangular
        default: circular
        }
    }

    var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .trim(from: 0, to: entry.metrics.percentUsed)
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3)
            VStack(spacing: 0) {
                Text("\(Int(entry.metrics.percentUsed * 100))%")
                    .font(.system(size: 13, weight: .bold))
                Text("已過")
                    .font(.system(size: 8))
            }
        }
    }

    var corner: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: entry.metrics.percentUsed)
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(entry.metrics.percentUsed * 100))%")
                .font(.system(size: 11, weight: .bold))
        }
        .widgetLabel("剩餘 \(entry.metrics.daysRemaining.formatted()) 天")
    }

    var inline: some View {
        Text("剩 \(entry.metrics.daysRemaining.formatted()) 天 · \(entry.metrics.percentString)")
    }

    var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("剩餘 \(entry.metrics.daysRemaining.formatted()) 天")
                .font(.headline)
            Text("\(entry.metrics.weeksRemaining.formatted()) 週 · 已過 \(entry.metrics.percentString)")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            ProgressView(value: entry.metrics.percentUsed)
                .tint(Color.white)  // // modified
        }
    }
}
