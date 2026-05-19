import Foundation

/// 「人生累積」自定項目：標題、圖示、數據來源（自動或手動）。
enum LifeJourneyStatMetricKind: String, Codable, CaseIterable, Identifiable {
    case daysLived
    case weekendsLived
    case birthdays
    case seasons
    case yearsLived
    case monthsLived
    case daysThisYear
    case manual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daysLived:       return "已活天數"
        case .weekendsLived:   return "已經歷週末"
        case .birthdays:       return "已過生日"
        case .seasons:         return "春夏秋冬"
        case .yearsLived:      return "已活年數"
        case .monthsLived:     return "已活月數"
        case .daysThisYear:    return "今年已走過"
        case .manual:          return "手動記錄"
        }
    }

    var hint: String {
        switch self {
        case .daysLived:       return "依生日自動計算至今的天數"
        case .weekendsLived:   return "依已活天數估算經歷的週末"
        case .birthdays:       return "依年齡計算已慶祝的生日次數"
        case .seasons:         return "依年齡計算經歷的四季輪迴"
        case .yearsLived:      return "依生日自動計算整歲年數"
        case .monthsLived:     return "依生日自動計算經歷的月份"
        case .daysThisYear:    return "今年 1 月 1 日起至今的天數"
        case .manual:          return "自行輸入並維護數字，適合旅行次數等"
        }
    }

    var defaultUnit: String {
        switch self {
        case .daysLived, .daysThisYear: return "天"
        case .weekendsLived:            return "個"
        case .birthdays:                return "次"
        case .seasons:                  return "輪"
        case .yearsLived:               return "歲"
        case .monthsLived:              return "個月"
        case .manual:                   return "次"
        }
    }
}

struct LifeJourneyStatItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var iconName: String
    var metricKind: LifeJourneyStatMetricKind
    var unit: String
    var manualValue: Int?
    var createdAt: Date
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String,
        metricKind: LifeJourneyStatMetricKind,
        unit: String? = nil,
        manualValue: Int? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.metricKind = metricKind
        self.unit = unit ?? metricKind.defaultUnit
        self.manualValue = manualValue
        self.createdAt = createdAt
        self.isArchived = isArchived
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        iconName = try c.decode(String.self, forKey: .iconName)
        metricKind = try c.decode(LifeJourneyStatMetricKind.self, forKey: .metricKind)
        unit = try c.decodeIfPresent(String.self, forKey: .unit) ?? metricKind.defaultUnit
        manualValue = try c.decodeIfPresent(Int.self, forKey: .manualValue)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    enum CodingKeys: String, CodingKey {
        case id, title, iconName, metricKind, unit, manualValue, createdAt, isArchived
    }
}

extension LifeJourneyStatItem {
    static let defaults: [LifeJourneyStatItem] = [
        LifeJourneyStatItem(
            title: "已活天數",
            iconName: "sun.max.fill",
            metricKind: .daysLived
        ),
        LifeJourneyStatItem(
            title: "已經歷週末",
            iconName: "calendar",
            metricKind: .weekendsLived
        ),
        LifeJourneyStatItem(
            title: "已過生日",
            iconName: "gift.fill",
            metricKind: .birthdays
        ),
        LifeJourneyStatItem(
            title: "春夏秋冬",
            iconName: "leaf.fill",
            metricKind: .seasons
        ),
        LifeJourneyStatItem(
            title: "今年已走過",
            iconName: "clock.fill",
            metricKind: .daysThisYear
        )
    ]
}

extension LifeJourneyStatItem {
    func resolvedValue(store: LifeStore, daysPassedThisYear: Int) -> Int {
        switch metricKind {
        case .daysLived:
            return store.daysLived
        case .weekendsLived:
            return store.weeksLived
        case .birthdays, .seasons:
            return store.ageYears
        case .yearsLived:
            return store.ageYears
        case .monthsLived:
            return monthsLived(from: store.birthday)
        case .daysThisYear:
            return daysPassedThisYear
        case .manual:
            return max(0, manualValue ?? 0)
        }
    }

    private func monthsLived(from birthday: Date) -> Int {
        max(0, Calendar.current.dateComponents([.month], from: birthday, to: Date()).month ?? 0)
    }

    func displayValue(store: LifeStore, daysPassedThisYear: Int) -> String {
        let count = resolvedValue(store: store, daysPassedThisYear: daysPassedThisYear)
        let formatted = count.formatted(.number.grouping(.automatic))
        return "\(formatted) \(unit)"
    }
}
