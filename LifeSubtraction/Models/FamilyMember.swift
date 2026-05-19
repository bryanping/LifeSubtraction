import Foundation

// 修改内容 — 家人關係類型
enum FamilyRelation: String, Codable, CaseIterable, Identifiable {
    case father
    case mother
    case parent
    case spouse
    case child
    case grandparent
    case sibling
    case friend
    case pet
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .father:      return "爸爸"
        case .mother:      return "媽媽"
        case .parent:      return "父母"
        case .spouse:      return "伴侶"
        case .child:       return "孩子"
        case .grandparent: return "祖父母"
        case .sibling:     return "兄弟姊妹"
        case .friend:      return "朋友"
        case .pet:         return "寵物"
        case .other:       return "其他"
        }
    }

    var iconName: String {
        switch self {
        case .father:      return "figure.stand"
        case .mother:      return "figure.stand.dress"
        case .parent:      return "heart.fill"
        case .spouse:      return "heart.circle.fill"
        case .child:       return "figure.child"
        case .grandparent: return "person.2.fill"
        case .sibling:     return "person.2"
        case .friend:      return "person.crop.circle"
        case .pet:         return "pawprint.fill"
        case .other:       return "person.fill"
        }
    }
}

// 修改内容 — 家人資料模型
struct FamilyMember: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var relation: FamilyRelation
    var currentAge: Int
    var lifeExpectancy: Int
    var note: String
    var createdAt: Date
    var isArchived: Bool

    // 修改内容 — 共同剩餘年數
    var yearsRemaining: Int {
        max(0, lifeExpectancy - currentAge)
    }
}
