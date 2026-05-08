import Foundation

// 修改内容 — 「你還有幾次」頻率選項
enum MomentFrequency: String, Codable, CaseIterable, Identifiable {
    case yearly
    case quarterly
    case monthly
    case biweekly
    case weekly

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yearly:    return "每年一次"
        case .quarterly: return "每季一次"
        case .monthly:   return "每月一次"
        case .biweekly:  return "每兩週一次"
        case .weekly:    return "每週一次"
        }
    }

    var timesPerYear: Int {
        switch self {
        case .yearly:    return 1
        case .quarterly: return 4
        case .monthly:   return 12
        case .biweekly:  return 26
        case .weekly:    return 52
        }
    }
}

// 修改内容 — 「你還有幾次」項目，可選擇關聯家人
struct RemainingMomentItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var icon: String
    var frequency: MomentFrequency
    var linkedFamilyMemberId: UUID?
    var createdAt: Date
    var isArchived: Bool

    // 修改内容 — 若有關聯家人，用家人剩餘年數計算；否則用使用者自己的
    func remainingCount(userYearsRemaining: Int, familyMembers: [FamilyMember]) -> Int {
        let years: Int
        if let memberId = linkedFamilyMemberId,
           let member = familyMembers.first(where: { $0.id == memberId && !$0.isArchived }) {
            years = member.yearsRemaining
        } else {
            years = userYearsRemaining
        }
        return years * frequency.timesPerYear
    }
}

// 修改内容 — 預設項目（首次啟動時自動寫入）
extension RemainingMomentItem {
    static var defaults: [RemainingMomentItem] {
        let now = Date()
        return [
            RemainingMomentItem(name: "新年", icon: "sparkles",
                                frequency: .yearly, createdAt: now, isArchived: false),
            RemainingMomentItem(name: "出國旅行", icon: "airplane",
                                frequency: .yearly, createdAt: now, isArchived: false),
            RemainingMomentItem(name: "讀一本書", icon: "book",
                                frequency: .monthly, createdAt: now, isArchived: false),
            RemainingMomentItem(name: "夏天", icon: "sun.max",
                                frequency: .yearly, createdAt: now, isArchived: false),
        ]
    }
}

// 修改内容 — 可供用戶選擇的圖示清單
extension RemainingMomentItem {
    static let availableIcons: [String] = [
        "heart.fill", "airplane", "book", "sun.max", "sparkles",
        "fork.knife", "person.2.fill", "house.fill", "gift.fill", "music.note",
        "camera.fill", "car.fill", "dumbbell.fill", "leaf.fill", "moon.fill",
        "phone.fill", "graduationcap.fill", "figure.hiking", "dog.fill", "star.fill",
    ]
}
