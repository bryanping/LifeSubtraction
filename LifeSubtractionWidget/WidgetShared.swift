//
//  WidgetShared.swift
//  LifeSubtractionWidget
//
//  Widget Extension 自帶的共享型別。
//  ⚠️ 與 LifeSubtraction/Shared/{AppConstants,LifeMetrics,LifeTheme}.swift 內容必須同步維護。
//
//  Why duplicate? 因為 Xcode 的 synchronized folder 是「一個資料夾 → 一個 target」綁定的，
//  跨 target 共享 Swift 檔需要手動 Target Membership 操作。
//  把 ~150 行通用程式直接複製進來，省掉所有設定步驟，build 一次過。
//

import Foundation
import SwiftUI

// MARK: - App Group 共享常數

enum AppConstants {
    /// App Group identifier — 主 App 與 Widget 必須在 Capabilities 中
    /// 都加入並勾選同一個 group，數值與此處字串一字不差。
    static let appGroup = "group.com.yourname.lifesubtraction"

    enum Key {
        static let birthday = "birthday"
        static let lifeExpectancy = "lifeExpectancy"
        static let onboarded = "onboarded"
        static let values = "values"
        static let isPremium = "isPremium"
        static let familyMembers = "family-members"
        static let familyMomentRecords = "family-moment-records"
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroup) ?? .standard
    }
}

extension DateFormatter {
    static func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - LifeMetrics

public struct LifeMetrics: Equatable, Sendable {
    public let birthday: Date
    public let lifeExpectancy: Int
    public let now: Date

    public init(birthday: Date, lifeExpectancy: Int, now: Date = Date()) {
        self.birthday = birthday
        self.lifeExpectancy = lifeExpectancy
        self.now = now
    }

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

    public var ageYears: Int {
        max(0, Calendar.current.dateComponents([.year], from: birthday, to: now).year ?? 0)
    }
    public var yearsRemaining: Int { max(0, lifeExpectancy - ageYears) }

    public var weeksLived: Int { daysLived / 7 }
    public var totalWeeks: Int { totalDays / 7 }
    public var weeksRemaining: Int { max(0, totalWeeks - weeksLived) }

