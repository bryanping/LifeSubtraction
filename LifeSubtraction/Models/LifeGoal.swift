import Foundation

// MARK: - Category

enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case family
    case experience
    case growth
    case health
    case creation
    case relationship
    case dream
    case contribution

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .family:        return "家人"
        case .experience:    return "體驗"
        case .growth:        return "成長"
        case .health:        return "健康"
        case .creation:      return "創造"
        case .relationship: return "關係"
        case .dream:         return "夢想"
        case .contribution:  return "貢獻"
        }
    }

    var iconName: String {
        switch self {
        case .family:        return "house.fill"
        case .experience:    return "airplane"
        case .growth:        return "leaf.fill"
        case .health:        return "heart.fill"
        case .creation:      return "paintbrush.fill"
        case .relationship:  return "person.2.fill"
        case .dream:         return "star.fill"
        case .contribution:  return "hands.sparkles.fill"
        }
    }

    var defaultStageTitles: [String] {
        switch self {
        case .family, .relationship:
            return ["下定決心", "開始準備", "付諸行動", "完成"]
        case .experience:
            return ["決定目的地", "訂票安排", "出發", "完成旅程"]
        case .growth:
            return ["選定方向", "開始行動", "持續投入", "完成"]
        case .health:
            return ["下定決心", "開始執行", "養成習慣", "達成"]
        case .creation:
            return ["有想法", "開始製作", "持續打磨", "完成作品"]
        case .dream:
            return ["許下願望", "開始規劃", "付諸行動", "實現"]
        case .contribution:
            return ["想到方式", "開始準備", "付諸行動", "完成"]
        }
    }
}

// MARK: - Status

enum GoalStatus: String, Codable {
    case active
    case completed
    case archived
}

// MARK: - Stage

struct GoalStage: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

// 修改内容 — 時間規劃精簡：開始日期＋執行時間，刪除結束時間/本月/年度；日曆行程改多筆（每週 N 次、每次 1 小時）
struct GoalTimePlan: Codable, Hashable {
    var startDate: Date              // 修改内容：原 dailyDate → 開始日期
    var execTime: Date               // 修改内容：原 dailyStart → 執行時間
    var calendarEventIdentifiers: [String]  // 修改内容：原單一 identifier → 多筆

    init(
        startDate: Date = Date(),
        execTime: Date = GoalTimePlan.defaultExecTime(),
        calendarEventIdentifiers: [String] = []
    ) {
        self.startDate = startDate
        self.execTime = execTime
        self.calendarEventIdentifiers = calendarEventIdentifiers
    }

    static func defaultExecTime() -> Date {
        Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
    }

    // 修改内容 — 舊資料相容（dailyDate/dailyStart/calendarEventIdentifier）
    enum CodingKeys: String, CodingKey {
        case startDate, execTime, calendarEventIdentifiers
        case dailyDate, dailyStart, calendarEventIdentifier
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        startDate = try c.decodeIfPresent(Date.self, forKey: .startDate)
            ?? c.decodeIfPresent(Date.self, forKey: .dailyDate)
            ?? Date()
        execTime = try c.decodeIfPresent(Date.self, forKey: .execTime)
            ?? c.decodeIfPresent(Date.self, forKey: .dailyStart)
            ?? GoalTimePlan.defaultExecTime()
        calendarEventIdentifiers = try c.decodeIfPresent([String].self, forKey: .calendarEventIdentifiers)
            ?? c.decodeIfPresent(String.self, forKey: .calendarEventIdentifier).map { [$0] }
            ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(startDate, forKey: .startDate)
        try c.encode(execTime, forKey: .execTime)
        try c.encode(calendarEventIdentifiers, forKey: .calendarEventIdentifiers)
    }
}

// 修改内容 — 打卡紀錄：實際投入時間＋執行狀況
struct GoalCheckIn: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var minutes: Int
    var note: String
    var stageId: UUID? // 修改内容 — 綁定進度步驟

    init(id: UUID = UUID(), date: Date = Date(), minutes: Int = 60, note: String = "", stageId: UUID? = nil) {
        self.id = id
        self.date = date
        self.minutes = minutes
        self.note = note
        self.stageId = stageId
    }
}

// MARK: - Life Goal

