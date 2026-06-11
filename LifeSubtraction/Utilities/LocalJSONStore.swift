import Foundation

// 修改内容
// 統一的 JSON / UserDefaults 存取輔助。所有新功能（goals、moments、records、reflections...）
// 都走這個入口，避免每處重寫 encode / decode。
final class LocalJSONStore {

    /// 讀取：找不到或 decode 失敗時回傳 defaultValue。
    static func load<T: Decodable>(_ type: T.Type, key: String, defaultValue: T) -> T {
        guard let data = UserDefaults.shared.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return defaultValue
        }
        return decoded
    }

    /// 讀取可選值：找不到或 decode 失敗時回傳 nil。
    static func loadOptional<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.shared.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return nil
        }
        return decoded
    }

    /// 寫入。
    static func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            UserDefaults.shared.set(data, forKey: key)
        }
    }

    /// 移除指定 key。
    static func remove(key: String) {
        UserDefaults.shared.removeObject(forKey: key)
    }
}

// 修改内容 — 集中管理 storage key，避免散落字串。
enum StorageKey {
    static let lifeGoals               = "life-goals"
    static let lifeValues              = AppConstants.Key.values
    static let regretItems             = "regret-avoidance-items"
    static let alignmentRecords        = "life-alignment-records"
    static let reflectionEntries       = "reflection-entries"
    static let remainingMomentItems    = "remaining-moment-items"
    static let remainingMomentRecords  = "remaining-moment-records"
    static let personalEventItems      = remainingMomentItems
    static let personalEventRecords    = remainingMomentRecords
    static let legacyPersonalEventItems = "remaining-moment-items"
    static let legacyPersonalEventRecords = "remaining-moment-records"
    static let lifeJourneyStatItems    = "life-journey-stat-items"
    static let familyMembers           = AppConstants.Key.familyMembers
    static let familyMomentRecords     = AppConstants.Key.familyMomentRecords
    static let legacyLifeGoals         = "life-goals"
    static let legacyParentAge         = "parentAge"
    static let legacyParentLifeExpectancy = "parentLifeExpectancy"

    static func alignment(for date: Date = Date()) -> String {
        "alignment-\(DateFormatter.dateKey(for: date))"
    }

    /// 本週焦點 key：weekly-focus-yyyy-ww
    static func weeklyFocus(for date: Date = Date()) -> String {
        let cal = Calendar.current
        let year = cal.component(.yearForWeekOfYear, from: date)
        let week = cal.component(.weekOfYear, from: date)
        return "weekly-focus-\(year)-\(week)"
    }
}
