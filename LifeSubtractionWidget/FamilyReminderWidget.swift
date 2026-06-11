import WidgetKit
import SwiftUI

struct FamilyReminderEntry: TimelineEntry {
    let date: Date
    let memberName: String?
    let daysSinceContact: Int?
    var isPremium: Bool = true  // 修改内容
}

struct FamilyReminderProvider: TimelineProvider {
    func placeholder(in context: Context) -> FamilyReminderEntry {
        FamilyReminderEntry(date: Date(), memberName: "媽媽", daysSinceContact: 14)
    }

    func getSnapshot(in context: Context, completion: @escaping (FamilyReminderEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FamilyReminderEntry>) -> Void) {
        let entry = makeEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(21600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func makeEntry() -> FamilyReminderEntry {
        let premium = WidgetDataLoader.isPremium  // 修改内容
        if let info = WidgetDataLoader.longestNotContactedFamilyMember() {
            return FamilyReminderEntry(date: Date(), memberName: info.name, daysSinceContact: info.days, isPremium: premium)
        }
        return FamilyReminderEntry(date: Date(), memberName: nil, daysSinceContact: nil, isPremium: premium)
    }
}

struct FamilyReminderWidgetView: View {
    let entry: FamilyReminderEntry

    var body: some View {
        if !entry.isPremium {  // 修改内容
            WidgetLockedView()
        } else if let name = entry.memberName, let days = entry.daysSinceContact {
            VStack(alignment: .leading, spacing: 6) {
                Text("家人提醒")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text(name)
                    .font(.headline)
                    .foregroundStyle(LifeTheme.textPrimary)
                Text(days == 0 ? "今天有聯繫" : "已 \(days) 天未聯繫")
                    .font(.caption)
                    .foregroundStyle(LifeTheme.warm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("家人提醒")
                    .font(.caption2)
                    .foregroundStyle(LifeTheme.textSecondary)
                Text("新增家人資料")
                    .font(.subheadline)
                    .foregroundStyle(LifeTheme.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct FamilyReminderWidget: Widget {
    let kind = "FamilyReminderWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FamilyReminderProvider()) { entry in
            if #available(iOS 17.0, *) {
                FamilyReminderWidgetView(entry: entry)
                    .containerBackground(for: .widget) { LifeTheme.subtleBackground }
            } else {
                FamilyReminderWidgetView(entry: entry).padding().background(LifeTheme.subtleBackground)
            }
        }
        .configurationDisplayName("家人提醒")
        .description("顯示最久未聯繫的重要家人。")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}
