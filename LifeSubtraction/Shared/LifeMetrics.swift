import Foundation

// MARK: - LifeMetrics
// 純值型別。給定生日 + 預期壽命，就能計算所有 UI 需要的衍生數據。
// 主 App / Widget / Watch 三邊共用，避免重複邏輯。

public struct LifeMetrics: Equatable, Sendable {
    public let birthday: Date
    public let lifeExpectancy: Int
    public let now: Date

    public init(birthday: Date, lifeExpectancy: Int, now: Date = Date()) {
        self.birthday = birthday
        self.lifeExpectancy = lifeExpectancy
        self.now = now
    }

    // MARK: - 基礎天數

    public var daysLived: Int {
        max(0, Calendar.current.dateComponents([.day], from: birthday, to: now).day ?? 0)
    }
    public var totalDays: Int { Int(Double(lifeExpectancy) * 365.25) }
    public var daysRemaining: Int { max(0, totalDays - daysLived) }
    public var percentUsed: Double {
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(daysLived) / Double(totalDays))
    }
    public var percentRemaining: Double { 1.0 - percentUsed }

    // MARK: - 年齡

    public var ageYears: Int {
        max(0, Calendar.current.dateComponents([.year], from: birthday, to: now).year ?? 0)
    }
    public var yearsRemaining: Int { max(0, lifeExpectancy - ageYears) }

    // MARK: - 週

    public var weeksLived: Int { daysLived / 7 }
    public var totalWeeks: Int { totalDays / 7 }
    public var weeksRemaining: Int { max(0, totalWeeks - weeksLived) }

    // MARK: - 「當前」進度條

    /// 目前年齡內已經過了百分之多少（0...1），用於 WeekGridView「年模式」的當前進度條。
    public var progressOfCurrentYear: Double {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .year, value: ageYears, to: birthday),
              let end = cal.date(byAdding: .year, value: ageYears + 1, to: birthday) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    /// 當前這一週已經過了百分之多少（0...1），用於 WeekGridView「週模式」的當前進度條。
    public var progressOfCurrentWeek: Double {
        let cal = Calendar.current
        // 用「自生日起算」的週為基準，避免跟系統週起始衝突。
        guard let start = cal.date(byAdding: .day, value: weeksLived * 7, to: birthday) else { return 0 }
        let elapsed = now.timeIntervalSince(start)
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60
        return min(1.0, max(0.0, elapsed / weekSeconds))
    }

    // MARK: - 「還有幾次」

    public var newYearsLeft: Int { yearsRemaining }
    public var summersLeft: Int { yearsRemaining }
    public var tripsLeft: Int { yearsRemaining }
    public var parentVisitsLeft: Int { yearsRemaining * 12 }
    public var booksLeft: Int { yearsRemaining * 12 }

    // MARK: - 字串
    public var percentString: String {
        "\(Int((percentUsed * 100).rounded()))%"
    }
}

// MARK: - Loader
// 從 App Group UserDefaults 把資料讀出來，回傳一個 LifeMetrics。
public extension LifeMetrics {
    static func loadFromShared() -> LifeMetrics {
        let defaults = UserDefaults.shared
        let birthday: Date = {
            if let d = defaults.object(forKey: AppConstants.Key.birthday) as? Date { return d }
            // Fallback：30 歲
            return Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        }()
        let raw = defaults.integer(forKey: AppConstants.Key.lifeExpectancy)
        let life = raw == 0 ? 80 : raw
        return LifeMetrics(birthday: birthday, lifeExpectancy: life)
    }
}
