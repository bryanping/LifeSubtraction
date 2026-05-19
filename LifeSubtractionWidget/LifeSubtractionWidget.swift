//
//  LifeSubtractionWidget.swift
//  LifeSubtractionWidget
//
//  人生減法 — 主 Widget：剩餘天數 + 進度
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct LifeEntry: TimelineEntry {
    let date: Date
    let metrics: LifeMetrics
}

// MARK: - Provider

struct LifeProvider: TimelineProvider {
    func placeholder(in context: Context) -> LifeEntry {
        LifeEntry(date: Date(), metrics: sampleMetrics())
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeEntry) -> Void) {
        completion(LifeEntry(date: Date(), metrics: LifeMetrics.loadFromShared()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeEntry>) -> Void) {
        let base = LifeMetrics.loadFromShared()
        var entries: [LifeEntry] = []
        let now = Date()
        let cal = Calendar.current
        for hourOffset in 0..<6 {
            let entryDate = cal.date(byAdding: .hour, value: hourOffset, to: now) ?? now
            let metrics = LifeMetrics(
                birthday: base.birthday,
                lifeExpectancy: base.lifeExpectancy,
                now: entryDate
            )
            entries.append(LifeEntry(date: entryDate, metrics: metrics))
        }
        let next = cal.date(byAdding: .hour, value: 6, to: now) ?? now.addingTimeInterval(3600 * 6)
        completion(Timeline(entries: entries, policy: .after(next)))
    }

    private func sampleMetrics() -> LifeMetrics {
        let birthday = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        return LifeMetrics(birthday: birthday, lifeExpectancy: 80)
    }
}

// MARK: - View

struct LifeSubtractionWidgetEntryView: View {
    var entry: LifeProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:    smallView
        case .systemMedium:   mediumView
        case .systemLarge:    largeView
        case .accessoryCircular:    circularView
        case .accessoryRectangular: rectangularView
        case .accessoryInline:      inlineView
        default: smallView
        }
    }

    // MARK: System Small
    var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("剩餘")
                .font(.caption2).foregroundStyle(Color.white.opacity(0.85))
            Text(entry.metrics.daysRemaining.formatted())
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("天")
                .font(.caption).foregroundStyle(Color.white.opacity(0.85))
            Spacer()
            ProgressMini(value: entry.metrics.percentUsed)
            Text("已過 \(entry.metrics.percentString)")
                .font(.caption2).foregroundStyle(Color.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: System Medium
    var mediumView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("剩餘的時間")
                    .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                Text(entry.metrics.daysRemaining.formatted())
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                Text("天")
                    .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                Spacer()
                ProgressMini(value: entry.metrics.percentUsed)
                Text("已過 \(entry.metrics.percentString)")
                    .font(.caption2).foregroundStyle(Color.white.opacity(0.9))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                StatLine(label: "週剩餘", value: entry.metrics.weeksRemaining.formatted())
                StatLine(label: "年剩餘", value: "\(entry.metrics.yearsRemaining)")
                StatLine(label: "現在",   value: "\(entry.metrics.ageYears) 歲")
            }
        }
    }

    // MARK: System Large
    var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading) {
                    Text("人生減法")
                        .font(.caption).foregroundStyle(Color.white.opacity(0.85))
                    Text(entry.metrics.daysRemaining.formatted())
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .foregroundStyle(Color.white)
                    Text("天剩餘 · 已過 \(entry.metrics.percentString)")
                        .font(.caption).foregroundStyle(Color.white.opacity(0.9))
                }
                Spacer()
            }
            ProgressMini(value: entry.metrics.percentUsed, height: 8)
            Divider().background(Color.white.opacity(0.3))  // // modified
            HStack {
                StatLine(label: "週剩餘", value: entry.metrics.weeksRemaining.formatted())
                Spacer()
                StatLine(label: "年剩餘", value: "\(entry.metrics.yearsRemaining)")
                Spacer()
                StatLine(label: "本年進度", value: "\(Int(entry.metrics.progressOfCurrentYear * 100))%")
            }
            Spacer(minLength: 0)
            FuturePreview(metrics: entry.metrics)
                .frame(maxHeight: 90)
        }
    }

    // MARK: Lock Screen / Watch accessories
    var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .trim(from: 0, to: entry.metrics.percentUsed)
                .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3)
            VStack(spacing: 0) {
                Text("\(Int(entry.metrics.percentUsed * 100))%")
                    .font(.system(size: 12, weight: .bold))
                Text("已過")
                    .font(.system(size: 8))
            }
        }
    }

    var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("剩餘 \(entry.metrics.daysRemaining.formatted()) 天")
                .font(.headline)
            Text("已過 \(entry.metrics.percentString) · \(entry.metrics.weeksRemaining.formatted()) 週剩餘")
                .font(.caption2).foregroundStyle(LifeTheme.textSecondary)  // // modified
            ProgressView(value: entry.metrics.percentUsed)
                .tint(Color.white)  // // modified
        }
    }

    var inlineView: some View {
        Text("剩餘 \(entry.metrics.daysRemaining.formatted()) 天 · \(entry.metrics.percentString) 已過")
    }
}

// MARK: - Sub views

struct StatLine: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .rounded)).fontWeight(.semibold)
                .foregroundStyle(Color.white)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(Color.white.opacity(0.8))
        }
    }
}

struct ProgressMini: View {
    let value: Double
    var height: CGFloat = 5
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25))
                Capsule().fill(Color.white)
                    .frame(width: geo.size.width * value)
            }
        }
        .frame(height: height)
    }
}

struct FuturePreview: View {
    let metrics: LifeMetrics
    let cols = 12
    var rows: Int { 8 }
    var body: some View {
        GeometryReader { geo in
            let total = cols * rows
            let visibleFuture = min(total, metrics.weeksRemaining)
            let dot = (geo.size.width - CGFloat(cols - 1) * 3) / CGFloat(cols)
            VStack(alignment: .leading, spacing: 3) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 3) {
                        ForEach(0..<cols, id: \.self) { c in
                            let i = r * cols + c
                            Circle()
                                .fill(i < visibleFuture
                                      ? Color.white.opacity(i == 0 ? 1.0 : 0.55)
                                      : Color.white.opacity(0.1))
                                .frame(width: dot, height: dot)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Widget

struct LifeSubtractionWidget: Widget {
    let kind: String = "LifeSubtractionWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeProvider()) { entry in
            if #available(iOS 17.0, *) {
                LifeSubtractionWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LifeTheme.heroGradient
                    }
            } else {
                LifeSubtractionWidgetEntryView(entry: entry)
                    .padding()
                    .background(LifeTheme.heroGradient)
            }
        }
        .configurationDisplayName("人生減法")
        .description("看見你還剩下多少時間。")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    LifeSubtractionWidget()
} timeline: {
    LifeEntry(date: .now, metrics: LifeMetrics(
        birthday: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
        lifeExpectancy: 80
    ))
}
