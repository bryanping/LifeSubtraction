import Foundation

// 修改内容
// 人生對齊：今天的行動是否接近你想成為的人。
enum LifeAlignmentLevel: String, Codable, CaseIterable, Identifiable {
    case stronglyAligned
    case somewhatAligned
    case notAligned

    var id: String { rawValue }

    var label: String {
        switch self {
        case .stronglyAligned: return "高度對齊"
        case .somewhatAligned: return "有點對齊"
        case .notAligned:      return "沒有對齊"
        }
    }

    var displayName: String {
        label
    }

    var emoji: String {
        switch self {
        case .stronglyAligned: return "✨"
        case .somewhatAligned: return "🌤"
        case .notAligned:      return "🌧"
        }
    }
}

struct LifeAlignmentRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var level: LifeAlignmentLevel
}
