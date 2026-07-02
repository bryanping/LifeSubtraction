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

    /// 今年還剩天數（連續，含小數）。
    public var daysRemainingThisYear: Double {
        let year = calendar.component(.year, from: now)
        guard let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1)) else { return 0 }
        return max(0, end.timeIntervalSince(now) / 86_400)
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

    // MARK: - 碼錶圓環（yy.mm.dd = 人生；外圈 / hh:mm:ss.s = 當日）

    private var lifeDaysPrecise: Double {
        var remaining = secondsRemaining
        let yearSec = 365.25 * 86_400
        let monthSec = yearSec / 12
        let daySec = 86_400.0

        let yy = min(99, Int(remaining / yearSec))
        remaining -= Double(yy) * yearSec
        let mm = min(99, Int(remaining / monthSec))
        remaining -= Double(mm) * monthSec
        return max(0, remaining / daySec)
    }

    /// 外圈：當日剩餘時間（24 進制，依 Calendar.current 裝置時區）。
    public var todayHoursRingFraction: Double {
        max(0, min(1, hoursRemainingToday / 24))
    }

    /// 第二圈：人生剩餘「日」（31 進制，綠）。
    public var lifeDaysRingFraction: Double {
        max(0, min(1, lifeDaysPrecise / 31))
    }

    /// 第三圈：人生剩餘「月」（12 進制，藍）。
    public var lifeMonthsRingFraction: Double {
        let c = lifeDateComponents
        let monthPrecise = Double(c.months) + lifeDaysPrecise / 31
        return max(0, min(1, monthPrecise / 12))
    }

    /// 內圈：人生剩餘「年」（預期壽命刻度，粉）。
    public var lifeYearsRingFraction: Double {
        let c = lifeDateComponents
        let monthPrecise = Double(c.months) + lifeDaysPrecise / 31
        let yearPrecise = Double(c.years) + monthPrecise / 12
        return max(0, min(1, yearPrecise / Double(max(1, lifeExpectancy))))
    }

    /// 中心百分比：人生總剩餘比例。
    public var lifeRemainingFraction: Double {
        max(0, min(1, percentRemaining))
    }

    /// 人生剩餘：年、月、日（對應 yy.mm.dd）。
    public var lifeDateComponents: (years: Int, months: Int, days: Int) {
        var remaining = secondsRemaining

        let yearSec = 365.25 * 86_400
        let monthSec = yearSec / 12
        let daySec = 86_400.0

        let yy = min(99, Int(remaining / yearSec))
        remaining -= Double(yy) * yearSec

        let mm = min(99, Int(remaining / monthSec))
        remaining -= Double(mm) * monthSec

        let dd = min(31, Int(remaining / daySec))
        return (yy, mm, dd)
    }

    /// 當日剩餘：時、分、秒、十分之一秒（對應 hh:mm:ss.s，裝置時區）。
    public var todayTimeComponents: (hours: Int, minutes: Int, seconds: Int, tenth: Int) {
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return (0, 0, 0, 0)
        }
        var remaining = max(0, end.timeIntervalSince(now))

        let hh = Int(remaining / 3_600)
        remaining -= Double(hh) * 3_600

        let mi = Int(remaining / 60)
        remaining -= Double(mi) * 60

        let ss = Int(remaining)
        remaining -= Double(ss)

        let tenth = min(9, max(0, Int(remaining * 10)))
        return (hh, mi, ss, tenth)
    }

    /// 今年剩餘月數（連續，含小數）。
    public var monthsRemainingThisYear: Double {
        max(0, (1 - progressOfCurrentYear) * 12)
    }

    /// 場記板完整讀數：yy.mm.dd.hh:mm:ss.s（人生 + 當日）
    public var filmTimecodeString: String {
        let d = lifeDateComponents
        let t = todayTimeComponents
        return String(
            format: "%02d.%02d.%02d.%02d:%02d:%02d.%d",
            d.years, d.months, d.days, t.hours, t.minutes, t.seconds, t.tenth
        )
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
