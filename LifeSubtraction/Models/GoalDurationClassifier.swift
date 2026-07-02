import Foundation

// MARK: - GoalDurationClass

enum GoalDurationClass: String, CaseIterable {
    case day   = "day"
    case month = "month"
    case year  = "year"

    var label: String {
        switch self {
        case .day:   return "今日可完成"
        case .month: return "一個月内"
        case .year:  return "今年可完成"
        }
    }

    var subLabel: String {
        switch self {
        case .day:   return "幾小時即可"
        case .month: return "幾天到幾週"
        case .year:  return "幾個月時間"
        }
    }

    var iconName: String {
        switch self {
        case .day:   return "sun.max.fill"
        case .month: return "calendar"
        case .year:  return "star.fill"
        }
    }
}

// MARK: - GoalDurationClassifier

enum GoalDurationClassifier {

    private static let dayIds: Set<String> = [
        "f02", "f04", "f05", "f09", "f10", "f11",
        "e04", "e07", "e10",
        "r01", "r04", "r07", "r08", "r11",
        "b02", "b03", "b07", "b12", "b13",
        "h01", "g11",
    ]

    private static let monthIds: Set<String> = [
        "f01", "f03", "f06", "f07", "f08", "f12", "f13",
        "g01", "g06", "g07", "g09", "g10", "g13",
        "h04", "h05", "h06", "h07", "h08", "h09", "h11", "h12",
        "e03", "e06", "e08", "e11", "e12", "e13",
        "c01", "c03", "c04", "c05", "c06", "c07", "c08", "c09", "c12",
        "r02", "r03", "r05", "r06", "r09", "r10", "r12",
        "b01", "b04", "b05", "b06", "b08", "b09", "b10", "b11",
    ]

    static func classify(id: String) -> GoalDurationClass {
        if dayIds.contains(id) { return .day }
        if monthIds.contains(id) { return .month }
        return .year
    }

    /// 所有符合條件的推薦（排除已加入），供分頁刷新使用
    static func allRecommendations(
        for duration: GoalDurationClass,
        existingCatalogIds: Set<String>
    ) -> [GoalCatalogEntry] {
        GoalCatalog.all
            .filter { classify(id: $0.id) == duration && !existingCatalogIds.contains($0.id) }
    }

    /// 取一批（預設3筆），支援 batch offset 換一批
    static func recommendations(
        for duration: GoalDurationClass,
        existingCatalogIds: Set<String>,
        batch: Int = 0,
        pageSize: Int = 3
    ) -> [GoalCatalogEntry] {
        let all = allRecommendations(for: duration, existingCatalogIds: existingCatalogIds)
        guard !all.isEmpty else { return [] }
        let start = (batch * pageSize) % all.count
        let slice = all.dropFirst(start).prefix(pageSize)
        // 不足補頭部
        if slice.count < pageSize && all.count > pageSize {
            return Array(slice) + Array(all.prefix(pageSize - slice.count))
        }
        return Array(slice)
    }
}
