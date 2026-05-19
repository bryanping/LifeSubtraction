import Foundation

// 修改内容
// 「你還有幾次？」單次紀錄。記錄一次完成的有意義時刻。
struct RemainingMomentRecord: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var itemId: UUID
    var date: Date = Date()
    var note: String = ""
}