    public var progressOfCurrentYear: Double {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .year, for: now) else { return 0 }
        let total = interval.end.timeIntervalSince(interval.start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(interval.start) / total))
    }

    public var progressOfCurrentWeek: Double {
        let cal = Calendar.current
        guard let interval = cal.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        let total = interval.end.timeIntervalSince(interval.start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(interval.start) / total))
    }

    public var progressOfCurrentMonth: Double {
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: now)
        guard
            let start = cal.date(from: components),
            let end = cal.date(byAdding: .month, value: 1, to: start)
        else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    public var progressOfCurrentDay: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    public var hoursElapsedToday: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        return max(0, now.timeIntervalSince(start) / 3_600)
    }

    public var expectedEndDate: Date {
        Calendar.current.date(byAdding: .year, value: lifeExpectancy, to: birthday) ?? now
    }

    public var secondsRemaining: Double {
        max(0, expectedEndDate.timeIntervalSince(now))
    }

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

    public var hoursRemainingToday: Double {
        let cal = Calendar.current
        let start = cal.startOfDay(for: now)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return max(0, end.timeIntervalSince(now) / 3_600)
    }

    public var newYearsLeft: Int {
        countSeasonalOccurrences(month: 1, day: 1)
    }

    public var summersLeft: Int {
        countRemainingSummers()
    }

    public var percentString: String {
        "\(Int((percentUsed * 100).rounded()))%"
    }

    private func countSeasonalOccurrences(month: Int, day: Int) -> Int {
        let cal = Calendar.current
        let startYear = cal.component(.year, from: now)
        let endYear = cal.component(.year, from: expectedEndDate)
        guard startYear <= endYear else { return 0 }

        var count = 0
        for year in startYear...endYear {
            var components = DateComponents(year: year, month: month, day: day)
            guard let candidate = cal.date(from: components) else { continue }
            if candidate >= cal.startOfDay(for: now), candidate <= expectedEndDate {
                count += 1
            }
        }
        return count
    }

    private func countRemainingSummers() -> Int {
        let cal = Calendar.current
        let startYear = cal.component(.year, from: now)
        let endYear = cal.component(.year, from: expectedEndDate)
        guard startYear <= endYear else { return 0 }

        var count = 0
        for year in startYear...endYear {
            let june = DateComponents(year: year, month: 6, day: 1)
            let august = DateComponents(year: year, month: 8, day: 31)
            guard
                let summerStart = cal.date(from: june),
                let summerEnd = cal.date(from: august)
            else { continue }

            let windowStart = max(summerStart, cal.startOfDay(for: now))
            let windowEnd = min(summerEnd, expectedEndDate)
            if windowStart <= windowEnd { count += 1 }
        }
        return count
    }

    public static func loadFromShared() -> LifeMetrics {
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

// MARK: - LifeTheme  // modified — 與主 App 同步：teal → blue 暗色系

public enum LifeTheme {
    // 背景  // modified
    public static let background      = Color(red: 0.04, green: 0.06, blue: 0.10)
    public static let backgroundDeep  = Color(red: 0.02, green: 0.03, blue: 0.07)

    // 文字 token  // modified
    public static let textPrimary    = Color.white
    public static let textSecondary  = Color.white.opacity(0.70)
    public static let textTertiary   = Color.white.opacity(0.40)
    public static let textQuaternary = Color.white.opacity(0.20)

    // 強調色 teal → blue  // modified
    public static let accent      = Color(red: 0.20, green: 0.85, blue: 0.80)
    public static let accentEnd   = Color(red: 0.30, green: 0.55, blue: 0.95)
    public static let accentSoft  = Color(red: 0.20, green: 0.85, blue: 0.80).opacity(0.18)
    public static let accentMuted = Color(red: 0.20, green: 0.85, blue: 0.80).opacity(0.32)

    // 暖色，僅用於今天/當前/急迫  // modified
    public static let warm        = Color(red: 1.00, green: 0.62, blue: 0.36)
    public static let warmSoft    = Color(red: 1.00, green: 0.62, blue: 0.36).opacity(0.18)

    public static let glassFill   = Color.white.opacity(0.05)
    public static let glassBorder = Color.white.opacity(0.08)

    public static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentEnd],                                     // // modified
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }
    public static var subtleBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.13),
                Color(red: 0.02, green: 0.03, blue: 0.07)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }
    public static var progressGradient: LinearGradient {
        LinearGradient(colors: [accent, accentEnd], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Widget helpers

private struct WidgetFamilyMember: Codable {
    var id: UUID
    var name: String
    var isArchived: Bool
}

private struct WidgetFamilyMomentRecord: Codable {
    var familyMemberId: UUID
    var date: Date
}

private struct WidgetReflectionEntry: Codable {
    var date: Date
    var text: String
}

enum WidgetDataLoader {
    static var isPremium: Bool {
        UserDefaults.shared.bool(forKey: AppConstants.Key.isPremium)
    }

    static func dailyReflectionPrompt() -> String {
        let fallback = "今天，你做了什麼讓未來的你感謝的事？"
        guard
            let data = UserDefaults.shared.data(forKey: "reflection-entries"),
            let entries = try? JSONDecoder().decode([WidgetReflectionEntry].self, from: data)
        else {
            return fallback
        }

        let todayKey = DateFormatter.dateKey(for: Date())
        if let entry = entries.first(where: {
            DateFormatter.dateKey(for: $0.date) == todayKey &&
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }) {
            return entry.text
        }
        return fallback
    }

    static func longestNotContactedFamilyMember() -> (name: String, days: Int)? {
        let decoder = JSONDecoder()
        guard
            let membersData = UserDefaults.shared.data(forKey: AppConstants.Key.familyMembers),
            let members = try? decoder.decode([WidgetFamilyMember].self, from: membersData)
        else {
            return nil
        }

        let activeMembers = members.filter { !$0.isArchived }
        guard !activeMembers.isEmpty else { return nil }

        let records: [WidgetFamilyMomentRecord]
        if let recordsData = UserDefaults.shared.data(forKey: AppConstants.Key.familyMomentRecords),
           let decoded = try? decoder.decode([WidgetFamilyMomentRecord].self, from: recordsData) {
            records = decoded
        } else {
            records = []
        }

        let calendar = Calendar.current
        return activeMembers
            .map { member in
                let latestDate = records
                    .filter { $0.familyMemberId == member.id }
                    .map(\.date)
                    .max()
                let days = latestDate.map {
                    max(0, calendar.dateComponents([.day], from: $0, to: Date()).day ?? 0)
                } ?? 999
                return (name: member.name, days: days)
            }
            .max { $0.days < $1.days }
    }
}

struct WidgetLockedView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "lock.fill")
                .foregroundStyle(LifeTheme.warm)
            Text("完整版功能")
                .font(.subheadline)
                .foregroundStyle(LifeTheme.textPrimary)
            Text("開啟 app 解鎖")
                .font(.caption)
                .foregroundStyle(LifeTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