struct LifeGoal: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var category: GoalCategory
    var startDate: Date?
    var completedDate: Date?
    var notes: String
    var status: GoalStatus
    var stages: [GoalStage]
    var reminderIdentifier: String?
    var catalogId: String?
    var detailSelections: [GoalDetailSelection]
    var dueDate: Date?
    var originalDueDate: Date?
    var extensionCount: Int
    var createdAt: Date
    // 修改内容 — 時間規劃欄位：目標所需總時數 & 每週願意投入時數
    var estimatedHours: Int?
    var weeklyHours: Double?
    var timePlan: GoalTimePlan
    var checkIns: [GoalCheckIn] // 修改内容 — 打卡紀錄

    init(
        id: UUID = UUID(),
        title: String,
        category: GoalCategory,
        startDate: Date? = nil,
        completedDate: Date? = nil,
        notes: String = "",
        status: GoalStatus = .active,
        stages: [GoalStage]? = nil,
        reminderIdentifier: String? = nil,
        catalogId: String? = nil,
        detailSelections: [GoalDetailSelection]? = nil,
        dueDate: Date? = nil,
        originalDueDate: Date? = nil,
        extensionCount: Int = 0,
        createdAt: Date = Date(),
        estimatedHours: Int? = nil,
        weeklyHours: Double? = 2, // 修改内容 — 每週投入預設 2 小時
        timePlan: GoalTimePlan = GoalTimePlan(),
        checkIns: [GoalCheckIn] = [] // 修改内容
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startDate = startDate
        self.completedDate = completedDate
        self.notes = notes
        self.status = status
        self.stages = stages ?? GoalStageGenerator.makeStages(catalogId: catalogId, title: title, category: category)
        self.reminderIdentifier = reminderIdentifier
        self.catalogId = catalogId
        self.detailSelections = detailSelections ?? GoalDetailOptions.defaultSelections(for: catalogId)
        self.dueDate = dueDate
        self.originalDueDate = originalDueDate ?? dueDate
        self.extensionCount = extensionCount
        self.createdAt = createdAt
        self.estimatedHours = estimatedHours
            ?? catalogId.flatMap { GoalCatalog.entry(id: $0)?.estimatedHours } // 修改内容 — 建立時自動預帶 catalog 預估
        self.weeklyHours = weeklyHours
        self.timePlan = timePlan
        self.checkIns = checkIns // 修改内容
    }

    // MARK: - 修改内容 — 時間規劃推算

    /// 每週投入（含預設 2 小時下限保護）
    var effectiveWeeklyHours: Double {
        max(0.5, weeklyHours ?? 2)
    }

    /// 每週執行次數（每次固定 1 小時）
    var weeklySessionCount: Int {
        max(1, Int(effectiveWeeklyHours.rounded(.up)))
    }

    /// 累積打卡分鐘數
    var loggedMinutes: Int {
        checkIns.reduce(0) { $0 + $1.minutes }
    }

    var loggedHours: Double {
        Double(loggedMinutes) / 60
    }

    /// 時間進度 0...1（以打卡累積 ÷ 任務總長）
    var timeProgress: Double? {
        guard let estimatedHours, estimatedHours > 0 else { return nil }
        return min(1, loggedHours / Double(estimatedHours))
    }

    /// 本週已打卡分鐘數
    var minutesThisWeek: Int {
        let cal = Calendar.current
        return checkIns
            .filter { cal.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
            .reduce(0) { $0 + $1.minutes }
    }

    /// 預計需要的週數
    var estimatedWeeks: Int? {
        guard let estimatedHours, estimatedHours > 0 else { return nil }
        let remaining = max(0, Double(estimatedHours) - loggedHours)
        return max(1, Int((remaining / effectiveWeeklyHours).rounded(.up)))
    }

    /// 預計完成日（依剩餘時數 ÷ 每週投入，從今天或開始日期往後推）
    var estimatedCompletionDate: Date? {
        guard let weeks = estimatedWeeks else { return nil }
        let anchor = max(timePlan.startDate, Calendar.current.startOfDay(for: Date()))
        return Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: anchor)
    }

    mutating func addCheckIn(minutes: Int, note: String, stageId: UUID? = nil) { // 修改内容 — 可綁定步驟
        checkIns.insert(GoalCheckIn(minutes: minutes, note: note, stageId: stageId), at: 0)
        if startDate == nil { startDate = Date() }
    }

    /// 指定步驟的打卡紀錄（新→舊）修改内容
    func checkIns(for stageId: UUID) -> [GoalCheckIn] {
        checkIns.filter { $0.stageId == stageId }
    }

    var isDueDateLocked: Bool {
        dueDate != nil && originalDueDate != nil
    }

    var daysUntilDue: Int? {
        guard let dueDate else { return nil }
        let cal = Calendar.current
        return cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: Date()),
            to: cal.startOfDay(for: dueDate)
        ).day
    }

    var isOverdue: Bool {
        guard let days = daysUntilDue else { return false }
        return days < 0 && status == .active
    }

    var detailSummary: String {
        detailSelections
            .map(\.selectedValue)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }

    var displayTitle: String {
        let summary = detailSummary
        return summary.isEmpty ? title : "\(title)（\(summary)）"
    }

    enum CodingKeys: String, CodingKey {
        case id, title, category, startDate, completedDate, notes, status, stages
        case reminderIdentifier, catalogId, detailSelections, dueDate, originalDueDate, extensionCount, createdAt
        case estimatedHours, weeklyHours, timePlan, checkIns // 修改内容
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(GoalCategory.self, forKey: .category)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        status = try container.decode(GoalStatus.self, forKey: .status)
        stages = try container.decode([GoalStage].self, forKey: .stages)
        reminderIdentifier = try container.decodeIfPresent(String.self, forKey: .reminderIdentifier)
        catalogId = try container.decodeIfPresent(String.self, forKey: .catalogId)
        detailSelections = try container.decodeIfPresent([GoalDetailSelection].self, forKey: .detailSelections)
            ?? GoalDetailOptions.defaultSelections(for: catalogId)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        originalDueDate = try container.decodeIfPresent(Date.self, forKey: .originalDueDate) ?? dueDate
        extensionCount = try container.decodeIfPresent(Int.self, forKey: .extensionCount) ?? 0
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        estimatedHours = try container.decodeIfPresent(Int.self, forKey: .estimatedHours)
            ?? catalogId.flatMap { GoalCatalog.entry(id: $0)?.estimatedHours } // 修改内容 — 舊資料補上預估
        weeklyHours = try container.decodeIfPresent(Double.self, forKey: .weeklyHours) ?? 2 // 修改内容
        timePlan = try container.decodeIfPresent(GoalTimePlan.self, forKey: .timePlan) ?? GoalTimePlan()
        checkIns = try container.decodeIfPresent([GoalCheckIn].self, forKey: .checkIns) ?? [] // 修改内容
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(category, forKey: .category)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encode(notes, forKey: .notes)
        try container.encode(status, forKey: .status)
        try container.encode(stages, forKey: .stages)
        try container.encodeIfPresent(reminderIdentifier, forKey: .reminderIdentifier)
        try container.encodeIfPresent(catalogId, forKey: .catalogId)
        try container.encode(detailSelections, forKey: .detailSelections)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(originalDueDate, forKey: .originalDueDate)
        try container.encode(extensionCount, forKey: .extensionCount)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(estimatedHours, forKey: .estimatedHours)
        try container.encodeIfPresent(weeklyHours, forKey: .weeklyHours)
        try container.encode(timePlan, forKey: .timePlan)
        try container.encode(checkIns, forKey: .checkIns) // 修改内容
    }

    var completedStageCount: Int { stages.filter(\.isDone).count }
    var allStagesDone: Bool { !stages.isEmpty && stages.allSatisfy(\.isDone) }

    var durationDays: Int? {
        guard let start = startDate, let end = completedDate else { return nil }
        return max(1, Calendar.current.dateComponents([.day], from: start, to: end).day ?? 1)
    }

    mutating func toggleStage(_ stageId: UUID) {
        guard let index = stages.firstIndex(where: { $0.id == stageId }) else { return }
        stages[index].isDone.toggle()
        if startDate == nil, stages.contains(where: \.isDone) {
            startDate = Date()
        }
    }

    mutating func markCompleted() {
        status = .completed
        completedDate = Date()
        if startDate == nil { startDate = Date() }
        for i in stages.indices where !stages[i].isDone {
            stages[i].isDone = true
        }
    }

    func shareText() -> String {
        var lines = ["我完成了：", displayTitle, ""]
        if !notes.isEmpty { lines.append("備註：\(notes)") }
        if let start = startDate, let end = completedDate {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "yyyy.MM.dd"
            lines.append("開始：\(formatter.string(from: start))")
            lines.append("完成：\(formatter.string(from: end))")
            if let days = durationDays {
                lines.append("共花費：\(days) 天")
            }
        }
        lines.append("")
        lines.append("— 人生減法")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Legacy migration

enum LifeGoalMigration {
    struct LegacyGoal: Codable {
        var id: UUID?
        var title: String
        var note: String?
        var progress: Double?
        var isCompleted: Bool?
        var createdAt: Date?
        var completedAt: Date?
    }

    static func migrateIfNeeded() {
        guard let data = UserDefaults.shared.data(forKey: StorageKey.lifeGoals) else { return }
        if (try? JSONDecoder().decode([LifeGoal].self, from: data)) != nil { return }
        guard let legacy = try? JSONDecoder().decode([LegacyGoal].self, from: data), !legacy.isEmpty else { return }

        let migrated: [LifeGoal] = legacy.map { old in
            var goal = LifeGoal(
                id: old.id ?? UUID(),
                title: old.title,
                category: .growth,
                startDate: old.createdAt,
                completedDate: old.completedAt,
                notes: old.note ?? "",
                status: (old.isCompleted == true) ? .completed : .active,
                createdAt: old.createdAt ?? Date()
            )
            if let progress = old.progress, progress > 0 {
                let threshold = Int((progress * Double(goal.stages.count)).rounded(.up))
                for i in 0..<min(threshold, goal.stages.count) {
                    goal.stages[i].isDone = true
                }
            }
            return goal
        }
        LocalJSONStore.save(migrated, key: StorageKey.lifeGoals)
    }
}
