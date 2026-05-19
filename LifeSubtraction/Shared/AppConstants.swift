import Foundation

// MARK: - Shared Constants
// 主 App / Widget Extension / watchOS App 三個 target 都會用到。
// 在 Xcode 中三個 target 都要加上同一個 App Group 才能共享 UserDefaults。

enum AppConstants {
    /// App Group identifier — 三個 target 的 Signing & Capabilities → App Groups
    /// 都要勾選同一個。請依你的 Bundle ID 更新此值。
    static let appGroup = "group.com.yourname.lifesubtraction"

    /// 共享 UserDefaults 的 keys
    enum Key {
        static let birthday = "birthday"
        static let lifeExpectancy = "lifeExpectancy"
        static let onboarded = "onboarded"
        static let values = "values"
        static let isPremium = "isPremium"
        // 修改内容 — 家人系統
        static let familyMembers = "family-members"
        static let familyMomentRecords = "family-moment-records"
    }
}

// MARK: - Shared UserDefaults helper
extension UserDefaults {
    /// App Group 共享的 UserDefaults，若失敗則 fallback 到 .standard。
    static var shared: UserDefaults {
        UserDefaults(suiteName: AppConstants.appGroup) ?? .standard
    }
}
