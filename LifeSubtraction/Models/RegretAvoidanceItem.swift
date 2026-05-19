import Foundation

// 修改内容
// 避免遺憾：80 歲的你，會後悔什麼沒做？
enum RegretStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted
    case inProgress
    case handled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .notStarted: return "尚未開始"
        case .inProgress: return "進行中"
        case .handled:    return "已處理"
        }
    }

    var displayName: String {
        label
    }

    var icon: String {
        switch self {
        case .notStarted: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .handled:    return "checkmark.circle.fill"
        }
    }
}

struct RegretAvoidanceItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var status: RegretStatus = .notStarted
    var createdAt: Date = Date()
}
