import Foundation

enum ReflectionPeriod: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:  return "單日"
        case .weekly: return "每週"
        }
    }

    var prompt: String {
        switch self {
        case .daily:
            return "今天，你做了什麼讓未來的你感謝的事？"
        case .weekly:
            return "如果這週只能完成一件事，那會是什麼？"
        }
    }

    var saveButtonTitle: String {
        switch self {
        case .daily:  return "保存今日反思"
        case .weekly: return "保存本週反思"
        }
    }

    var savedHint: String {
        switch self {
        case .daily:  return "已記錄今日反思"
        case .weekly: return "已記錄本週反思"
        }
    }
}

struct ReflectionEntry: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var text: String
    var period: ReflectionPeriod = .daily

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        text: String,
        period: ReflectionPeriod = .daily
    ) {
        self.id = id
        self.date = date
        self.text = text
        self.period = period
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        date = try c.decode(Date.self, forKey: .date)
        text = try c.decode(String.self, forKey: .text)
        period = try c.decodeIfPresent(ReflectionPeriod.self, forKey: .period) ?? .daily
    }

    enum CodingKeys: String, CodingKey {
        case id, date, text, period
    }
}

extension ReflectionEntry {
    static let storageKey = "reflection-entries"

    func bucketKey(calendar: Calendar = .current) -> String {
        switch period {
        case .daily:
            return DateFormatter.dateKey(for: date)
        case .weekly:
            let year = calendar.component(.yearForWeekOfYear, from: date)
            let week = calendar.component(.weekOfYear, from: date)
            return "\(year)-\(week)"
        }
    }

    static func bucketKey(for date: Date, period: ReflectionPeriod, calendar: Calendar = .current) -> String {
        ReflectionEntry(date: date, text: "", period: period).bucketKey(calendar: calendar)
    }

    static func current(in entries: [ReflectionEntry], period: ReflectionPeriod, date: Date = Date()) -> ReflectionEntry? {
        let key = bucketKey(for: date, period: period)
        return entries
            .filter { $0.period == period }
            .first { $0.bucketKey() == key }
    }

    @discardableResult
    static func upsert(
        text: String,
        period: ReflectionPeriod,
        in entries: inout [ReflectionEntry],
        date: Date = Date()
    ) -> ReflectionEntry {
        let key = bucketKey(for: date, period: period)
        if let index = entries.firstIndex(where: { $0.period == period && $0.bucketKey() == key }) {
            entries[index].text = text
            entries[index].date = date
            return entries[index]
        }
        let entry = ReflectionEntry(date: date, text: text, period: period)
        entries.append(entry)
        return entry
    }

    /// 將舊版 `weekly-focus-yyyy-ww` 字串遷移為每週反思紀錄。
    static func migrateLegacyWeeklyFocus(into entries: inout [ReflectionEntry]) -> Bool {
        let cal = Calendar.current
        let year = cal.component(.yearForWeekOfYear, from: Date())
        let week = cal.component(.weekOfYear, from: Date())
        let legacyKey = "weekly-focus-\(year)-\(week)"

        guard let legacyText = LocalJSONStore.loadOptional(String.self, key: legacyKey),
              !legacyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }

        if current(in: entries, period: .weekly) != nil {
            return false
        }

        upsert(text: legacyText, period: .weekly, in: &entries)
        return true
    }
}
