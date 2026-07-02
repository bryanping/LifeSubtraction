import Foundation

// 修改内容 — 取代估算式人生累積，改為與目標連動的真實行動紀錄

// MARK: - GoalAccumulationLog

struct GoalAccumulationLog: Identifiable, Codable, Hashable {
    var id: UUID
    var goalId: UUID          // 對應的 LifeGoal
    var date: Date
    var hours: Double         // 這次投入幾小時（支援 0.5 / 1 / 2 等）
    var note: String

    init(
        id: UUID = UUID(),
        goalId: UUID,
        date: Date = Date(),
        hours: Double,
        note: String = ""
    ) {
        self.id = id
        self.goalId = goalId
        self.date = date
        self.hours = hours
        self.note = note
    }
}

// MARK: - GoalAccumulationCalculator

enum GoalAccumulationCalculator {

    /// 某目標所有已記錄的投入時數
    static func totalHours(goalId: UUID, logs: [GoalAccumulationLog]) -> Double {
        logs.filter { $0.goalId == goalId }.map(\.hours).reduce(0, +)
    }

    /// 本月投入時數
    static func thisMonthHours(goalId: UUID, logs: [GoalAccumulationLog], now: Date = Date()) -> Double {
        let cal = Calendar.current
        guard
            let start = cal.date(from: cal.dateComponents([.year, .month], from: now)),
            let end = cal.date(byAdding: .month, value: 1, to: start)
        else { return 0 }
        return logs
            .filter { $0.goalId == goalId && $0.date >= start && $0.date < end }
            .map(\.hours)
            .reduce(0, +)
    }

    /// 進度 0~1（已投入 / 目標總時數）
    static func progress(goalId: UUID, estimatedHours: Int?, logs: [GoalAccumulationLog]) -> Double {
        guard let total = estimatedHours, total > 0 else { return 0 }
        let logged = totalHours(goalId: goalId, logs: logs)
        return min(logged / Double(total), 1.0)
    }

    /// 按每週時數估算，還需幾週完成
    static func weeksToFinish(goalId: UUID, estimatedHours: Int?, weeklyHours: Double?, logs: [GoalAccumulationLog]) -> Int? {
        guard
            let estimated = estimatedHours, estimated > 0,
            let weekly = weeklyHours, weekly > 0
        else { return nil }
        let remaining = max(0, Double(estimated) - totalHours(goalId: goalId, logs: logs))
        return Int((remaining / weekly).rounded(.up))
    }

    /// 估算完成日期
    static func estimatedFinishDate(goalId: UUID, estimatedHours: Int?, weeklyHours: Double?, logs: [GoalAccumulationLog], now: Date = Date()) -> Date? {
        guard let weeks = weeksToFinish(goalId: goalId, estimatedHours: estimatedHours, weeklyHours: weeklyHours, logs: logs) else { return nil }
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: now)
    }

    /// 格式化已投入時數顯示
    static func formattedHours(_ hours: Double) -> String {
        if hours == hours.rounded(.down) {
            return "\(Int(hours))"
        }
        return String(format: "%.1f", hours)
    }
}
