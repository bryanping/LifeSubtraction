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
