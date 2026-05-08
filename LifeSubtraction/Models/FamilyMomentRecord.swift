import Foundation

// 修改内容 — 家人互動記錄類型
enum FamilyMomentType: String, Codable, CaseIterable, Identifiable {
    case visit
    case phoneCall
    case meal
    case trip
    case message
    case gift
    case custom

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .visit:     return "見面"
        case .phoneCall: return "通話"
        case .meal:      return "吃飯"
        case .trip:      return "旅行"
        case .message:   return "訊息"
        case .gift:      return "送禮"
        case .custom:    return "其他"
        }
    }

    var iconName: String {
        switch self {
        case .visit:     return "person.2.fill"
        case .phoneCall: return "phone.fill"
        case .meal:      return "fork.knife"
        case .trip:      return "airplane"
        case .message:   return "message.fill"
        case .gift:      return "gift.fill"
        case .custom:    return "star.fill"
        }
    }
}

// 修改内容 — 家人互動記錄模型
struct FamilyMomentRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var familyMemberId: UUID
    var type: FamilyMomentType
    var date: Date
    var note: String
    var createdAt: Date
}
