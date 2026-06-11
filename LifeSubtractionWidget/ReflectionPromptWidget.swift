import WidgetKit
import SwiftUI

struct ReflectionPromptEntry: TimelineEntry {
    let date: Date
    let prompt: String
    var isPremium: Bool = true  // 修改内容
}

struct ReflectionPromptProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReflectionPromptEntry {
        ReflectionPromptEntry(date: Date(), prompt: "今天，你做了什麼讓未來的你感謝的事？")
    }

    func getSnapshot(in context: Context, completion: @escaping (ReflectionPromptEntry) -> Void) {
        completion(ReflectionPromptEntry(date: Date(), prompt: WidgetDataLoader.dailyReflectionPrompt(), isPremium: WidgetDataLoader.isPremium))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReflectionPromptEntry>) -> Void) {
        let entry = ReflectionPromptEntry(date: Date(), prompt: WidgetDataLoader.dailyReflectionPrompt(), isPremium: WidgetDataLoader.isPremium)  // 修改内容
        let next = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date().addingTimeInterval(10800)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct ReflectionPromptWidgetView: View {
    let entry: ReflectionPromptEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.isPremium {  // 修改内容
            WidgetLockedView()
        } else {
            content
        }
    }

    @ViewBuilder
    var content: some View {
        switch family {
        case .accessoryInline:
            Text(entry.prompt)
                .lineLimit(1)
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("今日反思").font(.caption2)
                Text(entry.prompt).font(.caption).lineLimit(2)
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                Text("今日反思")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text(entry.prompt)
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ReflectionPromptWidget: Widget {
    let kind = "ReflectionPromptWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReflectionPromptProvider()) { entry in
            if #available(iOS 17.0, *) {
                ReflectionPromptWidgetView(entry: entry)
                    .containerBackground(for: .widget) { LifeTheme.subtleBackground }
            } else {
                ReflectionPromptWidgetView(entry: entry).padding().background(LifeTheme.subtleBackground)
            }
        }
        .configurationDisplayName("每日反思")
        .description("提醒你寫下今日的一句反思。")
        .supportedFamilies([.systemSmall, .accessoryInline, .accessoryRectangular])
    }
}
