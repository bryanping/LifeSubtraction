import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleDailyReminder() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let messages = [
            "今天，你做了什麼值得的事？",
            "你的每一天都在書寫人生。今天的章節是什麼？",
            "剩下的時間比你想的少。比你想的多。好好用它。",
            "今天結束前，做一件讓未來的你感謝的事。",
            "你最重視的人，今天有聯繫嗎？",
        ]

        let content = UNMutableNotificationContent()
        content.title = "人生減法"
        content.body = messages.randomElement() ?? messages[0]
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
}
