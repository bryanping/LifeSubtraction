import Foundation

// 修改内容
// 人生目標：使用者真正想完成的事。MVP 版本以 progress 0...1 表達進度。
struct LifeGoal: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var note: String = ""
    var progress: Double = 0          // 0...1
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date? = nil
}
