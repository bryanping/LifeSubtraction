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
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroup) ?? .standard
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
        guard let start = cal.date(byAdding: .year, value: ageYears, to: birthday),
              let end = cal.date(byAdding: .year, value: ageYears + 1, to: birthday) else { return 0 }
        let total = end.timeIntervalSince(start)
        guard total > 0 else { return 0 }
        return min(1.0, max(0.0, now.timeIntervalSince(start) / total))
    }

    public var progressOfCurrentWeek: Double {
        let cal = Calendar.current
        guard let start = cal.date(byAdding: .day, value: weeksLived * 7, to: birthday) else { return 0 }
        let elapsed = now.timeIntervalSince(start)
        let weekSeconds: TimeInterval = 7 * 24 * 60 * 60
        return min(1.0, max(0.0, elapsed / weekSeconds))
    }

    public var newYearsLeft: Int { yearsRemaining }
    public var summersLeft: Int { yearsRemaining }
    public var tripsLeft: Int { yearsRemaining }
    public var parentVisitsLeft: Int { yearsRemaining * 12 }
    public var booksLeft: Int { yearsRemaining * 12 }

    public var percentString: String {
        "\(Int((percentUsed * 100).rounded()))%"
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
