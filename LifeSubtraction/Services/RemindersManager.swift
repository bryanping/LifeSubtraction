import EventKit
import Foundation

@MainActor
final class RemindersManager {
    static let shared = RemindersManager()

    private let store = EKEventStore()
    private let listTitle = "LifeSubtraction"

    private init() {}

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToReminders()
        } catch {
            return false
        }
    }

    func syncGoal(_ goal: LifeGoal) async -> String? {
        guard await requestAccess() else { return nil }

        let list = await fetchOrCreateList()
        guard let list else { return nil }

        if let existingId = goal.reminderIdentifier,
           let reminder = store.calendarItem(withIdentifier: existingId) as? EKReminder {
            reminder.title = goal.title
            reminder.notes = goal.notes.isEmpty ? "來自人生減法" : goal.notes
            try? store.save(reminder, commit: true)
            return existingId
        }

        let reminder = EKReminder(eventStore: store)
        reminder.title = goal.title
        reminder.notes = goal.notes.isEmpty ? "來自人生減法 · 人生想完成的事" : goal.notes
        reminder.calendar = list

        let alarm = EKAlarm(absoluteDate: endOfYear())
        reminder.addAlarm(alarm)

        do {
            try store.save(reminder, commit: true)
            return reminder.calendarItemIdentifier
        } catch {
            return nil
        }
    }

    func removeReminder(identifier: String?) {
        guard let identifier,
              let reminder = store.calendarItem(withIdentifier: identifier) as? EKReminder
        else { return }
        try? store.remove(reminder, commit: true)
    }

    private func fetchOrCreateList() async -> EKCalendar? {
        let calendars = store.calendars(for: .reminder)
        if let existing = calendars.first(where: { $0.title == listTitle }) {
            return existing
        }

        let calendar = EKCalendar(for: .reminder, eventStore: store)
        calendar.title = listTitle
        calendar.source = store.defaultCalendarForNewReminders()?.source
            ?? store.sources.first { $0.sourceType == .local }

        guard calendar.source != nil else { return nil }
        try? store.saveCalendar(calendar, commit: true)
        return calendar
    }

    private func endOfYear() -> Date {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return cal.date(from: DateComponents(year: year, month: 12, day: 28, hour: 9, minute: 0)) ?? Date()
    }
}

@MainActor
final class AppleCalendarManager {
    static let shared = AppleCalendarManager()

    private let store = EKEventStore()

    private init() {}

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // 修改内容 — 每週 N 次、每次固定 1 小時、每週重複至預計完成日
    func syncGoal(_ goal: LifeGoal) async -> [String] {
        guard await requestAccess() else { return [] }

        removeEvents(identifiers: goal.timePlan.calendarEventIdentifiers)

        let calendar = store.defaultCalendarForNewEvents
        let cal = Calendar.current
        let sessions = goal.weeklySessionCount
        let firstStart = combinedDate(day: goal.timePlan.startDate, time: goal.timePlan.execTime)
        var recurrenceEnd: EKRecurrenceEnd?
        if let completion = goal.estimatedCompletionDate {
            recurrenceEnd = EKRecurrenceEnd(end: completion)
        }

        var identifiers: [String] = []
        for i in 0..<sessions {
            // 平均分散在一週內（例：2 次 → 間隔約 3~4 天）
            let dayOffset = Int((Double(i) * 7 / Double(sessions)).rounded())
            guard let start = cal.date(byAdding: .day, value: dayOffset, to: firstStart) else { continue }

            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = goal.displayTitle
            event.notes = calendarNotes(for: goal)
            event.startDate = start
            event.endDate = start.addingTimeInterval(3600) // 固定 1 小時
            event.recurrenceRules = [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: recurrenceEnd)]

            if (try? store.save(event, span: .futureEvents, commit: true)) != nil {
                identifiers.append(event.eventIdentifier)
            }
        }
        return identifiers
    }

    // 修改内容 — 移除多筆行程（含重複）
    func removeEvents(identifiers: [String]) {
        for identifier in identifiers {
            guard let event = store.event(withIdentifier: identifier) else { continue }
            try? store.remove(event, span: .futureEvents, commit: true)
        }
    }

    private func combinedDate(day: Date, time: Date) -> Date {
        let cal = Calendar.current
        let dayComponents = cal.dateComponents([.year, .month, .day], from: day)
        let timeComponents = cal.dateComponents([.hour, .minute], from: time)
        return cal.date(from: DateComponents(
            year: dayComponents.year,
            month: dayComponents.month,
            day: dayComponents.day,
            hour: timeComponents.hour,
            minute: timeComponents.minute
        )) ?? day
    }

    private func calendarNotes(for goal: LifeGoal) -> String {
        var lines = ["來自人生減法 · 規劃"]
        if let estimatedHours = goal.estimatedHours {
            lines.append("預估總長：\(estimatedHours) 小時")
        }
        lines.append(String(format: "每週投入：%.1f 小時（每週 %d 次、每次 1 小時）", goal.effectiveWeeklyHours, goal.weeklySessionCount)) // 修改内容
        if let date = goal.estimatedCompletionDate { // 修改内容
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "yyyy/MM/dd"
            lines.append("預計完成：\(formatter.string(from: date))")
        }
        if !goal.notes.isEmpty {
            lines.append("")
            lines.append(goal.notes)
        }
        return lines.joined(separator: "\n")
    }
}
