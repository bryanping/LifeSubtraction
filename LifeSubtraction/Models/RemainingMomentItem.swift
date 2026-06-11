import Foundation

// 修改内容
// 「你還有幾次？」自定項目模型。

enum RemainingMomentFrequency: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily:   return "每日"
        case .weekly:  return "每週"
        case .monthly: return "每月"
        case .yearly:  return "每年"
        case .custom:  return "自訂"
        }
    }

    /// 一年大約幾次（custom 由 item 自帶值）。
    var defaultTimesPerYear: Int {
        switch self {
        case .daily:   return 365
        case .weekly:  return 52
        case .monthly: return 12
        case .yearly:  return 1
        case .custom:  return 0
        }
    }
}

// 修改内容 — 計算依賴對象。決定「剩餘年數」要套誰。
enum RemainingMomentDependency: String, Codable, CaseIterable, Identifiable {
    case selfLife   // 我的剩餘人生（預設）
    case parents    // 父母的剩餘人生（取與我較短者）

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .selfLife: return "我的剩餘人生"
        case .parents:  return "父母剩餘人生"
        }
    }

    var hint: String {
        switch self {
        case .selfLife: return "依你預期的壽命估算"
        case .parents:  return "依父母預期壽命估算（取與你較短者）"
        }
    }
}

struct RemainingMomentItem: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var iconName: String
    var unit: String
    var frequency: RemainingMomentFrequency
    var customTimesPerYear: Int?
    var createdAt: Date
    var isArchived: Bool
    var dependsOn: RemainingMomentDependency        // 修改内容

    init(
        id: UUID = UUID(),
        title: String,
        iconName: String,
        unit: String,
        frequency: RemainingMomentFrequency,
        customTimesPerYear: Int? = nil,
        createdAt: Date = Date(),
        isArchived: Bool = false,
        dependsOn: RemainingMomentDependency = .selfLife   // 修改内容
    ) {
        self.id = id
        self.title = title
        self.iconName = iconName
        self.unit = unit
        self.frequency = frequency
        self.customTimesPerYear = customTimesPerYear
        self.createdAt = createdAt
        self.isArchived = isArchived
        self.dependsOn = dependsOn
    }

    // 修改内容 — 後向相容：舊 JSON 沒有 dependsOn / createdAt 等欄位時帶預設值
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.title = try c.decode(String.self, forKey: .title)
        self.iconName = try c.decode(String.self, forKey: .iconName)
        self.unit = try c.decode(String.self, forKey: .unit)
        self.frequency = try c.decode(RemainingMomentFrequency.self, forKey: .frequency)
        self.customTimesPerYear = try c.decodeIfPresent(Int.self, forKey: .customTimesPerYear)
        self.createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.isArchived = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        self.dependsOn = try c.decodeIfPresent(RemainingMomentDependency.self, forKey: .dependsOn) ?? .selfLife
    }

    enum CodingKeys: String, CodingKey {
        case id, title, iconName, unit, frequency, customTimesPerYear, createdAt, isArchived, dependsOn
    }

    /// 一年估算次數（含 custom）
    func estimatedTimesPerYear() -> Int {
        switch frequency {
        case .custom: return max(0, customTimesPerYear ?? 0)
        default:      return frequency.defaultTimesPerYear
        }
    }
}

// 修改内容 — 第一次啟動時的預設項目，沿用原本的固定列。
// 注意：「探望父母」的 dependsOn 改為 .parents，避免被算成自己的剩餘年數。
extension RemainingMomentItem {
    static let defaults: [RemainingMomentItem] = []

    // 修改内容 — 舊資料遷移：標題含「父母」且 dependsOn 還是 .selfLife 時自動修正。
    /// 對一陣列做就地遷移，回傳是否有變動。
    static func migrateLegacyParentDependency(_ items: inout [RemainingMomentItem]) -> Bool {
        var changed = false
        for i in items.indices {
            if items[i].title.contains("父母") && items[i].dependsOn == .selfLife {
                items[i].dependsOn = .parents
                changed = true
            }
        }
        return changed
    }
}
