//
//  LifeProgressWidget.swift
//  LifeSubtractionWidget
//
//  人生減法 — 第二款 Widget：當前年/週進度
//

import WidgetKit
import SwiftUI

struct LifeProgressWidget: Widget {
    let kind = "LifeProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeProvider()) { entry in
            if #available(iOS 17.0, *) {
                LifeProgressWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LifeTheme.subtleBackground  // // modified — 深藍黑底
                    }
            } else {
                LifeProgressWidgetEntryView(entry: entry)
                    .padding()
                    .background(LifeTheme.subtleBackground)  // // modified — 深藍黑底)
            }
        }
        .configurationDisplayName("本年/本週進度")
        .description("當前的年與週走到哪裡了。")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular])
    }
}

struct LifeProgressWidgetEntryView: View {
    let entry: LifeEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:    smallView
        case .systemMedium:   mediumView
        case .accessoryCircular: circularView
        default: smallView
        }
    }

    var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("這一年")
                .font(.caption).foregroundStyle(LifeTheme.textSecondary)  // // modified
            HStack(alignment: .firstTextBaseline) {
                Text("\(entry.metrics.ageYears)")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(LifeTheme.accent)
                Text("歲")
                    .font(.subheadline).foregroundStyle(LifeTheme.textSecondary)  // // modified
            }
            ProgressLine(value: entry.metrics.progressOfCurrentYear, color: LifeTheme.warm)
            Text("本年已過 \(Int(entry.metrics.progressOfCurrentYear * 100))%")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            Spacer(minLength: 0)
            ProgressLine(value: entry.metrics.progressOfCurrentWeek, color: LifeTheme.accent)
            Text("本週已過 \(Int(entry.metrics.progressOfCurrentWeek * 100))%")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
        }
    }

    var mediumView: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("這一年").font(.caption).foregroundStyle(LifeTheme.textSecondary)  // // modified
                Text("\(entry.metrics.ageYears) 歲")
                    .font(.title2).fontWeight(.semibold)
                ProgressLine(value: entry.metrics.progressOfCurrentYear, color: LifeTheme.warm)
                Text("\(Int(entry.metrics.progressOfCurrentYear * 100))%")
                    .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("這一週").font(.caption).foregroundStyle(LifeTheme.textSecondary)  // // modified
                Text("第 \(entry.metrics.weeksLived + 1) 週")
                    .font(.title2).fontWeight(.semibold)
                ProgressLine(value: entry.metrics.progressOfCurrentWeek, color: LifeTheme.accent)
                Text("\(Int(entry.metrics.progressOfCurrentWeek * 100))%")
                    .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            }
        }
    }

    var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .trim(from: 0, to: entry.metrics.progressOfCurrentYear)
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3)
            Text("\(entry.metrics.ageYears)")
                .font(.system(size: 14, weight: .bold))
        }
    }
}

struct ProgressLine: View {
    let value: Double
    var color: Color = LifeTheme.accent
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))  // // modified
                Capsule().fill(color)
                    .frame(width: geo.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 6)
    }
}

#Preview(as: .systemSmall) {
    LifeProgressWidget()
} timeline: {
    LifeEntry(date: .now, metrics: LifeMetrics(
        birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
        lifeExpectancy: 80
    ))
}
