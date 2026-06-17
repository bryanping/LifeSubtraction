import Foundation

/// 完成人生目標後產生的人生時刻／回憶。
struct LifeMoment: Identifiable, Codable, Hashable {
    var id: UUID
    var goalId: UUID
    var catalogId: String?
    var title: String
    var detailSummary: String
    var category: GoalCategory
    var notes: String
    var startDate: Date?
    var completedDate: Date
    var durationDays: Int

    init(from goal: LifeGoal) {
        self.id = UUID()
        self.goalId = goal.id
        self.catalogId = goal.catalogId
        self.title = goal.title
        self.detailSummary = goal.detailSummary
        self.category = goal.category
        self.notes = goal.notes
        self.startDate = goal.startDate
        self.completedDate = goal.completedDate ?? Date()
        self.durationDays = goal.durationDays ?? 1
    }

    enum CodingKeys: String, CodingKey {
        case id, goalId, catalogId, title, detailSummary, category, notes, startDate, completedDate, durationDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        goalId = try container.decode(UUID.self, forKey: .goalId)
        catalogId = try container.decodeIfPresent(String.self, forKey: .catalogId)
        title = try container.decode(String.self, forKey: .title)
        detailSummary = try container.decodeIfPresent(String.self, forKey: .detailSummary) ?? ""
        category = try container.decode(GoalCategory.self, forKey: .category)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        completedDate = try container.decode(Date.self, forKey: .completedDate)
        durationDays = try container.decode(Int.self, forKey: .durationDays)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(goalId, forKey: .goalId)
        try container.encodeIfPresent(catalogId, forKey: .catalogId)
        try container.encode(title, forKey: .title)
        try container.encode(detailSummary, forKey: .detailSummary)
        try container.encode(category, forKey: .category)
        try container.encode(notes, forKey: .notes)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encode(completedDate, forKey: .completedDate)
        try container.encode(durationDays, forKey: .durationDays)
    }

    var summaryLine: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy.MM.dd"
        let name = detailSummary.isEmpty ? title : "\(title)（\(detailSummary)）"
        return "\(formatter.string(from: completedDate)) · 完成了「\(name)」"
    }

    var detailBody: String {
        var parts = ["完成了", title]
        if !notes.isEmpty { parts.append(notes) }
        parts.append("共花費 \(durationDays) 天")
        return parts.joined(separator: "\n")
    }
}

enum GoalRecommender {
    static func suggestions(after goal: LifeGoal) -> [(title: String, category: GoalCategory)] {
        switch goal.category {
        case .growth:
            return [
                ("再讀一本書", .growth),
                ("學一項技能", .growth),
                ("寫一篇心得", .creation)
            ]
        case .experience:
            return [
                ("規劃下一次旅行", .experience),
                ("寫下旅行回憶", .creation),
                ("分享給重要的人", .relationship)
            ]
        case .family:
            return [
                ("再安排一次家人時光", .family),
                ("拍一張全家福", .family),
                ("寫一封感謝信", .relationship)
            ]
        case .health:
            return [
                ("保持一週運動", .health),
                ("做一次健檢", .health),
                ("嘗試新的健康習慣", .health)
            ]
        case .creation:
            return [
                ("開始下一個作品", .creation),
                ("分享你的創作", .contribution),
                ("記錄創作心得", .growth)
            ]
        case .relationship:
            return [
                ("聯絡一位老朋友", .relationship),
                ("安排一次見面", .relationship),
                ("寫下這段關係的意義", .growth)
            ]
        case .dream:
            return [
                ("為夢想邁出下一步", .dream),
                ("記錄這段旅程", .creation),
                ("感謝支持你的人", .relationship)
            ]
        case .contribution:
            return [
                ("再做一次小小的善舉", .contribution),
                ("記錄這次經驗", .growth),
                ("邀請朋友一起參與", .relationship)
            ]
        }
    }
}
