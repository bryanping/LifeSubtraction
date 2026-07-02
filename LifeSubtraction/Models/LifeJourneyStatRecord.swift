import Foundation

/// 人生累積的真實紀錄（由倒數「新增一次」或手動累加）。
struct LifeJourneyStatRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var statItemId: UUID
    var date: Date
    var note: String

    init(
        id: UUID = UUID(),
        statItemId: UUID,
        date: Date = Date(),
        note: String = ""
    ) {
        self.id = id
        self.statItemId = statItemId
        self.date = date
        self.note = note
    }
}

enum JourneyStatCalculator {
    static func filteredRecords(for itemId: UUID, in allRecords: [LifeJourneyStatRecord]) -> [LifeJourneyStatRecord] {
        allRecords.filter { $0.statItemId == itemId }
    }

    static func loggedCount(for itemId: UUID, in allRecords: [LifeJourneyStatRecord]) -> Int {
        filteredRecords(for: itemId, in: allRecords).count
    }

    static func totalCount(item: LifeJourneyStatItem, records allRecords: [LifeJourneyStatRecord]) -> Int {
        item.baselineEstimate + loggedCount(for: item.id, in: allRecords)
    }

    static func count(in interval: DateInterval, itemId: UUID, records allRecords: [LifeJourneyStatRecord]) -> Int {
        filteredRecords(for: itemId, in: allRecords).filter { interval.contains($0.date) }.count
    }

    static func thisMonthCount(itemId: UUID, records allRecords: [LifeJourneyStatRecord], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let end = calendar.date(byAdding: .month, value: 1, to: start)
        else { return 0 }
        return count(in: DateInterval(start: start, end: end), itemId: itemId, records: allRecords)
    }

    static func lastMonthCount(itemId: UUID, records allRecords: [LifeJourneyStatRecord], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)
        else { return 0 }
        return count(in: DateInterval(start: start, end: thisMonthStart), itemId: itemId, records: allRecords)
    }

    // 修改内容 — 年度累積（修正「年度回顧」原本錯誤顯示本月數據的問題）
    static func thisYearCount(itemId: UUID, records allRecords: [LifeJourneyStatRecord], now: Date = Date()) -> Int {
        let calendar = Calendar.current
        guard
            let start = calendar.date(from: calendar.dateComponents([.year], from: now)),
            let end = calendar.date(byAdding: .year, value: 1, to: start)
        else { return 0 }
        return count(in: DateInterval(start: start, end: end), itemId: itemId, records: allRecords)
    }
}
