import Foundation

// MARK: - PlanningScope
// 「規劃」頁面的年 / 月 / 日 切換單位。

enum PlanningScope: String, CaseIterable, Identifiable {
    case year, month, day

    var id: String { rawValue }

    var title: String {
        switch self {
        case .year:  return "年"
        case .month: return "月"
        case .day:   return "日"
        }
    }
}

// MARK: - PlanningItem
// 統一事件：把 LifeGoal（到期日 / 每日排程）與 LifeTask（提醒日）攤平成同一種可排序、可分組的事件。

struct PlanningItem: Identifiable, Hashable {
    enum Kind: Hashable {
        case goalDue          // 目標到期日
        case goalDailyPlan    // 目標每日排程時段
        case taskReminder     // 任務提醒
    }

    let id: String
    let title: String
    let category: GoalCategory
    let date: Date          // 用於分組排序的錨點日期
    let timeLabel: String   // 顯示用的時間文字，例如「20:00–21:00」「距今 3 天」
    let kind: Kind
    let subtitle: String
    let goalId: UUID?
    let taskId: UUID?

    static func == (lhs: PlanningItem, rhs: PlanningItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - FreeSlot
// 一天當中沒有被任何目標每日排程佔用的空檔時段。

struct FreeSlot: Identifiable, Hashable {
    let startHour: Int
    let endHour: Int

    var id: String { "\(startHour)-\(endHour)" }
    var durationHours: Int { max(0, endHour - startHour) }
    var label: String { "\(pad(startHour)):00–\(pad(endHour)):00" }

    private func pad(_ h: Int) -> String { h < 10 ? "0\(h)" : "\(h)" }
}

// MARK: - PlanningSuggestion
// 針對某個空檔，建議可以排入的一件事。

struct PlanningSuggestion: Identifiable {
    var id: String { "\(slot.id)-\(title)" }
    let slot: FreeSlot
    let title: String
    let subtitle: String
    let category: GoalCategory
    let taskId: UUID?
    let goalId: UUID?
}

// MARK: - PlanningRecommendation
// 尚未被實際事件佔用的月份／日期，依剩餘時間給出的建議內容（不是已排定的事）。

struct PlanningRecommendation: Identifiable {
    let id: String
    let dateLabel: String
    let title: String
    let subtitle: String
    let category: GoalCategory
    let goalId: UUID?
}

// MARK: - PlanningEngine

enum PlanningEngine {

    static let dayWindowStartHour = 7
    static let dayWindowEndHour = 23

    // MARK: 事件聚合

    static func items(
        scope: PlanningScope,
        anchorDate: Date,
        goals: [LifeGoal],
        tasks: [LifeTask]
    ) -> [PlanningItem] {
        switch scope {
        case .year:  return yearItems(anchorDate: anchorDate, goals: goals, tasks: tasks)
        case .month: return monthItems(anchorDate: anchorDate, goals: goals, tasks: tasks)
        case .day:   return dayItems(anchorDate: anchorDate, goals: goals, tasks: tasks)
        }
    }

    private static func yearItems(anchorDate: Date, goals: [LifeGoal], tasks: [LifeTask]) -> [PlanningItem] {
        let cal = Calendar.current
        let year = cal.component(.year, from: anchorDate)
        var result: [PlanningItem] = []

        for goal in goals where goal.status == .active {
            if let due = goal.dueDate, cal.component(.year, from: due) == year {
                let days = goal.daysUntilDue ?? 0
                result.append(PlanningItem(
                    id: "goal-due-\(goal.id.uuidString)",
                    title: goal.displayTitle,
                    category: goal.category,
                    date: due,
                    timeLabel: days < 0 ? "已超過 \(abs(days)) 天" : "距今 \(days) 天",
                    kind: .goalDue,
                    subtitle: goalSubtitle(goal, budgetHours: Double(goal.estimatedHours ?? 0)), // 修改内容
                    goalId: goal.id,
                    taskId: nil
                ))
            } else if goal.dueDate == nil {
                // 沒有設定到期日的長期目標，仍列入今年視角，方便被看見。
                result.append(PlanningItem(
                    id: "goal-ongoing-\(goal.id.uuidString)",
                    title: goal.displayTitle,
                    category: goal.category,
                    date: goal.createdAt,
                    timeLabel: "長期進行中",
                    kind: .goalDue,
                    subtitle: goalSubtitle(goal, budgetHours: Double(goal.estimatedHours ?? 0)), // 修改内容
                    goalId: goal.id,
                    taskId: nil
                ))
            }
        }

        for task in tasks where task.isPending {
            if let reminder = task.reminderDate, cal.component(.year, from: reminder) == year {
                result.append(taskItem(task, date: reminder))
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    /// 統一「X/Y 階段」+ 目標時數的顯示文字，避免另外用一張卡片重複列出同一個目標。
    private static func goalSubtitle(_ goal: LifeGoal, budgetHours: Double) -> String {
        var parts = ["\(goal.completedStageCount)/\(goal.stages.count) 階段"]
        if budgetHours > 0 {
            parts.append("目標 \(Int(budgetHours)) 小時")
        }
        return parts.joined(separator: " · ")
    }

    private static func monthItems(anchorDate: Date, goals: [LifeGoal], tasks: [LifeTask]) -> [PlanningItem] {
        let cal = Calendar.current
        let year = cal.component(.year, from: anchorDate)
        let month = cal.component(.month, from: anchorDate)
        var result: [PlanningItem] = []

        for goal in goals where goal.status == .active {
            if let due = goal.dueDate,
               cal.component(.year, from: due) == year,
               cal.component(.month, from: due) == month {
                let days = goal.daysUntilDue ?? 0
                result.append(PlanningItem(
                    id: "goal-due-\(goal.id.uuidString)",
                    title: goal.displayTitle,
                    category: goal.category,
                    date: due,
                    timeLabel: days < 0 ? "已超過 \(abs(days)) 天" : (days == 0 ? "本月到期" : "距今 \(days) 天"),
                    kind: .goalDue,
                    subtitle: goalSubtitle(goal, budgetHours: goal.effectiveWeeklyHours * 4), // 修改内容 — 以每週投入推月時數
                    goalId: goal.id,
                    taskId: nil
                ))
            }
        }

        for task in tasks where task.isPending {
            if let reminder = task.reminderDate,
               cal.component(.year, from: reminder) == year,
               cal.component(.month, from: reminder) == month {
                result.append(taskItem(task, date: reminder))
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    private static func dayItems(anchorDate: Date, goals: [LifeGoal], tasks: [LifeTask]) -> [PlanningItem] {
        let cal = Calendar.current
        var result: [PlanningItem] = []

        // 今天有每日排程時段的進行中目標。若同一個目標今天剛好到期，合併成同一列，避免重複出現。
        for goal in goals where goal.status == .active {
            let plan = goal.timePlan
            let startHour = cal.component(.hour, from: plan.execTime) // 修改内容
            let endHour = min(24, startHour + 1) // 修改内容 — 每次固定 1 小時
            let dueToday = goal.dueDate.map { cal.isDate($0, inSameDayAs: anchorDate) } ?? false

            result.append(PlanningItem(
                id: "goal-daily-\(goal.id.uuidString)",
                title: goal.displayTitle,
                category: goal.category,
                date: cal.date(bySettingHour: startHour, minute: 0, second: 0, of: anchorDate) ?? anchorDate,
                timeLabel: dueToday ? "今天到期 · \(pad(startHour)):00–\(pad(endHour)):00" : "\(pad(startHour)):00–\(pad(endHour)):00",
                kind: .goalDailyPlan,
                subtitle: goalSubtitle(goal, budgetHours: 0),
                goalId: goal.id,
                taskId: nil
            ))
        }

        for task in tasks where task.isPending {
            if let reminder = task.reminderDate, cal.isDate(reminder, inSameDayAs: anchorDate) {
                result.append(taskItem(task, date: reminder))
            }
        }

        return result.sorted { $0.date < $1.date }
    }

    private static func taskItem(_ task: LifeTask, date: Date) -> PlanningItem {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "HH:mm"
        return PlanningItem(
            id: "task-\(task.id.uuidString)",
            title: task.title,
            category: task.category,
            date: date,
            timeLabel: formatter.string(from: date),
            kind: .taskReminder,
            subtitle: task.estimatedLabel.isEmpty ? "任務提醒" : task.estimatedLabel,
            goalId: nil,
            taskId: task.id
        )
    }

    // MARK: 空檔偵測

    /// 找出當天在 dayWindowStartHour ~ dayWindowEndHour 之間，沒有被任何進行中目標的每日排程佔用的空檔。
    static func freeSlots(goals: [LifeGoal]) -> [FreeSlot] {
        var occupied = Array(repeating: false, count: 24)
        let cal = Calendar.current

        for goal in goals where goal.status == .active {
            let plan = goal.timePlan
            let startHour = max(0, cal.component(.hour, from: plan.execTime)) // 修改内容
            let endHour = min(24, startHour + 1) // 修改内容 — 每次固定 1 小時
            guard startHour < endHour else { continue }
            for h in startHour..<endHour { occupied[h] = true }
        }

        var slots: [FreeSlot] = []
        var runStart: Int? = nil
        for hour in dayWindowStartHour..<dayWindowEndHour {
            if occupied[hour] {
                if let start = runStart, hour - start >= 1 {
                    slots.append(FreeSlot(startHour: start, endHour: hour))
                }
                runStart = nil
            } else if runStart == nil {
                runStart = hour
            }
        }
        if let start = runStart, dayWindowEndHour - start >= 1 {
            slots.append(FreeSlot(startHour: start, endHour: dayWindowEndHour))
        }
        return slots
    }

    /// 針對每個空檔，建議一件可以排入的事：只從「還沒被排進今天任何時段」的待辦裡挑選。
    /// 進行中目標已經各自有每日排程時段，不會再被拿來重複建議一次。
    static func suggestions(for slots: [FreeSlot], tasks: [LifeTask]) -> [PlanningSuggestion] {
        let unscheduledTasks = tasks
            .filter { $0.isCurrentlyActive && $0.reminderDate == nil }
            .sorted { lhs, rhs in
                if lhs.isStarred != rhs.isStarred { return lhs.isStarred }
                return (lhs.estimatedMinutes ?? 999) < (rhs.estimatedMinutes ?? 999)
            }

        var usedTaskIds = Set<UUID>()
        var result: [PlanningSuggestion] = []

        for slot in slots {
            let capacityMinutes = slot.durationHours * 60

            if let task = unscheduledTasks.first(where: {
                !usedTaskIds.contains($0.id) && ($0.estimatedMinutes ?? 30) <= capacityMinutes
            }) {
                usedTaskIds.insert(task.id)
                result.append(PlanningSuggestion(
                    slot: slot,
                    title: task.title,
                    subtitle: "空檔 \(slot.durationHours) 小時，可以完成這件待辦",
                    category: task.category,
                    taskId: task.id,
                    goalId: nil
                ))
            }
        }

        return result
    }

    private static func pad(_ h: Int) -> String { h < 10 ? "0\(h)" : "\(h)" }

    // MARK: 依剩餘時間給建議（年 → 每月，月 → 每日）

    /// 今年剩餘、還沒有任何實際事件的月份，依剩餘月數挑 3~5 個給建議。
    static func monthlyRecommendations(
        anchorDate: Date,
        goals: [LifeGoal],
        tasks: [LifeTask],
        occupiedMonths: Set<Int>
    ) -> [PlanningRecommendation] {
        let cal = Calendar.current
        let currentMonth = cal.component(.month, from: anchorDate)
        let remainingMonths = (currentMonth...12).filter { !occupiedMonths.contains($0) }
        guard !remainingMonths.isEmpty else { return [] }
        let candidates = recommendationCandidates(goals: goals, tasks: tasks)
        guard !candidates.isEmpty else { return [] }
        let picked = spaced(
            remainingMonths,
            desiredCount: min(5, remainingMonths.count, candidates.count)
        )

        return picked.enumerated().map { index, month in
            let content = candidates[index]
            return PlanningRecommendation(
                id: "month-rec-\(month)",
                dateLabel: "\(month) 月",
                title: content.title,
                subtitle: content.subtitle,
                category: content.category,
                goalId: content.goalId
            )
        }
    }

    /// 這個月剩餘、還沒有任何實際事件的日期，依剩餘天數挑 3~5 天給建議。
    static func dailyRecommendations(
        anchorDate: Date,
        goals: [LifeGoal],
        tasks: [LifeTask],
        occupiedDays: Set<Int>
    ) -> [PlanningRecommendation] {
        let cal = Calendar.current
        let today = cal.component(.day, from: anchorDate)
        guard let range = cal.range(of: .day, in: .month, for: anchorDate) else { return [] }
        let remainingDays = (today...range.upperBound - 1).filter { !occupiedDays.contains($0) }
        guard !remainingDays.isEmpty else { return [] }
        let candidates = recommendationCandidates(goals: goals, tasks: tasks)
        guard !candidates.isEmpty else { return [] }
        let picked = spaced(
            remainingDays,
            desiredCount: min(5, remainingDays.count, candidates.count)
        )

        return picked.enumerated().map { index, day in
            let content = candidates[index]
            return PlanningRecommendation(
                id: "day-rec-\(day)",
                dateLabel: "\(day) 日",
                title: content.title,
                subtitle: content.subtitle,
                category: content.category,
                goalId: content.goalId
            )
        }
    }

    private struct RecommendationCandidate {
        let title: String
        let subtitle: String
        let category: GoalCategory
        let goalId: UUID?
    }

    /// 建議候選：進行中目標的下一步 + 還沒排定時間的待辦，交錯排列；都沒有時退回通用提示語。
    private static func recommendationCandidates(
        goals: [LifeGoal],
        tasks: [LifeTask]
    ) -> [RecommendationCandidate] {
        let activeGoals = goals.filter { $0.status == .active }
        let goalCandidates: [RecommendationCandidate] = activeGoals.map { goal in
            let step = goal.stages.first(where: { !$0.isDone })
            return RecommendationCandidate(
                title: "為「\(goal.displayTitle)」推進：\(step?.title ?? "下一步")",
                subtitle: "還沒安排具體時間，適合找空檔推進",
                category: goal.category,
                goalId: goal.id
            )
        }

        let unscheduledTasks = tasks.filter { $0.isCurrentlyActive && $0.reminderDate == nil }
        let taskCandidates: [RecommendationCandidate] = unscheduledTasks.map { task in
            RecommendationCandidate(
                title: task.title,
                subtitle: task.estimatedLabel.isEmpty ? "還沒排定時間的待辦" : "還沒排定時間，約需 \(task.estimatedLabel)",
                category: task.category,
                goalId: nil
            )
        }

        let merged = interleave(goalCandidates, taskCandidates)
        if !merged.isEmpty { return uniqueCandidates(merged) }
        return genericPrompts
    }

    private static func uniqueCandidates(_ candidates: [RecommendationCandidate]) -> [RecommendationCandidate] {
        var usedKeys = Set<String>()
        return candidates.filter { candidate in
            let key = candidate.goalId?.uuidString ?? normalize(candidate.title)
            guard !usedKeys.contains(key) else { return false }
            usedKeys.insert(key)
            return true
        }
    }

    private static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func interleave<T>(_ a: [T], _ b: [T]) -> [T] {
        var result: [T] = []
        let maxCount = max(a.count, b.count)
        for i in 0..<maxCount {
            if i < a.count { result.append(a[i]) }
            if i < b.count { result.append(b[i]) }
        }
        return result
    }

    private static let genericPrompts: [RecommendationCandidate] = [
        RecommendationCandidate(title: "挑一件想完成的事，加入規劃", subtitle: "還沒有進行中的目標，先從一件小事開始", category: .growth, goalId: nil),
        RecommendationCandidate(title: "留一段時間陪伴家人", subtitle: "找一天約家人吃頓飯或聊聊天", category: .family, goalId: nil),
        RecommendationCandidate(title: "為自己安排一次放鬆", subtitle: "留一點時間做喜歡的事", category: .health, goalId: nil),
        RecommendationCandidate(title: "寫下一個想完成的心願", subtitle: "把想法變成具體的下一步", category: .dream, goalId: nil),
        RecommendationCandidate(title: "整理一次生活回顧", subtitle: "回顧最近的生活，想想接下來想調整什麼", category: .growth, goalId: nil)
    ]

    /// 從候選清單中，依需求數量取等間距的樣本（避免全部集中在最前面）。
    private static func spaced<T>(_ items: [T], desiredCount: Int) -> [T] {
        guard desiredCount > 0, !items.isEmpty else { return [] }
        guard items.count > desiredCount else { return items }
        let step = Double(items.count) / Double(desiredCount)
        return (0..<desiredCount).map { i in items[Int((Double(i) * step).rounded())] }
    }
}
