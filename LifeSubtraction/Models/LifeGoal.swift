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
        createdAt: Date = Date()
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
