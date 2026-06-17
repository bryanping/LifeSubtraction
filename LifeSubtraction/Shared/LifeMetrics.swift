import Foundation

// MARK: - LifeMetrics
// 純值型別。給定生日 + 預期壽命，就能計算所有 UI 需要的衍生數據。
// 主 App / Widget / Watch 三邊共用，避免重複邏輯。

public struct LifeMetrics: Equatable, Sendable {
    public let birthday: Date
    public let lifeExpectancy: Int
    public let now: Date

    private var calendar: Calendar { Calendar.current }

    public init(birthday: Date, lifeExpectancy: Int, now: Date = Date()) {
        self.birthday = birthday
        self.lifeExpectancy = lifeExpectancy
        self.now = now
    }

    // MARK: - 預期終點

    /// 依生日 + 預期壽命推算的人生終點（不含閏年誤差修正，與 totalDays 一致）。
    public var expectedEndDate: Date {
        calendar.date(byAdding: .year, value: lifeExpectancy, to: birthday) ?? now
    }

    /// 距離預期終點的剩餘秒數（連續、可驅動翻牌動畫）。
    public var secondsRemaining: Double {
        max(0, expectedEndDate.timeIntervalSince(now))
    }

    // MARK: - 基礎天數

    public var daysLived: Int {
        max(0, calendar.dateComponents([.day], from: birthday, to: now).day ?? 0)
    }

    public var totalDays: Int { Int(Double(lifeExpectancy) * 365.25) }

    public var daysRemaining: Int {
        max(0, Int(secondsRemaining / 86_400))
    }

    public var percentUsed: Double {
        guard totalDays > 0 else { return 0 }
        return min(1.0, Double(daysLived) / Double(totalDays))
    }

    public var percentRemaining: Double { 1.0 - percentUsed }

    // MARK: - 精確剩餘（連續）

    public var yearsRemainingPrecise: Double {
        secondsRemaining / (365.25 * 86_400)
    }

    public var monthsRemainingPrecise: Double {
        secondsRemaining / ((365.25 / 12) * 86_400)
    }

    public var weeksRemainingPrecise: Double {
        secondsRemaining / (7 * 86_400)
    }

    public var hoursRemaining: Double {
        secondsRemaining / 3_600
    }

    public var minutesRemaining: Double {
        secondsRemaining / 60
    }

    // MARK: - 年齡

    public var ageYears: Int {
        max(0, calendar.dateComponents([.year], from: birthday, to: now).year ?? 0)
    }

    public var yearsRemaining: Int { max(0, lifeExpectancy - ageYears) }

    // MARK: - 週

    public var weeksLived: Int { daysLived / 7 }
    public var totalWeeks: Int { totalDays / 7 }
    public var weeksRemaining: Int { max(0, totalWeeks - weeksLived) }

    // MARK: - 當前節奏進度（0...1，依日曆年月週日計算）

    public var progressOfCurrentYear: Double {
        guard let interval = calendar.dateInterval(of: .year, for: now) else { return 0 }
        let total = interval.end.timeIntervalSince(interval.start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(interval.start) / total))
    }

    public var progressOfCurrentWeek: Double {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let total = interval.end.timeIntervalSince(interval.start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(interval.start) / total))
    }

    public var progressOfCurrentMonth: Double {
        let components = calendar.dateComponents([.year, .month], from: now)
        guard
            let start = calendar.date(from: components),
            let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    public var progressOfCurrentDay: Double {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    /// 本月已過天數（連續，含小數）。
    public var daysElapsedThisMonth: Double {
        let components = calendar.dateComponents([.year, .month], from: now)
        guard let start = calendar.date(from: components) else { return 0 }
        return max(0, now.timeIntervalSince(start) / 86_400)
    }

    /// 本月總天數。
    public var daysInCurrentMonth: Int {
        let components = calendar.dateComponents([.year, .month], from: now)
        guard
            let start = calendar.date(from: components),
            let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return 30 }
        return calendar.dateComponents([.day], from: start, to: end).day ?? 30
    }

    /// 本月還剩天數（連續，含小數）。
    public var daysRemainingThisMonth: Double {
        max(0, Double(daysInCurrentMonth) - daysElapsedThisMonth)
    }

    /// 本週已過天數（連續，0…7）。
    public var daysElapsedThisWeek: Double {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return max(0, now.timeIntervalSince(interval.start) / 86_400)
    }

    /// 本週還剩天數（連續，含小數）。
    public var daysRemainingThisWeek: Double {
        max(0, 7 - daysElapsedThisWeek)
    }

    /// 今天已過多少小時（連續）。
    public var hoursElapsedToday: Double {
        let start = calendar.startOfDay(for: now)
        return max(0, now.timeIntervalSince(start) / 3_600)
    }

    /// 今天還剩多少小時（連續）。
    public var hoursRemainingToday: Double {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return max(0, end.timeIntervalSince(now) / 3_600)
    }

    // MARK: - 「還有幾次」（僅保留有獨立語意的估算）

    /// 大約還有幾次跨年（依剩餘日曆年的 Jan 1 計）。
    public var newYearsLeft: Int {
        countSeasonalOccurrences(month: 1, day: 1)
    }

    /// 大約還有幾個夏天（北半球 6–8 月，每年最多計一次）。
    public var summersLeft: Int {
        countRemainingSummers()
    }

    // MARK: - 字串

    public var percentString: String {
        "\(Int((percentUsed * 100).rounded()))%"
    }

    // MARK: - Private helpers

    private func countSeasonalOccurrences(month: Int, day: Int) -> Int {
        let startYear = calendar.component(.year, from: now)
        let endYear = calendar.component(.year, from: expectedEndDate)
        guard startYear <= endYear else { return 0 }

        var count = 0
        for year in startYear...endYear {
            var components = DateComponents(year: year, month: month, day: day)
            guard let candidate = calendar.date(from: components) else { continue }
            if candidate >= calendar.startOfDay(for: now), candidate <= expectedEndDate {
                count += 1
            }
        }
        return count
    }

    private func countRemainingSummers() -> Int {
        let startYear = calendar.component(.year, from: now)
        let endYear = calendar.component(.year, from: expectedEndDate)
        guard startYear <= endYear else { return 0 }

        var count = 0
        for year in startYear...endYear {
            var june = DateComponents(year: year, month: 6, day: 1)
            var august = DateComponents(year: year, month: 8, day: 31)
            guard
                let summerStart = calendar.date(from: june),
                let summerEnd = calendar.date(from: august)
            else { continue }

            let windowStart = max(summerStart, calendar.startOfDay(for: now))
            let windowEnd = min(summerEnd, expectedEndDate)
            if windowStart <= windowEnd { count += 1 }
        }
        return count
    }
}

// MARK: - Loader

public extension LifeMetrics {
    static func loadFromShared() -> LifeMetrics {
        let defaults = UserDefaults.shared
        let birthday: Date = {
            if let d = defaults.object(forKey: AppConstants.Key.birthday) as? Date { return d }
            return Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
        }()
        let raw = defaults.integer(forKey: AppConstants.Key.lifeExpectancy)
        let life = raw == 0 ? 80 : raw
        return LifeMetrics(birthday: birthday, lifeExpectancy: life)
    }
}
